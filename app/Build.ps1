$AppDir = $PSScriptRoot
$SrcDir = Join-Path -Path $AppDir -ChildPath "src"
$OutFile = Join-Path -Path $AppDir -ChildPath "Win-MultiTools.ps1"

# Eliminar archivo de salida anterior si existe
if (Test-Path -Path $OutFile) {
    Remove-Item -Path $OutFile -Force
}

Write-Host "Compilando Win-MultiTools.ps1 en $OutFile..." -ForegroundColor Cyan

# Forzar TLS 1.2 al principio del archivo compilado para compatibilidad con Windows antiguo
$initCode = "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12"
Add-Content -Path $OutFile -Value $initCode -Encoding UTF8
Add-Content -Path $OutFile -Value "`r`n" -Encoding UTF8

# Obtener todos los archivos .ps1 (excepto el menú) y añadirlos al principio
Get-ChildItem -Path $SrcDir -Filter "*.ps1" -Recurse | Where-Object { $_.Name -notmatch "MainMenu" } | Sort-Object Name | ForEach-Object {
    Write-Host "Añadiendo: $($_.Name)" -ForegroundColor Gray
    $content = Get-Content -Path $_.FullName -Raw -Encoding UTF8
    Add-Content -Path $OutFile -Value $content -Encoding UTF8
    Add-Content -Path $OutFile -Value "`r`n" -Encoding UTF8
}

# Obtener el archivo del menú y añadirlo al final
$MenuFile = Get-ChildItem -Path $SrcDir -Filter "*MainMenu.ps1" -Recurse | Select-Object -First 1
if ($MenuFile) {
    Write-Host "Añadiendo: $($MenuFile.Name) (Main Menu)" -ForegroundColor Gray
    $content = Get-Content -Path $MenuFile.FullName -Raw -Encoding UTF8
    Add-Content -Path $OutFile -Value $content -Encoding UTF8
    Add-Content -Path $OutFile -Value "`r`n" -Encoding UTF8
}

Write-Host "Compilación completada." -ForegroundColor Green
