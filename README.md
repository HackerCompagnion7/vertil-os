<p align="center">
  <img src="https://img.shields.io/badge/Vertil%20OS-Phase%201-green?style=for-the-badge" alt="Vertil OS Phase 1">
  <img src="https://img.shields.io/badge/Platform-Termux%20%2F%20Android-blue?style=for-the-badge" alt="Platform">
  <img src="https://img.shields.io/badge/Architecture-proot--distro-orange?style=for-the-badge" alt="Architecture">
</p>

# Vertil OS

**Sistema operativo proyectable mediante VNC en Termux/Android.**

Vertil OS es un entorno de escritorio Linux completo que se ejecuta dentro de Termux (Android, sin root) utilizando proot-distro como base. Se construye incrementalmente por fases, garantizando que cada fase sea ejecutable y verificable visualmente antes de avanzar a la siguiente.

---

## Estado Actual: Fase 1 — BASE VIVA

Escritorio mínimo visible en VNC con Openbox, Tint2 y cursor funcional.

## Instalación Rápida

```bash
# 1. Clona el repositorio
git clone https://github.com/HackerCompagnion7/vertil-os.git
cd vertil-os

# 2. Ejecuta la construcción (solo la primera vez)
bash vertil-build.sh

# 3. Inicia Vertil OS
./vertil-start

# 4. Conecta tu cliente VNC a localhost:5901
#    Clientes recomendados: bVNC, RealVNC, MultiVNC

# 5. Para detener: Ctrl+C en la terminal de Termux
```

## Requisitos

- **Termux** (descargado desde [F-Droid](https://f-droid.org/packages/com.termux/), NO Google Play)
- **Cliente VNC** instalado en el dispositivo (bVNC recomendado)
- Al menos **2 GB** de almacenamiento libre para el rootfs de Debian
- Conexión a internet para la primera instalación

## Arquitectura

```
Termux (Android)
└── proot-distro (Debian 12)
    ├── Xvfb (display virtual X11, :0, 1280x720)
    ├── Openbox (gestor de ventanas ultraligero)
    ├── Tint2 (barra de tareas)
    └── TigerVNC / x11vnc (servidor VNC, puerto 5901)
```

## Estructura del Repositorio

```
vertil-os/
├── vertil-build.sh          # Script de instalación única (construye el rootfs)
├── vertil-start             # Script de lanzamiento (inicia el sistema)
├── configs/
│   ├── openbox-rc.xml       # Configuración de Openbox (referencia)
│   ├── openbox-menu.xml     # Menú contextual de Openbox (referencia)
│   └── tint2rc              # Configuración de Tint2 (referencia)
├── docs/
│   └── ROADMAP.md           # Hoja de ruta por fases
├── README.md                # Este archivo
└── LICENSE                  # GPL-3.0
```

> **Nota:** Las configuraciones en `configs/` son copias de referencia. Los valores reales se embeben dentro de `vertil-build.sh` y se instalan automáticamente.

## Lo que ves en VNC (Fase 1)

- ✅ Escritorio vacío con fondo oscuro
- ✅ Cursor del ratón funcional y responsive
- ✅ Barra Tint2 en la parte inferior con reloj (formato 24h)
- ✅ Botón de menú visible (esquina inferior izquierda)
- ✅ Click derecho en el escritorio → menú contextual con "Terminal" y "Reiniciar Openbox"
- ✅ Alt+F4 para cerrar ventanas
- ✅ Entorno estable sin crasheos

## Características del Sistema

| Característica | Detalle |
|---|---|
| Display virtual | Xvfb en `:0`, 1280x720, 24-bit |
| Gestor de ventanas | Openbox con configuración mínima |
| Barra de tareas | Tint2 con reloj y botón de menú |
| Servidor VNC | x0vncserver (fallback: x11vnc) |
| Puerto VNC | 5901 (sin contraseña en Fase 1) |
| Terminal | xterm |
| Logging | `$HOME/.vertil/logs/` con timestamps |
| PID tracking | `$HOME/.vertil/pids` |
| Limpieza | Ordenada en Ctrl+C (SIGINT/SIGTERM) |

## Roadmap

| Fase | Nombre | Estado | Descripción |
|------|--------|--------|-------------|
| 1 | BASE VIVA | ✅ Completa | Escritorio mínimo visible en VNC |
| 2 | IDENTIDAD VISUAL | 🔜 Pendiente | Logo, wallpaper, paleta verde/negro, rofi |
| 3 | BOOT ANIMADO | 🔜 Pendiente | Pantalla de carga con progreso real |
| 4 | ECOSISTEMA .VERTIL | 🔜 Pendiente | Formato de paquete propio, instalador gráfico |
| 5 | PROTECCIÓN Y MARCA | 🔜 Pendiente | Guardian auto-regenerativo, watermark persistente |

Ver [docs/ROADMAP.md](docs/ROADMAP.md) para detalles completos de cada fase.

## Solución de Problemas

### "No se encontro el rootfs de Debian"
Ejecuta `bash vertil-build.sh` primero para crear el rootfs.

### El escritorio no aparece en VNC
1. Verifica que `vertil-start` se esté ejecutando sin errores
2. Revisa los logs en `$HOME/.vertil/logs/`
3. Asegúrate de conectarte al puerto correcto (5901)

### La conexión VNC se rechaza
- Confirma que no hay otra instancia de Vertil OS ejecutándose
- Verifica que el puerto 5901 no esté en uso por otra aplicación

### Tint2 no aparece
Tint2 es no-crítico en Fase 1. Si no se muestra, el escritorio sigue funcional. Revisa `~/.vertil/logs/tint2.log` para detalles.

## Licencia

Este proyecto está licenciado bajo la [GNU General Public License v3.0](LICENSE).

---

<p align="center">
  <strong>Vertil OS</strong> — Un escritorio Linux en tu Android, sin root.
</p>
