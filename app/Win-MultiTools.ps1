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
    Write-Host "Pulsa cualquier tecla para volver al menú principal..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}


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


function Set-Volumen {
    Clear-Host
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "   CONTROL DE VOLUMEN DEL SISTEMA       " -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan

    # 1. Pedimos al usuario el porcentaje deseado
    $inputVolumen = Read-Host "`nIntroduce el nivel de volumen deseado (0 al 100)"

    # Validamos que lo que ha escrito sea un número entre 0 y 100
    if ($inputVolumen -match "^\d+$" -and [int]$inputVolumen -ge 0 -and [int]$inputVolumen -le 100) {
        $volumenDeseado = [int]$inputVolumen
    }
    else {
        Write-Host "`nError: Debes introducir un número válido entre 0 y 100." -ForegroundColor Red
        Start-Sleep -Seconds 2
        return
    }

    Write-Host "`nAjustando el volumen al $volumenDeseado%..." -ForegroundColor Yellow

    # 2. Inyectamos C# para hablar con la API de Windows (Solo si no se ha inyectado ya)
    if (-not ("ControladorAudio" -as [type])) {
        $codigoCSharp = @"
        using System.Runtime.InteropServices;

        [Guid("5CDF2C82-841E-4546-9722-0CF74078229A"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
        interface IAudioEndpointVolume {
            int NotImpl1(); int NotImpl2(); int NotImpl3(); int NotImpl4();
            int SetMasterVolumeLevelScalar(float fLevel, System.Guid pEventContext);
            int NotImpl6();
            int GetMasterVolumeLevelScalar(out float pfLevel);
            int NotImpl8(); int NotImpl9(); int NotImpl10();
            int SetMute([MarshalAs(UnmanagedType.Bool)] bool bMute, System.Guid pEventContext);
            int GetMute(out bool pbMute);
        }

        [Guid("D666063F-1587-4E43-81F1-B948E807363F"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
        interface IMMDevice {
            int Activate(ref System.Guid id, int clsCtx, int activationParams, out IAudioEndpointVolume aev);
        }

        [Guid("A95664D2-9614-4F35-A746-DE8DB63617E6"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
        interface IMMDeviceEnumerator {
            int NotImpl1();
            int GetDefaultAudioEndpoint(int dataFlow, int role, out IMMDevice endpoint);
        }

        [ComImport, Guid("BCDE0395-E52F-467C-8E3D-C4579291692E")]
        class MMDeviceEnumeratorComObject { }

        public class ControladorAudio {
            public static void SetVolumen(int volumen) {
                var enumerator = new MMDeviceEnumeratorComObject() as IMMDeviceEnumerator;
                IMMDevice dev = null;
                enumerator.GetDefaultAudioEndpoint(0, 1, out dev);
                IAudioEndpointVolume epv = null;
                var epvid = typeof(IAudioEndpointVolume).GUID;
                dev.Activate(ref epvid, 23, 0, out epv);
                epv.SetMasterVolumeLevelScalar((float)volumen / 100f, System.Guid.Empty);
            }
        }
"@
        # Compilamos el código C# en la memoria de PowerShell
        Add-Type -TypeDefinition $codigoCSharp
    }

    # 3. Ejecutamos el cambio de volumen usando la clase que acabamos de crear
    [ControladorAudio]::SetVolumen($volumenDeseado)

    Write-Host "¡Volumen ajustado correctamente al $volumenDeseado%!" -ForegroundColor Green
    
    Write-Host "`nPulsa cualquier tecla para volver al menú principal..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}


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
                Test-RepararRed
            }
            else {
                Write-Host "La función Test-RepararRed no está cargada." -ForegroundColor Red
            }
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
            Pause
        }
        '0' {
            Write-Host "Saliendo del programa..." -ForegroundColor Green
            break
        }
        default {
            Write-Host "Opción no válida. Por favor, selecciona una opción correcta." -ForegroundColor Red
            Start-Sleep -Seconds 2
        }
    }
}



