function Test-RepararRed {
    Clear-Host
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "   REPARACIÓN DE CONEXIÓN DE RED        " -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan

    # Advertencia de seguridad sobre IPs estáticas / DHCP
    Write-Host "`nATENCIÓN: Esto restablecerá la red a sus valores de fábrica (DHCP)." -ForegroundColor Red
    Write-Host "Si tu equipo o empresa requiere una IP manual/estática, perderás esa configuración." -ForegroundColor Red
    $confirmacion = Read-Host "¿Estás seguro de que deseas continuar? (S/N)"

    if ($confirmacion -notmatch "^[Ss]$") {
        Write-Host "`nOperación cancelada. Volviendo al menú principal..." -ForegroundColor Yellow
        Start-Sleep -Seconds 2
        return # Sale de la función y vuelve al menú
    }

    Write-Host "`nIniciando diagnóstico y reparación de adaptadores...`n" -ForegroundColor Yellow

    # 1. Limpiar la caché DNS
    Write-Host "[1/4] Vaciando la caché DNS..." -ForegroundColor White
    ipconfig /flushdns | Out-Null
    Start-Sleep -Seconds 1

    # 2. Liberar y renovar la IP asignada por el router (DHCP)
    Write-Host "[2/4] Liberando y renovando la dirección IP..." -ForegroundColor White
    ipconfig /release | Out-Null
    ipconfig /renew | Out-Null
    Start-Sleep -Seconds 2

    # 3. Restablecer Winsock
    Write-Host "[3/4] Restableciendo el catálogo Winsock..." -ForegroundColor White
    netsh winsock reset | Out-Null
    Start-Sleep -Seconds 1

    # 4. Restablecer la pila TCP/IP
    Write-Host "[4/4] Restableciendo el protocolo TCP/IP..." -ForegroundColor White
    netsh int ip reset | Out-Null
    Start-Sleep -Seconds 1

    Write-Host "`n¡Reparación de red completada con éxito!" -ForegroundColor Green
    Write-Host "========================================`n"
    
    Write-Host "NOTA: Para que los cambios surtan efecto por completo, reinicia el equipo." -ForegroundColor DarkYellow
    
    Write-Host "`nPulsa cualquier tecla para volver al menú principal..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}