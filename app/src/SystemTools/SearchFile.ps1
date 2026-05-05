function Search-File {
    Clear-Host
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "         BUSCADOR DE FICHEROS           " -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan

    # 1. Pedimos al usuario el nombre o patrón del fichero
    $nombreFichero = Read-Host "`nIntroduce el nombre del fichero a buscar (Ej: *.ps1, informe.txt, etc.)"

    if ([string]::IsNullOrWhiteSpace($nombreFichero)) {
        Write-Host "Error: No has introducido ningún nombre de fichero." -ForegroundColor Red
        return
    }

    Write-Host "`nBuscando '$nombreFichero' en el disco C:... (Esto puede tardar un poco)" -ForegroundColor Yellow

    # 2. Buscamos el fichero en C:
    # Usamos -ErrorAction SilentlyContinue para ignorar los errores de acceso denegado
    $resultados = Get-ChildItem -Path "C:\" -Filter $nombreFichero -Recurse -Force -File -ErrorAction SilentlyContinue

    # 3. Mostramos los resultados
    if ($resultados) {
        # En caso de que Get-ChildItem devuelva un solo elemento, nos aseguramos de tratarlo como un array
        if ($resultados -isnot [array]) {
            $resultados = @($resultados)
        }

        Write-Host "`nSe han encontrado $($resultados.Count) coincidencia(s):`n" -ForegroundColor Green
        
        foreach ($fichero in $resultados) {
            # Calculamos el tamaño en un formato legible
            if ($fichero.Length -ge 1GB) {
                $tamanoFormateado = "{0:N2} GB" -f ($fichero.Length / 1GB)
            } elseif ($fichero.Length -ge 1MB) {
                $tamanoFormateado = "{0:N2} MB" -f ($fichero.Length / 1MB)
            } elseif ($fichero.Length -ge 1KB) {
                $tamanoFormateado = "{0:N2} KB" -f ($fichero.Length / 1KB)
            } else {
                $tamanoFormateado = "$($fichero.Length) Bytes"
            }

            Write-Host "Ubicación: " -NoNewline -ForegroundColor Cyan
            Write-Host $fichero.FullName
            Write-Host "Tamaño:    " -NoNewline -ForegroundColor Cyan
            Write-Host $tamanoFormateado
            Write-Host "----------------------------------------" -ForegroundColor DarkGray
        }
    } else {
        Write-Host "`nNo se ha encontrado ningún fichero con el nombre o patrón '$nombreFichero' en el disco C:." -ForegroundColor Red
    }
}
