function Test-LimpiarTemporales {
    Clear-Host
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "   LIMPIEZA DE ARCHIVOS TEMPORALES      " -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Iniciando proceso de limpieza, por favor espera...`n" -ForegroundColor Yellow

    # Definimos las carpetas temporales clásicas de Windows
    $rutasTemporales = @(
        $env:TEMP,                 # Temporales del usuario actual
        "$env:WINDIR\Temp",        # Temporales del sistema (Requiere Admin)
        "$env:WINDIR\Prefetch"     # Caché de arranque de aplicaciones (Requiere Admin)
    )

    $archivosBorrados = 0
    $espacioLiberado = 0

    foreach ($ruta in $rutasTemporales) {
        if (Test-Path $ruta) {
            Write-Host "Analizando y limpiando: $ruta" -ForegroundColor DarkGray
            
            # Buscamos todos los archivos y carpetas dentro de la ruta
            $elementos = Get-ChildItem -Path $ruta -Recurse -Force -ErrorAction SilentlyContinue

            foreach ($elemento in $elementos) {
                try {
                    # Si es un archivo, guardamos su tamaño antes de borrarlo
                    if (-not $elemento.PSIsContainer) {
                        $tamano = $elemento.Length
                    }
                    else {
                        $tamano = 0
                    }

                    # Intentamos forzar el borrado
                    Remove-Item -Path $elemento.FullName -Force -Recurse -ErrorAction Stop
                    
                    $archivosBorrados++
                    $espacioLiberado += $tamano
                }
                catch {
                    # Si el archivo está en uso, el script entra aquí y lo ignora en silencio
                }
            }
        }
    }

    # Convertimos los bytes a Megabytes y redondeamos a 2 decimales
    $mbLiberados = [math]::Round($espacioLiberado / 1MB, 2)

    Write-Host "`n¡Limpieza completada con éxito!" -ForegroundColor Green
    Write-Host "----------------------------------------"
    Write-Host "Archivos eliminados: $archivosBorrados" -ForegroundColor White
    Write-Host "Espacio liberado:    $mbLiberados MB" -ForegroundColor White
    Write-Host "========================================`n"
    
    # Pausa para que el usuario pueda leer los resultados antes de volver al menú
}