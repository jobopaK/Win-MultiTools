[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12


function Test-RepararRed {
    Clear-Host
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "   REPARACIÓN DE CONEXIONES DE RED        " -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan

    # Advertencia de seguridad sobre IPs estáticas / DHCP
    Write-Host "`nATENCIÓN: Esto restablecerá la red a sus valores de fábrica." -ForegroundColor Red
    Write-Host "Si tu equipo requiere una IP manual/estática, perderás esa configuración." -ForegroundColor Red
    while ($true) {
        $confirmacion = Read-Host "¿Desea reestablecer todos los valores de red a sus valores por defecto? (S/N)"

        if ($confirmacion -match "^[Ss]$") {
            break # Continuar
        }
        elseif ($confirmacion -match "^[Nn]$") {
            Write-Host "`nOperación cancelada. Presione Entrar para volver..." -ForegroundColor Yellow
            $null = Read-Host
            return "CANCEL"
        }
        else {
            Write-Host "Error: Por favor, introduce 'S' para Sí o 'N' para No." -ForegroundColor Red
        }
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
    
}


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



function Set-Volumen {
    Clear-Host
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "   CONTROL DE VOLUMEN DEL SISTEMA       " -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan

    # 1. Pedimos al usuario el porcentaje deseado
    while ($true) {
        $inputVolumen = Read-Host "`nIntroduce el nivel de volumen deseado (0 al 100)"

        # Validamos que lo que ha escrito sea un número entre 0 y 100
        if ($inputVolumen -match "^\d+$" -and [int]$inputVolumen -ge 0 -and [int]$inputVolumen -le 100) {
            $volumenDeseado = [int]$inputVolumen
            break
        }
        else {
            Write-Host "Error: Debes introducir un número válido entre 0 y 100." -ForegroundColor Red
        }
    }

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

    Write-Host "`n¡Volumen ajustado correctamente al $volumenDeseado%!" -ForegroundColor Green
    
}


function Get-SystemInfo {
    Clear-Host
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "         INFORMACION DEL SISTEMA        " -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Recopilando datos, por favor espera...`n" -ForegroundColor Yellow

    $outBuffer = New-Object System.Collections.ArrayList

    # Colección silenciosa de datos básicos
    $os = Get-CimInstance Win32_OperatingSystem | Select-Object -Property Caption, OSArchitecture, Version, FreePhysicalMemory
    $compsys = Get-CimInstance Win32_ComputerSystem | Select-Object -Property Name, TotalPhysicalMemory
    $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
    $gpus = @(Get-CimInstance Win32_VideoController | Select-Object -Property Name)

    $ramTotal = [math]::Round($compsys.TotalPhysicalMemory / 1GB, 2)
    $ramFree = [math]::Round($os.FreePhysicalMemory / 1MB, 2)

    $reg = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
    $buildNumber = "$($reg.CurrentBuild).$($reg.UBR)"
    $displayVersion = if ($reg.DisplayVersion) { $reg.DisplayVersion } else { $reg.ReleaseId }

    $uefi = "Desconocido"
    $secureBoot = "Desconocido"
    try {
        $sb = Confirm-SecureBootUEFI -ErrorAction Stop
        $uefi = "Presente"
        $secureBoot = if ($sb) { "Activado" } else { "Desactivado" }
    }
    catch {
        if ($_.FullyQualifiedErrorId -match "CmdletNotSupported") {
            $uefi = "No Presente (Legacy/BIOS)"
            $secureBoot = "No Soportado"
        }
        else {
            $uefi = "Presente"
            $secureBoot = "Desactivado o Soportado sin permisos"
        }
    }

    [void]$outBuffer.Add(@{ Text = "--- Usuario y SO ---"; Color = "Cyan" })
    [void]$outBuffer.Add(@{ Text = "Usuario:      $($env:USERNAME)"; Color = "White" })
    [void]$outBuffer.Add(@{ Text = "Equipo:       $($compsys.Name)"; Color = "White" })
    [void]$outBuffer.Add(@{ Text = "Sistema:      $($os.Caption) ($($os.OSArchitecture)) Build $buildNumber ($displayVersion)"; Color = "White" })
    [void]$outBuffer.Add(@{ Text = "UEFI:         $uefi"; Color = "White" })
    [void]$outBuffer.Add(@{ Text = "Secure Boot:  $secureBoot"; Color = "White" })
    
    # --- PROCESADOR ---
    [void]$outBuffer.Add(@{ Text = "`n--- Procesador ---"; Color = "Cyan" })
    [void]$outBuffer.Add(@{ Text = "CPU:                $($cpu.Name)"; Color = "White" })

    $clockSpeed = if ($cpu.MaxClockSpeed) { "$([math]::Round($cpu.MaxClockSpeed / 1000, 2)) GHz" } else { "Desconocida" }
    [void]$outBuffer.Add(@{ Text = "Velocidad base:     $clockSpeed"; Color = "White" })
    [void]$outBuffer.Add(@{ Text = "Núcleos:            $($cpu.NumberOfCores)"; Color = "White" })
    [void]$outBuffer.Add(@{ Text = "Núcleos logicos:    $($cpu.NumberOfLogicalProcessors)"; Color = "White" })
    
    $virt = if ($cpu.VirtualizationFirmwareEnabled) { "Activada" } else { "Desactivada o No Soportada" }
    [void]$outBuffer.Add(@{ Text = "Virtualización:     $virt"; Color = "White" })
    
    $l1 = "N/A"; $l2 = "N/A"; $l3 = "N/A"
    try {
        $caches = Get-CimInstance Win32_CacheMemory -ErrorAction SilentlyContinue
        if ($caches) {
            foreach ($cache in $caches) {
                if ($cache.Purpose -match "L1" -and $cache.InstalledSize) { $l1 = "$($cache.InstalledSize) KB" }
                if ($cache.Purpose -match "L2" -and $cache.InstalledSize) { $l2 = "$([math]::Round($cache.InstalledSize / 1024, 1)) MB" }
                if ($cache.Purpose -match "L3" -and $cache.InstalledSize) { $l3 = "$([math]::Round($cache.InstalledSize / 1024, 1)) MB" }
            }
        }
    }
    catch {}
    
    [void]$outBuffer.Add(@{ Text = "Caché L1:           $l1"; Color = "White" })
    [void]$outBuffer.Add(@{ Text = "Caché L2:           $l2"; Color = "White" })
    [void]$outBuffer.Add(@{ Text = "Caché L3:           $l3"; Color = "White" })

    [void]$outBuffer.Add(@{ Text = "`n--- Memoria RAM ---"; Color = "Cyan" })

    $ramModules = @(Get-CimInstance Win32_PhysicalMemory -ErrorAction SilentlyContinue)
    $ramArray = Get-CimInstance Win32_PhysicalMemoryArray -ErrorAction SilentlyContinue
    
    $slotsUsed = $ramModules.Count
    $slotsTotal = if ($ramArray -and $ramArray.MemoryDevices) { $ramArray.MemoryDevices } else { "N/A" }
    
    $speed = if ($ramModules -and $ramModules[0].ConfiguredClockSpeed) { 
        "$($ramModules[0].ConfiguredClockSpeed) MHz" 
    }
    elseif ($ramModules -and $ramModules[0].Speed) { 
        "$($ramModules[0].Speed) MHz" 
    }
    else { 
        "Desconocida" 
    }
    
    [void]$outBuffer.Add(@{ Text = "RAM Total:          $ramTotal GB"; Color = "White" })
    [void]$outBuffer.Add(@{ Text = "RAM Libre:          $ramFree GB"; Color = "White" })
    $xmpEnabled = "No / Desconocido"
    if ($ramModules -and $ramModules[0].ConfiguredClockSpeed -and $ramModules[0].Speed) {
        if ([int]$ramModules[0].ConfiguredClockSpeed -gt [int]$ramModules[0].Speed) {
            $xmpEnabled = "Sí"
        }
        else {
            $xmpEnabled = "No"
        }
    }

    [void]$outBuffer.Add(@{ Text = "Velocidad:          $speed"; Color = "White" })
    [void]$outBuffer.Add(@{ Text = "XMP/EXPO:           $xmpEnabled"; Color = "White" })
    [void]$outBuffer.Add(@{ Text = "Ranuras usadas:     $slotsUsed de $slotsTotal"; Color = "White" })
    
    $slotNum = 1
    foreach ($mod in $ramModules) {
        [void]$outBuffer.Add(@{ Text = "Slot $($slotNum):"; Color = "Yellow" })
        
        $modModel = if ($mod.PartNumber -and $mod.PartNumber.Trim() -ne "Unknown" -and $mod.PartNumber.Trim() -ne "") { $mod.PartNumber.Trim() } else { "Desconocido" }
        [void]$outBuffer.Add(@{ Text = "  Modelo: $modModel"; Color = "White" })
        
        $modGB = if ($mod.Capacity) { [math]::Round($mod.Capacity / 1GB, 0) } else { "N/A" }
        [void]$outBuffer.Add(@{ Text = "  Tamaño: $($modGB) GB"; Color = "White" })
        
        # Mapeo de SMBIOSMemoryType (WMI) a nombre de tipo de memoria
        $memType = "Desconocido"
        if ($mod.SMBIOSMemoryType) {
            switch ($mod.SMBIOSMemoryType) {
                20 { $memType = "DDR" }
                21 { $memType = "DDR2" }
                24 { $memType = "DDR3" }
                26 { $memType = "DDR4" }
                34 { $memType = "DDR5" }
            }
        }
        elseif ($mod.MemoryType) {
            # Fallback lógico (menos fiable)
            switch ($mod.MemoryType) {
                20 { $memType = "DDR" }
                21 { $memType = "DDR2" }
                24 { $memType = "DDR3" }
            }
        }
        [void]$outBuffer.Add(@{ Text = "  Tipo:   $memType"; Color = "White" })
        
        $slotNum++
    }
    
    [void]$outBuffer.Add(@{ Text = "`n--- Tarjeta Gráfica ---"; Color = "Cyan" })
    foreach ($gpu in $gpus) {
        $gpuName = if ($gpu.Name) { $gpu.Name } else { "Gráfica Desconocida" }
        [void]$outBuffer.Add(@{ Text = $gpuName; Color = "Yellow" })
        
        # Calcular memoria total buscando en el registro para evitar el límite de 4GB (32-bit de WMI)
        $gpuMem = "Desconocida"
        $rawMemGB = 0
        $memBytes = 0
        
        try {
            $regMem = Get-ItemProperty "HKLM:\SYSTEM\ControlSet001\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\*" -ErrorAction Ignore | Where-Object { $_.DriverDesc -eq $gpu.Name } | Select-Object -ExpandProperty HardwareInformation.qwMemorySize -First 1
            if ($regMem) {
                $memBytes = $regMem
            }
            elseif ($gpu.AdapterRAM) {
                $memBytes = $gpu.AdapterRAM
            }
        }
        catch {
            if ($gpu.AdapterRAM) { $memBytes = $gpu.AdapterRAM }
        }

        if ($memBytes -gt 0) {
            $rawMemGB = $memBytes / 1GB
            $rawMemMB = [math]::Round($memBytes / 1MB, 0)
            
            if ($rawMemMB -lt 1024) {
                $gpuMem = "$rawMemMB MB"
            }
            else {
                $gpuMem = "$([math]::Round($rawMemGB, 0)) GB"
            }
        }

        # Determinar Arquitectura leyendo el Vendor ID (Fabricante de Hardware Real) y la VRAM detectada
        $arch = "Desconocida"
        $venId = if ($gpu.PNPDeviceID) { $gpu.PNPDeviceID } else { "" }
        
        if ($venId -match "VEN_10DE") {
            # 10DE es el Vendor ID exclusivo de NVIDIA en PCIe. 100% GPUs dedicadas.
            $arch = "Dedicada"
        }
        elseif ($venId -match "VEN_1002" -or $venId -match "VEN_1022" -or $venId -match "VEN_8086") {
            # 1002/1022 son AMD. 8086 es Intel. Ambos fabrican APUs (Integradas) y Dedicadas.
            # Una GPU integrada (UMA) rara vez se le reserva más de 2.5 GB. 
            if ($rawMemGB -le 2.5 -and $rawMemGB -gt 0) {
                $arch = "Integrada / APU"
            }
            elseif ($rawMemGB -gt 2.5) {
                $arch = "Dedicada"
            }
            else {
                $arch = "Integrada / APU"
            }
        }
        else {
            # Fallback genérico a la regla de VRAM en caso de fallar o Vendor ID raro.
            if ($rawMemGB -le 2.5 -and $rawMemGB -gt 0) { $arch = "Integrada / APU" } else { $arch = "Dedicada" }
        }

        
        [void]$outBuffer.Add(@{ Text = "  Memoria total:  $gpuMem"; Color = "White" })
        [void]$outBuffer.Add(@{ Text = "  Arquitectura:   $arch"; Color = "White" })
    }

    [void]$outBuffer.Add(@{ Text = "`n--- Discos (Locales) ---"; Color = "Cyan" })
    # Convertimos explícitamente a array y bloqueamos los stream pipes
    $physicalDisks = @(Get-PhysicalDisk | Select-Object -Property DeviceId, FriendlyName, MediaType, BusType | Sort-Object DeviceId)
    
    foreach ($disk in $physicalDisks) {
        $diskInfo = Get-Disk -Number $disk.DeviceId -ErrorAction SilentlyContinue
        $partStyle = if ($diskInfo.PartitionStyle) { $diskInfo.PartitionStyle } else { "" }
        $diskSizeGB = if ($diskInfo.Size) { "$([math]::Round($diskInfo.Size / 1GB, 0))GB" } else { "" }
        
        $extraInfo = ("$diskSizeGB $partStyle").Trim()
        $diskTitle = if ($extraInfo) { "$($disk.FriendlyName) ($extraInfo)" } else { "$($disk.FriendlyName)" }
        
        [void]$outBuffer.Add(@{ Text = $diskTitle; Color = "Yellow" })
        
        try {
            $partitions = Get-Partition -DiskNumber $disk.DeviceId -ErrorAction SilentlyContinue
            $hasParts = $false
            if ($partitions) {
                foreach ($part in $partitions) {
                    if ($part.Size -gt 0) {
                        $hasParts = $true
                        $driveStr = if ($part.DriveLetter) { $part.DriveLetter + ":" } else { "---" }
                        
                        $totMB = [math]::Round($part.Size / 1MB, 0)
                        $totStr = if ($totMB -lt 1024) { "$totMB MB" } else { "$([math]::Round($part.Size / 1GB, 2)) GB" }

                        if ($part.DriveLetter) {
                            $vol = Get-Volume -DriveLetter $part.DriveLetter -ErrorAction SilentlyContinue
                            $fileSys = if ($vol -and $vol.FileSystem) { $vol.FileSystem } else { $part.Type }
                            
                            $freeStr = "N/A"
                            if ($vol -and $vol.SizeRemaining -ne $null) {
                                $freeMB = [math]::Round($vol.SizeRemaining / 1MB, 0)
                                $freeStr = if ($freeMB -lt 1024) { "$freeMB MB" } else { "$([math]::Round($vol.SizeRemaining / 1GB, 2)) GB" }
                            }
                            
                            [void]$outBuffer.Add(@{ Text = "  * Unidad [$driveStr] -> Formato: $fileSys | Total: $totStr | Libre: $freeStr"; Color = "White" })
                        }
                        else {
                            [void]$outBuffer.Add(@{ Text = "  * Partición [---] -> Tipo: $($part.Type) | Tamaño: $totStr"; Color = "White" })
                        }
                    }
                }
            }
            if (-not $hasParts) {
                [void]$outBuffer.Add(@{ Text = "  * Sin particiones reconocidas o disco vacio."; Color = "DarkGray" })
            }
        }
        catch {}
    }




    # IMPRIMIR TODO SECUENCIALMENTE AL FINAL
    Clear-Host
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "         INFORMACION DEL SISTEMA        " -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    foreach ($line in $outBuffer) {
        Write-Host $line.Text -ForegroundColor $line.Color
    }
    Write-Host "`n========================================`n" -ForegroundColor Cyan
}



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
    Write-Host "4. Información del Sistema"
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
        '4' {
            Write-Host "Compilando Información del Sistema..." -ForegroundColor Yellow
            if (Get-Command "Get-SystemInfo" -ErrorAction SilentlyContinue) {
                Get-SystemInfo
            }
            else {
                Write-Host "La función Get-SystemInfo no está cargada." -ForegroundColor Red
            }
            Write-Host ""
            Pause
        }
                '5' {
            Write-Host "Buscador de ficheros" -ForegroundColor Yellow
            if (Get-Command "Search-File" -ErrorAction SilentlyContinue) {
                Search-File
            }
            else {
                Write-Host "La función Search-File no está cargada." -ForegroundColor Red
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



