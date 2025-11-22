function Find-TextInFiles {
    param(
        [Parameter(Mandatory=True)]
        [string] ,

        [Parameter(Mandatory=True)]
        [string] ,

        [string[]]  = @("*")  # Ejemplo: @("*.txt","*.md","*.log")
    )

    # Buffer interno para evitar logs en disco
     = [System.Collections.Generic.List[string]]::new()

    # Obtener archivos según extensiones
     = foreach ( in ) {
        Get-ChildItem -Path  -Recurse -File -Filter  -ErrorAction SilentlyContinue
    }

    foreach ( in ) {
         = Select-String -Path .FullName -Pattern  -SimpleMatch -CaseInsensitive -ErrorAction SilentlyContinue
        
        foreach ( in ) {
             = .Line.Trim()
             = "Archivo:  | Línea:  | Texto: "
            .Add()
        }
    }

    # Mostrar resultados en pantalla
    if (.Count -eq 0) {
        Write-Host "No se encontraron coincidencias."
    } else {
        Write-Host "
Resultados:"
        
    }

    # Preguntar si guardar, exportar o descartar
     = Read-Host "
¿Deseas (G)uardar, (E)xportar o (B)orrar los resultados? (g/e/b)"

    switch (.ToLower()) {
        "g" {
             = Read-Host "Ruta completa para guardar el archivo de texto"
             | Set-Content -Path  -Encoding UTF8
            Write-Host "Guardado en: "
        }
        "e" {
             = Read-Host "Ruta para exportar (formato JSON)"
             | ConvertTo-Json -Depth 5 | Set-Content -Path  -Encoding UTF8
            Write-Host "Exportado en JSON a: "
        }
        "b" {
            Write-Host "Resultados eliminados del buffer."
        }
        default {
            Write-Host "Opción no válida. No se guardaron datos."
        }
    }
}
