$AppDir = $PSScriptRoot
$SrcDir = Join-Path -Path $AppDir -ChildPath "src"
$OutFile = Join-Path -Path $AppDir -ChildPath "Win-MultiTools.ps1"

# Eliminar archivo de salida anterior si existe
if (Test-Path -Path $OutFile) {
    Remove-Item -Path $OutFile -Force
}

Write-Host "Compilando Win-MultiTools.ps1 en $OutFile..." -ForegroundColor Cyan

# Obtener todos los archivos .ps1 del directorio src y subdirectorios, ordenados y fucionados
Get-ChildItem -Path $SrcDir -Filter "*.ps1" -Recurse | Sort-Object Name | ForEach-Object {
    Write-Host "Añadiendo: $($_.Name)" -ForegroundColor Gray
    $content = Get-Content -Path $_.FullName -Raw
    Add-Content -Path $OutFile -Value $content
    Add-Content -Path $OutFile -Value "`r`n"
}

Write-Host "Compilación completada." -ForegroundColor Green
