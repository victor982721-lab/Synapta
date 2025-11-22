\C:\Users\VictorFabianVeraVill\Documents\GitHub\Neurologic\Sandbox\ProyectoBase = Split-Path -Parent \System.Management.Automation.InvocationInfo.MyCommand.Path
\ = Join-Path \C:\Users\VictorFabianVeraVill\Documents\GitHub\Neurologic\Sandbox\ProyectoBase "Portable"

# Crear carpeta Portable
New-Item -ItemType Directory -Force -Path \ | Out-Null

# Publicar
dotnet publish \C:\Users\VictorFabianVeraVill\Documents\GitHub\Neurologic\Sandbox\ProyectoBase\ProyectoBase.csproj -c Release -o \ --self-contained true --runtime win-x64 /p:PublishSingleFile=true /p:IncludeNativeLibrariesForSelfExtract=true

# Comprimir resultado
Compress-Archive -Path "\\*" -DestinationPath "\C:\Users\VictorFabianVeraVill\Documents\GitHub\Neurologic\Sandbox\ProyectoBase\ProyectoBase_Portable.zip" -Force

Write-Host "Portable generado en ProyectoBase_Portable.zip"
