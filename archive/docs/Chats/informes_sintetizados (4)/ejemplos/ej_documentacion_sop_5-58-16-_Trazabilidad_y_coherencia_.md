### Entrada (user)

Lee y analiza detalladamente lo siguiente:

~~~~~
Aquí tienes un método breve y efectivo para comprobar coherencia entre **Instrucciones del proyecto** y **archivos de referencia**:

1. **Inventario y descomposición**

   * Lista los archivos (título, fecha, versión) y **divide las instrucciones en “cláusulas atómicas”** (una regla o criterio por línea, con ID).

2. **Matriz de trazabilidad (instrucción → evidencia)**

   * Para cada cláusula, identifica **dónde vive la evidencia** (archivo, sección/página) y su **vigencia** (fecha/versión).
   * Usa esta tabla y marca estado:

   | ID   | Instrucción (resumida) | Evidencia (archivo + sección)  | Vigencia   | Estado    | Nota/Fix                           |
   | ---- | ---------------------- | ------------------------------ | ---------- | --------- | ---------------------------------- |
   | I-01 | “Usar tono formal”     | `Guía_Estilo v3.pdf §2`        | 2025-07-10 | OK        | —                                  |
   | I-02 | “Umbral = 0.75”        | `Spec_Modelo.xlsx hoja Config` | 2024-11-02 | CONFLICTO | En `README.md` dice 0.70; unificar |

3. **Criterios de coherencia (úsalos como checklist)**

   * **Consistencia:** no hay contradicciones entre instrucciones y archivos (números, definiciones, pasos).
   * **Completitud:** toda instrucción tiene evidencia; si falta, crear/actualizar el archivo fuente.
   * **Vigencia (recency):** la instrucción referencia **versiones/fechas actuales**; evita citar documentos obsoletos.
   * **Precedencia:** define jerarquía (p. ej., “Spec_v3 > Manual_v2 > Notas”).
   * **Aplicabilidad:** el modelo puede ejecutar la instrucción con lo que hay en archivos (sin ambigüedad).

4. **Pruebas de comportamiento (golden tests)**

   * Diseña 5–10 **tareas representativas** (inputs reales).
   * Evalúa si la salida **cumple cada cláusula** (tono, fuentes, límites, pasos).
   * Si falla: ajusta **instrucciones** (más claras/prioridades) o **archivos** (corrige dato/versión).

5. **Automatización ligera dentro del Proyecto (útil para iterar)**
   Pega este prompt en un chat del Proyecto con los archivos cargados:

   ```
   Actúa como verificador de coherencia. 
   1) Extrae una lista numerada de cláusulas atómicas de las Instrucciones del proyecto.
   2) Para cada cláusula, busca evidencia en los archivos del proyecto (cita archivo y sección/página).
   3) Produce la matriz: ID | Instrucción | Evidencia | Vigencia | Estado (OK/CONFLICTO/FALTA) | Nota/Fix.
   4) Señala contradicciones y sugiere la fuente canónica (según precedencia).
   5) Propón 3 pruebas breves para validar tras los cambios.
   ```

   *(Opcional)* Añade en las Instrucciones: **“Si hay conflicto, prioriza `Spec_Producto vX` por fecha más reciente; nunca uses documentos sin fecha.”*

6. **Cierre y mantenimiento**

   * Ejecuta fixes (unificar números, actualizar versiones, eliminar duplicados).
   * **Sella la coherencia**: actualiza las Instrucciones con “fuentes canónicas” y **fechas ISO**.
   * Repite el check **tras cada cambio de archivo clave** o en cadencia semanal.
~~~~~

### Salida (assistant)

¡Buen método! Está bien enfocado en trazabilidad y “pruebas de aceptación” rápidas. Aquí tienes un análisis crítico y varias mejoras para operativizarlo sin fricción (plantillas + mini-protocolo + script auxiliar).

# Diagnóstico (qué tan sólido está el enfoque)
- **Fortalezas**
  - **Trazabilidad explícita** (instrucción → evidencia) y atención a **vigencia/precedencia**.
  - Introduce **golden tests** para validar el comportamiento real, no solo la documentación.
  - Es **agnóstico de dominio** y aplicable a cualquier set de archivos.

- **Riesgos / huecos habituales**
  1) **Estados insuficientes:** solo OK/CONFLICTO/FALTA; falta “OBSOLETA” (evidencia desactualizada) y “AMBIGUA” (texto interpretable de ≥2 formas).
  2) **Vigencia no cuantificada:** conviene una regla concreta (p. ej., “obsoleto si >180 días sin cambio o versión menor que la referida en Instrucciones”).
  3) **Precedencia poco operacional:** define tabla de jerarquía con pesos (“Spec > SOP > README > Notas”) y desempate por fecha ISO del documento.
  4) **Extracción de versión/fecha:** PDFs/Excels o archivos sin fecha en nombre requieren heurísticas (regex sobre nombre y cabeceras).
  5) **Cierre sin SLA:** falta priorización y due dates para los fixes.

---

# Mejoras puntuales (plug-and-play)

## 1) Estados y severidad
Usa este conjunto:
- **OK** (sev: —)
- **FALTA** (sev: Alto): no existe evidencia.
- **CONFLICTO** (sev: Crítico): dos fuentes se contradicen.
- **OBSOLETA** (sev: Medio/Alto): evidencia existe pero fecha/versión antigua según regla.
- **AMBIGUA** (sev: Medio): instrucción interpretable de formas múltiples.

## 2) Regla de vigencia (ejemplo cuantificable)
- “Una evidencia es **OBSOLETA** si:  
  a) `LastModified` > **180 días** atrás **o**  
  b) su `version` < versión citada en Instrucciones **o**  
  c) no contiene **fecha ISO** y no está en la **fuente canónica**.”

(Ajusta 180 → 90/365 según cadencia del proyecto.)

## 3) Precedencia operativa (con peso)
| Orden | Fuente           | Peso | Nota de desempate                  |
|------:|------------------|-----:|------------------------------------|
| 1     | **Spec_Producto**| 100  | Más reciente por **fecha ISO**     |
| 2     | **SOP/Protocolos**| 80  |                                    |
| 3     | **README/Guías** | 60   |                                    |
| 4     | **Notas**        | 40   |                                    |

Cuando haya **CONFLICTO**: gana el **peso**; si pesos iguales, gana **fecha más reciente**.

## 4) Esquema de IDs
- **Cláusula**: `I-###` (p. ej., `I-003`)  
- **Evidencia**: `E-yyyymmdd-###` si necesitas referenciar múltiples secciones.

## 5) Matriz extendida (añade severidad y fuente)
Cambia tus columnas a:

`ID | Instrucción (resumida) | Evidencia (archivo + sección) | Fuente (Spec/SOP/…) | Versión/Fecha | Estado | Severidad | Nota/Fix | Due date | Owner`

---

# Plantillas listas

## A) Checklist de coherencia
- [ ] **Consistencia** (números/definiciones/umbrales no se contradicen)  
- [ ] **Completitud** (toda instrucción mapea a evidencia)  
- [ ] **Vigencia** (≤180 días, versión al día, fecha ISO presente)  
- [ ] **Precedencia** (decisionado por peso + fecha)  
- [ ] **Aplicabilidad** (modelo puede ejecutar sin ambigüedad)  
- [ ] **Sello** (Instrucciones actualizadas con **fuentes canónicas** y **fecha ISO**)

## B) Prompt del verificador (tuneado)
```
Actúa como verificador de coherencia. 
1) Extrae una lista numerada de *cláusulas atómicas* de las Instrucciones del proyecto (una por línea, con ID I-###).
2) Para cada cláusula, busca evidencia en los archivos del proyecto (cita archivo y sección/página) y determina:
   - Fuente (Spec/SOP/README/Notas)
   - Versión/Fecha (ISO si existe; si falta, marca “sin fecha”)
3) Produce la matriz con columnas:
   ID | Instrucción | Evidencia | Fuente | Versión/Fecha | Estado (OK/CONFLICTO/FALTA/OBSOLETA/AMBIGUA) | Severidad | Nota/Fix | Due date | Owner
4) Aplica precedencia: Spec>SOP>README>Notas; desempata por fecha más reciente.
5) Señala contradicciones y propone la **fuente canónica**.
6) Sugiere 3 pruebas cortas (golden tests) para validar tras los cambios.
7) Marca como **OBSOLETA** toda evidencia con >180 días o versión menor que la declarada.
```

## C) Fragmento para añadir a tus Instrucciones
> **Resolución de conflictos**: “Prioriza `Spec_Producto` sobre otras fuentes. Si hay contradicción, gana la fuente de mayor precedencia; si empatan, gana la de **fecha ISO más reciente**. Documentos **sin fecha** no pueden ser fuente canónica.”

---

# Golden tests (ejemplos genéricos)
1) **Tono y estilo**: Dado un prompt técnico, la salida usa el tono instruido (formal/informal) y mantiene el formato requerido (p. ej., Markdown con secciones X/Y/Z).  
2) **Umbral numérico**: Cuando se pide un cálculo que depende de `umbral = 0.75`, la solución usa exactamente 0.75 y señala la fuente.  
3) **Precedencia**: Ante dos documentos con cifras distintas, la respuesta cita la **Spec** y explica por qué descarta la otra.  
4) **Vigencia**: Si se referencia un documento >180 días, la respuesta lo marca como “obsoleto” y solicita confirmación de actualización.  
5) **Aplicabilidad**: Al ejecutar un paso procedimental, la salida no asume archivos ni rutas inexistentes; si faltan, lo reporta como **FALTA** con fix propuesto.

---

# Mini-protocolo operativo (10–15 min por iteración)
1) **Inventario**: lista de archivos con `ruta, nombre, ext, tamaño, lastWriteTime, hashSHA256, versión (heurística), fechaISO (si en nombre)`.  
2) **Cláusulas atómicas**: extrae 15–40 (máx. 1 criterio por línea).  
3) **Rastreo**: llena la matriz; marca estados.  
4) **Reporte**: top 5 hallazgos (Crítico/Alto), fixes 1-línea con **Owner** y **Due date**.  
5) **Sello**: actualiza Instrucciones (fuente canónica + fecha ISO) y archiva la matriz.

---

# Script auxiliar (PowerShell, opcional)
Genera inventario rápido con heurísticas de **versión/fecha** desde el nombre y primeras líneas de texto.

```powershell
# Inventory-Coherence-Snapshot.ps1
# Requiere PowerShell 5.1+ (mejor 7+). No instala módulos.
param(
  [Parameter(Mandatory=$true)][string]$RootDir,
  [int]$MaxBytesToScan = 8192
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-VersionFromName([string]$name) {
  $patterns = @(
    'v(?<v>\d+(?:\.\d+){0,3})',           # v1 / v1.2 / v1.2.3.4
    '(?<v>\d+\.\d+\.\d+)',                 # 1.2.3
    'version[_\-\s:]*(?<v>\d+(?:\.\d+)*)'  # version: 1.2
  )
  foreach ($p in $patterns) {
    $m = [regex]::Match($name, $p, 'IgnoreCase')
    if ($m.Success) { return $m.Groups['v'].Value }
  }
  return $null
}

function Get-DateIsoFromName([string]$name) {
  $m = [regex]::Match($name, '(?<d>\d{4}-\d{2}-\d{2})')
  if ($m.Success) { return $m.Groups['d'].Value }
  return $null
}

function Get-TextPreview($path, $max) {
  try {
    $ext = [IO.Path]::GetExtension($path).ToLowerInvariant()
    if ($ext -in '.txt','.md','.json','.csv','.yml','.yaml','.ps1','.psm1','.psd1') {
      $fs = [IO.File]::OpenRead($path)
      try {
        $len = [Math]::Min($fs.Length, [int64]$max)
        $buf = New-Object byte[] $len
        [void]$fs.Read($buf,0,$len)
        return [Text.Encoding]::UTF8.GetString($buf)
      } finally { $fs.Dispose() }
    }
  } catch {}
  return $null
}

$items = Get-ChildItem -LiteralPath $RootDir -Recurse -File -ErrorAction Stop
$out = foreach ($f in $items) {
  $name = $f.Name
  $ver  = Get-VersionFromName $name
  $iso  = Get-DateIsoFromName $name
  $preview = Get-TextPreview $f.FullName $MaxBytesToScan
  if (-not $ver -and $preview) {
    $m = [regex]::Match($preview, 'version[_\-\s:]*(?<v>\d+(?:\.\d+)*)', 'IgnoreCase')
    if ($m.Success) { $ver = $m.Groups['v'].Value }
  }
  $sha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $f.FullName).Hash
  [pscustomobject]@{
    Path          = $f.FullName
    FileName      = $name
    Ext           = $f.Extension
    SizeBytes     = $f.Length
    LastWriteUtc  = $f.LastWriteTimeUtc.ToString('s') + 'Z'
    VersionGuess  = $ver
    DateISOinName = $iso
    SHA256        = $sha256
  }
}

$out | Sort-Object Path | Export-Csv -NoTypeInformation -Encoding UTF8 -Path (Join-Path $RootDir 'inventory_snapshot.csv')
$out | ConvertTo-Json -Depth 5 | Set-Content -Encoding UTF8 (Join-Path $RootDir 'inventory_snapshot.json')
Write-Host "Inventario generado: inventory_snapshot.csv / .json"
```

**Cómo usar**  
`pwsh ./Inventory-Coherence-Snapshot.ps1 -RootDir "C:\ruta\al\proyecto"`

> Resultado: dos archivos (`inventory_snapshot.csv/json`) con columnas listas para mapear en tu matriz. Agrega manualmente “Fuente/Estado/Owner/Due date” o extiéndelo si deseas.

---

# Qué cambiaría yo en tu método (resumen ejecutable)
1) Añadir **estados** OBSOLETA y AMBIGUA + **severidad**.  
2) Cuantificar **vigencia** (días y/o versión) y **precedencia** con pesos.  
3) Integrar **SLA**: cada fila con Due date (ISO) y Owner.  
4) Incorporar **inventario automatizado** (script anterior) para acelerar el paso 1.  
5) “Sellar” la coherencia actualizando Instrucciones con: **fuente canónica**, **fecha ISO** y **regla de conflicto** (texto ya propuesto).

Si quieres, puedo adaptar el script para que **pre-llene** una matriz CSV con tus columnas extendidas y estados iniciales “FALTA/OBSOLETA” según reglas de fecha/versión.
