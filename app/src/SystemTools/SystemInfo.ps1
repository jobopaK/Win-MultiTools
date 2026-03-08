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
