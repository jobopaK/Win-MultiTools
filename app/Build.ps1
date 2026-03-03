$AppDir = $PSScriptRoot
$SrcDir = Join-Path -Path $AppDir -ChildPath "src"
$OutFile = Join-Path -Path $AppDir -ChildPath "Win-MultiTools.ps1"

# Eliminar archivo de salida anterior si existe
if (Test-Path -Path $OutFile) {
    Remove-Item -Path $OutFile -Force
}

Write-Host "Compilando Win-MultiTools.ps1 en $OutFile..." -ForegroundColor Cyan

# Obtener todos los archivos .ps1 (excepto el menú) y añadirlos al principio
Get-ChildItem -Path $SrcDir -Filter "*.ps1" -Recurse | Where-Object { $_.Name -notmatch "MenuPrincipal" } | Sort-Object Name | ForEach-Object {
    Write-Host "Añadiendo: $($_.Name)" -ForegroundColor Gray
    $content = Get-Content -Path $_.FullName -Raw
    Add-Content -Path $OutFile -Value $content
    Add-Content -Path $OutFile -Value "`r`n"
}

# Obtener el archivo del menú y añadirlo al final
$MenuFile = Get-ChildItem -Path $SrcDir -Filter "*MenuPrincipal.ps1" -Recurse | Select-Object -First 1
if ($MenuFile) {
    Write-Host "Añadiendo: $($MenuFile.Name) (Menu Principal)" -ForegroundColor Gray
    $content = Get-Content -Path $MenuFile.FullName -Raw
    Add-Content -Path $OutFile -Value $content
    Add-Content -Path $OutFile -Value "`r`n"
}

Write-Host "Compilación completada." -ForegroundColor Green
