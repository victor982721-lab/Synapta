# Procedimiento de Estilo de Scripts PowerShell
Este procedimiento define las reglas para mantener un estilo consistente, estable y claro en todos los scripts PowerShell generados dentro del proyecto.

---

## 1. Objetivos del Estilo
- Claridad total del código.
- Fácil lectura y mantenimiento.
- Evitar complejidad innecesaria.
- Consistencia entre scripts.
- Portabilidad en PS7 como prioridad.

---

## 2. Estructura General
Todos los scripts deben mantener:

1. **Encabezado limpio**  
   - Sin comentarios decorativos innecesarios.  
   - Sin bloques extensos salvo que sean solicitados.

2. **Funciones organizadas**  
   - Una función = una responsabilidad clara.  
   - Nombre en PascalCase o UpperCamelCase: Get-ItemData, Invoke-Scan.  
   - No anidar funciones salvo que se solicite explícitamente.

3. **Bloques lógicos separados**  
   - Parámetros  
   - Validaciones  
   - Lógica  
   - Salida  

4. **Evitar comportamiento impredecible**  
   - No escribir en disco sin confirmación explícita.  
   - No modificar el entorno del usuario.  
   - No usar alias ambiguos.

---

## 3. Sintaxis y Calidad
- Usar param() para definir parámetros siempre que el script lo necesite.
- Evitar variables globales.  
- Nombres descriptivos, nada de $a, $x, $tmp.
- Usar Write-Host solo para mensajes directos al usuario; para logs considerar Write-Output.
- Evitar pipelines innecesariamente largos.
- Evitar dependencias externas sin aprobación.

---

## 4. Compatibilidad
### 4.1. PowerShell 7 (preferido)
- Scripts optimizados para PS7.  
- Uso permitido de cmdlets modernos compatibles.

### 4.2. PowerShell 5 (opcional)
El script debe advertir si algo:
- No funciona igual en PS5.  
- No existe en PS5.  
- Requiere reescritura para portar.  

No se debe duplicar lógica a menos que sea estrictamente necesario y aprobado.

---

## 5. Estilo de Errores y Validaciones
- Usar 	hrow cuando corresponda.  
- Evitar 	ry/catch excesivo.  
- Mensajes claros y específicos.  
- Validar entradas antes de procesarlas.  

---

## 6. Estilo de Here-Strings
Cuando se generen:
- Siempre incluirlos listos para escribirse a disco.  
- Usar Set-Content o Out-File.  
- Declarar la ruta completa.  
- No generar variables sueltas con here-strings sin destinación.

---

## 7. Comentarios
- Usar comentarios **solo para aclarar decisiones importantes**.  
- No comentar obviedades.  
- No saturar el script con documentación innecesaria.  

---

## 8. Modularidad del Script
- Si una función crece demasiado, dividirla en funciones internas dentro del mismo módulo, **no en archivos separados** salvo aprobación.  
- Cada script debe ser autodelimitado y no depender de rutas relativas salvo que el usuario lo pida.  

---

## 9. Portabilidad del Código PowerShell
- Evitar APIs que requieran permisos elevados salvo que se explicite.  
- No usar Windows Forms en PS7 salvo aprobación explícita.  
- Preferir mecanismos nativos de PowerShell para rutas, IO y procesamiento.  

---

## 10. Objetivo General
Mantener un estándar sólido para que todos los scripts:
- Sean legibles.
- Sean mantenibles.
- Sean consistentes.
- No generen frustración.
- Mantengan coherencia entre etapas del proyecto.
