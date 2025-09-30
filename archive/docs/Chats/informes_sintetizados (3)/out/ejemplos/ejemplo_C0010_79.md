```
Basado en la estructura de SEED01 y subpartes descritas en el temario y en la guía de “Semillas”. fileciteturn6file1L7-L15 fileciteturn6file3L22-L25

## USER
Ok, sigue con SEED02

## Thoughts
Debe responderse en español de manera directa, presentando el bloque de código requerido para SEED02. Este contendrá subpartes numeradas como "02.0". No hay necesidad de usar citas, ya que no se han solicitado. El código no tiene bloques anidados, por lo que se emplearán tres acentos graves.
Vamos a usar tres acentos graves, ya que no hay códigos anidados aquí. Para SEED02, hemos creado los siguientes subpartes:

SEED02_Configuración_&_Seguridad

Subpartes:
02.0 Configuración básica de sesión
02.1 Cultura y codificación
02.2 TLS y políticas de seguridad
02.3 Manejo de errores y excepciones
02.4 Políticas de ejecución y firmas
02.5 Entorno y dependencias
02.6 Validaciones cruzadas de seguridad

Cada subparte tiene funciones y prácticas recomendadas asociadas, como `Set-StrictMode -Version Latest`, `$ErrorActionPreference = 'Stop'`, o la configuración de `SecurityProtocol`.
En PowerShell 7, se sigue utilizando `ServicePointManager`, pero con `SslProtocols` y `HttpClient`. Mi enfoque sería configurar en `Tls12` o `Tls13`, dependiendo del soporte.

Para UTF-8 sin BOM, se puede usar `[Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)`.

Para la cultura, utiliza `[System.Globalization.CultureInfo]::CurrentCulture = 'es-MX'`, aunque en PS7 se puede usar `Set-Culture`.
Para mejorar la ejecución en PowerShell, se pueden usar `$PSDefaultParameterValues` para configurar opciones como `-ErrorAction`. El uso de `Test-IsAdmin` y `Set-ExecutionPolicy` puede ser relevante, especialmente si trabajas con "Bypass" en PS7. 

Recuerda ajustar el modo de depuración con `Set-StrictMode`, y para la firma de código puedes usar `Get-AuthenticodeSignature`.

## ASSISTANT
```