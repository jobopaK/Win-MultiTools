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