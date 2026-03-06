# 1. Comprobamos si el usuario actual tiene privilegios de Administrador
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "Este programa necesita ejecutarse como Administrador." -ForegroundColor Yellow
    Write-Host "Solicitando permisos, por favor acepte la ventana emergente..." -ForegroundColor Cyan
    Start-Sleep -Seconds 2
    
    # 2. Verificamos si el script se está ejecutando desde un archivo físico
    if ($PSCommandPath) {
        # Si hay un archivo, relanzamos ese mismo archivo como Administrador
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    }
    else {
        # Si se ejecuta directamente en memoria (con el comando irm | iex), no hay archivo que relanzar.
        Write-Host "==========================================================" -ForegroundColor Red
        Write-Host "Este programa se ejecuta de forma online." -ForegroundColor Red
        Write-Host "Debe abrir PowerShell COMO ADMINISTRADOR." -ForegroundColor Red
        Write-Host "(Click derecho -> Ejecutar como Administrador) y volver a pegar el comando." -ForegroundColor Red
        Write-Host "==========================================================" -ForegroundColor Red
        Start-Sleep -Seconds 10
    }
    
    # 3. Cerramos la consola actual que no tiene permisos
    exit
}

# A partir de aquí, el script ya es Administrador de forma garantizada.
Write-Host "Permisos de Administrador confirmados. Cargando Win-MultiTools..." -ForegroundColor Green
Start-Sleep -Seconds 1



function Show-Menu {
    Clear-Host
    Write-Host "=== Win-MultiTools v1.0 ===" -ForegroundColor Cyan
    Write-Host "1. Herramientas de Red"
    Write-Host "2. Herramientas de Sistema"
    Write-Host "3. Ajustar Volumen del Sistema"
    Write-Host "0. Salir"
    Write-Host "==========================" -ForegroundColor Cyan
    
    $choice = Read-Host "Seleccione una opción"
    return $choice
}

while ($true) {
    $option = Show-Menu
    
    switch ($option) {
        '1' {
            Write-Host "Ejecutando opciones de Red..." -ForegroundColor Yellow
            if (Get-Command "Test-RepararRed" -ErrorAction SilentlyContinue) {
                $resultado = Test-RepararRed
                if ($resultado -eq "CANCEL") {
                    continue
                }
            }
            else {
                Write-Host "La función Test-RepararRed no está cargada." -ForegroundColor Red
            }
            Write-Host ""
            Pause
        }
        '2' {
            Write-Host "Ejecutando opciones de Sistema..." -ForegroundColor Yellow
            if (Get-Command "Test-LimpiarTemporales" -ErrorAction SilentlyContinue) {
                Test-LimpiarTemporales
            }
            else {
                Write-Host "La función Test-LimpiarTemporales no está cargada." -ForegroundColor Red
            }
            Write-Host ""
            Pause
        }
        '3' {
            Write-Host "Ejecutando opciones de Volumen..." -ForegroundColor Yellow
            if (Get-Command "Set-Volumen" -ErrorAction SilentlyContinue) {
                Set-Volumen
            }
            else {
                Write-Host "La función Set-Volumen no está cargada." -ForegroundColor Red
            }
            Write-Host ""
            Pause
        }
        '0' {
            Write-Host "Saliendo del programa..." -ForegroundColor Green
            exit
        }
        default {
            Write-Host "Opción no válida. Por favor, selecciona una opción correcta." -ForegroundColor Red
            Start-Sleep -Seconds 2
        }
    }
}
