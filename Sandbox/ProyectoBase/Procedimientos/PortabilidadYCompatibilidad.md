# Procedimiento de Portabilidad y Compatibilidad
Este procedimiento establece las reglas para garantizar que todo desarrollo del proyecto se mantenga portable, autocontenido y compatible con los entornos definidos por el usuario.

---

## 1. Lineamientos Generales
La portabilidad se basa exclusivamente en:
- Windows 10 o superior.
- .NET 8 en modo self-contained.
- PowerShell 7.x como entorno principal.
- Compatibilidad opcional con PowerShell 5 cuando no genere complejidad.

El asistente debe cumplir estas reglas sin desviaciones.

---

## 2. Compilación Self-Contained
Toda aplicación .NET generada dentro del proyecto debe compilarse con:
- SelfContained=true
- PublishSingleFile=true
- IncludeNativeLibrariesForSelfExtract=true
- RuntimeIdentifier=win-x64

### Objetivo
Permitir que el ejecutable corra en equipos sin ninguna instalación previa de .NET.

---

## 3. Compatibilidad .NET
### 3.1. Versión base
La versión base del proyecto es **.NET 8**.

### 3.2. Compatibilidad hacia atrás
Si se ejecuta en un sistema que tenga .NET 6 o 7 instalados:
- Esto no afecta al ejecutable self-contained.
- El programa usa su propio runtime.

### 3.3. Restricciones
No se utilizan API modernas que requieran Windows 11, a menos que el usuario lo autorice explícitamente.

---

## 4. Compatibilidad Windows
### 4.1. Sistema mínimo
- Windows 10 (cualquier edición).

### 4.2. Exclusión explícita
- Windows 7 queda fuera del soporte debido a incompatibilidad con PowerShell 7.

### 4.3. Nivel de API
El asistente debe verificar:
- Que las APIs usadas existan en Windows 10.
- Que no se invoquen funciones WinRT que dependan de versiones posteriores.

---

## 5. Compatibilidad PowerShell
### 5.1. Entorno principal
- PowerShell 7.5.4 o superior.

### 5.2. Compatibilidad opcional
- PowerShell 5 puede usarse cuando:
  - No genere deuda técnica.
  - No complique diseño.
  - No requiera soluciones duplicadas.

### 5.3. Diferencias a considerar
El asistente debe advertir cuando:
- Un cmdlet se comporta distinto en PS5 y PS7.
- Una característica solo existe en PS7.
- Un script deje de ser portable por ejecutar APIs exclusivas de un entorno.

---

## 6. Mantenimiento de Portabilidad
Para mantener la portabilidad en cada etapa del proyecto:
- No usar dependencias externas sin aprobación.
- No requerir instaladores.
- No asumir frameworks del sistema.
- Mantener arquitectura modular.
- Evitar uso de COM innecesario.
- No introducir runtimes adicionales.

Cada módulo debe poder funcionar con:
- El ejecutable self-contained.
- PowerShell 7, sin dependencias complejas.

---

## 7. Validación de Portabilidad
Antes de entregar código que afecte compatibilidad:
- Validar que compila para Windows 10.
- Confirmar que no rompe el runtime self-contained.
- Verificar que no requiere instalación de .NET.
- Advertir si una API eleva el requisito mínimo del sistema.

---

## 8. Correcciones
Si la portabilidad se ve comprometida:
- El asistente aplica el procedimiento de corrección modular (CorreccionModular.md).
- Reescribe el módulo correspondiente completo.
- Nunca solicita correcciones manuales al usuario.

---

## 9. Objetivo General
Asegurar que todo el proyecto funcione en:
- Windows 10 en adelante.
- Sistemas sin .NET instalado.
- PowerShell 7 como entorno nativo.
- PowerShell 5 cuando sea razonable.

Sin romper modularidad, estabilidad ni simplicidad.
