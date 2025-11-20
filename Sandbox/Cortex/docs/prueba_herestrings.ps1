
# Contenido que quieres escribir
$GlobalNeurologicAgentsContent = 

@'

{{Aquí va el contenido del AGENTS.md ubicado en "C:\Users\VictorFabianVeraVill\Documents\GitHub\Neurologic\Sandbox\Cortex\docs\Templates"}}

'@

# Ruta del archivo .md a generar
$OutputPath = "C:\Users\VictorFabianVeraVill\Documents\GitHub\Neurologic\Sandbox\Cortex\docs\Archivo\ContenidoGenerado.md"

# Crear el archivo con ese contenido
Set-Content -Path $OutputPath -Value $GlobalNeurologicAgentsContent -Encoding UTF8
