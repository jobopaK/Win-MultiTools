<div align="center">
  <h1>🛠️ Win-MultiTools</h1>
  <p>Herramienta multipropósito en PowerShell para la gestión rápida de Red y Sistema en entornos Windows.</p>
</div>

---

## 📖 Descripción

📝 **Win-MultiTools** nace como un script de PowerShell "todo en uno" para realizar tareas administrativas de mantenimiento de forma interactiva y segura. 
Proporciona un menú de consola intuitivo que reúne las herramientas y comandos esenciales en un solo lugar, permitiendo a los usuarios automatizar procesos y ahorrarse la memorización de comandos de sistema.

## ✨ Características Principales

Actualmente, el menú interactivo incluye los siguientes módulos:

- 🌐 **[1] Herramientas de Red**: Reparación integral de la conexión a internet y el adaptador de red.
  - Vaciado de la caché DNS (`ipconfig /flushdns`).
  - Liberación y renovación de IP DHCP (`ipconfig /release` y `/renew`).
  - Restablecimiento del catálogo Winsock y del protocolo TCP/IP.
- 🧹 **[2] Herramientas de Sistema**: Limpieza profunda de archivos temporales.
  - Vaciado de la papelera y directorios temporales de usuario.
  - Limpieza del directorio `Temp` del sistema operativo.
  - Borrado de la caché `Prefetch` para aligerar la carga del sistema.
- 🔊 **[3] Control de Volumen**: Ajuste preciso del volumen maestro.
  - Sistema inteligente de inyección C# para conectarse a la API de control de audio nativa de Windows (CoreAudio API).
  - Permite configurar niveles sonoros del 0% al 100% interactuando directamente en la terminal.

## 🚀 Modo de Ejecución Rápida

La forma más eficiente de probar o utilizar el script, especialmente de forma remota, es utilizando su formato One-Liner (en memoria).

Abre PowerShell **como Administrador** y pega el siguiente comando:

```powershell
irm https://raw.githubusercontent.com/jobopaK/Win-MultiTools/refs/heads/main/app/Win-MultiTools.ps1 | iex
```

> **[!IMPORTANT]**
> El script necesita privilegios de **Elevación de Usuarios** para modificar la pila TPC/IP o borrar archivos de sistema en uso. Si lo ejecutas como un usuario base local, el propio script detectará esta limitación e intentará reiniciar la consola solicitando Permisos de Administrador a través del control de cuentas UAC.

## 💻 Desarrollo y Compilación Local

Si prefieres probar las herramientas, auditar el código o contribuir creando nuevos módulos, realiza una instalación local.

1. Clona este repositorio:
   ```cmd
   git clone https://github.com/jobopaK/Win-MultiTools.git
   ```
2. Accede al directorio principal de la aplicación:
   ```cmd
   cd Win-MultiTools/app
   ```
3. Ejecuta el archivo autogenerado del menú principal:
   ```powershell
   .\Win-MultiTools.ps1
   ```

### 🏗️ Arquitectura del Proyecto Automática

Buscando una buena mantenibilidad de código y diseño de software limpio, la herramienta se construye con un enfoque modular.

- `app/`: Directorio principal.
  - `src/`: Carpeta con los scripts independientes (`NetworkFix.ps1`, `TempDelete.ps1`, `SetVolumen.ps1`, `MainMenu.ps1`). El desarrollo transcurre unicamente en estos archivos.
  - `build.ps1`: **Constructor del entorno.** Script de automatización que agrupa, alinea y codifica (UTF-8) todos los archivos fraccionados de la carpeta `src/` en el ejecutable monolítico final.
  - `Win-MultiTools.ps1`: Archivo final autogenerado, este es el script que se distribuye a los usuarios.
- `docs/`: Arquitectura de la futura documentación y wikis.
- `tests/`: Laboratorio para realizar testeos en partes incompletas del código.

### ⚙️ Generación de Nueva Versión (Build)

Cualquier cambio de código en las funciones de la carpeta `src/` no se aplica automáticamente al entorno. Una vez finalizados tus cambios, compila el código ejecutando:

```powershell
cd app
.\build.ps1
```

Tras esto, ¡verás cómo tu `Win-MultiTools.ps1` se ha actualizado exitosamente!

---
<div align="center">
  <i>🛠️ Desarrollado para ayudar a administradores de sistemas y power-users de ecosistemas Windows. 🛠️</i>
</div>
