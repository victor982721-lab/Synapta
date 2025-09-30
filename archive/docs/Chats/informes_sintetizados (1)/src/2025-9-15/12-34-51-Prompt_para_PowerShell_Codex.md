# Prompt para PowerShell Codex

https://chat.openai.com/c/68d3371e-1014-8013-b431-fc270bea0cc8

## USER
https://microsoft-github-io.translate.goog/prompt-engineering/?_x_tr_sl=en&_x_tr_tl=es&_x_tr_hl=es&_x_tr_pto=tc

Por favor en función de lo que dice esta página de internet, genera un prompt adecuado para CODEX enfocado en uso de powershell

## ASSISTANT
Para generar un prompt efectivo para GitHub Copilot (basado en Codex) enfocado en PowerShell, es esencial aplicar las mejores prácticas de ingeniería de prompts. A continuación, se presenta un ejemplo detallado que sigue estas directrices:

---

## 🎯 Prompt para GitHub Copilot en PowerShell


```powershell
# Generar un script en PowerShell que automatice la creación de un informe en formato CSV
# con el estado de los servicios de Windows, incluyendo:
# - Nombre del servicio
# - Estado (en ejecución, detenido, etc.)
# - Descripción
# - Nombre del equipo
#
# El script debe:
# - Obtener la lista de servicios utilizando Get-Service
# - Filtrar servicios cuyo estado sea 'Running'
# - Exportar los resultados a un archivo CSV
# - Incluir un encabezado con la fecha y hora de ejecución
# - Manejar errores si no se puede acceder a los servicios
# - No utilizar Write-Host; en su lugar, usar Write-Output o Write-Error según corresponda
# - Asegurar la compatibilidad con PowerShell 7.3 en sistemas Windows 10 Pro versión 22H2
#
# Ejemplo de salida esperada:
# "Servicio,Estado,Descripción,Equipo"
# "wuauserv,Running,Windows Update,MI-PC"
```



---

## 🧠 Estrategias de Ingeniería de Prompts Aplicadas

1. **Inicio general, luego especificar**: Se comienza con una descripción amplia del objetivo (automatizar la creación de un informe en CSV) y luego se detallan los requisitos específicos.

2. **Proporcionar ejemplos**: Se incluye un ejemplo de la salida esperada para guiar a Copilot en la generación del código.

3. **Descomponer tareas complejas**: Se especifican pasos individuales como obtener servicios, filtrarlos, exportar a CSV y manejar errores.

4. **Evitar ambigüedades**: Se utilizan términos claros y se especifica el entorno de ejecución (PowerShell 7.3 en Windows 10 Pro 22H2).

5. **Experimentar e iterar**: Si la salida generada no cumple con las expectativas, se ajusta el prompt para refinar los resultados.

6. **Mantener historial relevante**: En sesiones de Copilot Chat, se conserva el contexto pertinente para tareas continuas.

7. **Seguir buenas prácticas de codificación**: Se especifica el uso de `Write-Output` o `Write-Error` en lugar de `Write-Host` y se enfatiza la compatibilidad con versiones específicas de PowerShell.

---

Este enfoque asegura que GitHub Copilot genere un script en PowerShell que cumpla con los requisitos establecidos, siguiendo las mejores prácticas de ingeniería de prompts. 

## USER


## ASSISTANT


## USER


## ASSISTANT
El usuario prefiere que, para afinar prompts, no se le hagan preguntas directas, sino que él vaya respondiendo según lo considere, y que al final se le entregue una versión final del prompt adecuada.

## ASSISTANT


## USER


## ASSISTANT


