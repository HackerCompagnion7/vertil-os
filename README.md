<p align="center">
  <img src="https://img.shields.io/badge/Vertil%20OS-Phase%201-green?style=for-the-badge" alt="Vertil OS Phase 1">
  <img src="https://img.shields.io/badge/Platform-Termux%20%2F%20Android-blue?style=for-the-badge" alt="Platform">
  <img src="https://img.shields.io/badge/Architecture-proot--distro-orange?style=for-the-badge" alt="Architecture">
</p>

# Vertil OS

**Sistema operativo proyectable mediante VNC en Termux/Android.**

Vertil OS es un entorno de escritorio Linux que se ejecuta dentro de Termux (Android, sin root) utilizando proot-distro como base. Se construye incrementalmente por fases, garantizando que cada fase sea ejecutable y verificable visualmente antes de avanzar a la siguiente.

---

## Estado Actual: Fase 1 — BASE VIVA

Escritorio mínimo visible en VNC con Openbox, Tint2 y cursor funcional.

## Instalación y Uso

```bash
# 1. Clona el repositorio en Termux
git clone https://github.com/HackerCompagnion7/vertil-os.git
cd vertil-os

# 2. Construye el sistema (SOLO en Termux)
bash vertil-build.sh

# 3. Inicia Vertil OS (dos opciones)

# Opción A: Lanzador rápido (desde Termux)
./vertil

# Opción B: Manual (dos pasos)
proot-distro login debian --bind ~/vertil-os:/root/vertil-os
# Dentro de Debian:
cd /root/vertil-os && ./vertil-start

# 4. Conecta tu cliente VNC a localhost:5901
#    (Recomendado: bVNC desde F-Droid)

# 5. Para detener: Ctrl+C
```

## Requisitos

- **Termux** (descargado desde [F-Droid](https://f-droid.org/packages/com.termux/), NO Google Play)
- **Cliente VNC** instalado en el dispositivo (bVNC recomendado)
- Al menos **2 GB** de almacenamiento libre para el rootfs de Debian
- Conexión a internet para la primera instalación

## Arquitectura — Separación Estricta de Capas

```
CAPA TERMUX                          CAPA DEBIAN
━━━━━━━━━━━━                         ━━━━━━━━━━━━
vertil-build.sh                      vertil-start
  • Instala proot-distro               • Inicia Xvfb
  • Instala Debian                     • Inicia Openbox
  • Instala paquetes                   • Inicia Tint2
  • Instala configs                    • Inicia VNC
  • Validacion: proot-distro list      • Validacion: ! $TERMUX_VERSION
  • Guard: $TERMUX_VERSION             • Guard: ! proot-distro en PATH

vertil (lanzador)
  • proot-distro login
  • --bind ~/vertil-os:/root/vertil-os
  • ejecuta vertil-start
```

**Regla fundamental:** Cada script pertenece a una capa. Nunca se mezclan.

## Estructura del Repositorio

```
vertil-os/
├── vertil-build.sh      # CAPA TERMUX — Bootstrap (instalacion unica)
├── vertil-start         # CAPA DEBIAN — Runtime (inicio de servicios)
├── vertil               # CAPA TERMUX — Lanzador rapido
├── configs/             # Configuraciones de referencia
│   ├── openbox-rc.xml
│   ├── openbox-menu.xml
│   └── tint2rc
├── docs/
│   └── ROADMAP.md       # Hoja de ruta por fases
└── README.md
```

## Reglas de Ejecución

| Regla | Detalle |
|-------|---------|
| Debian instalado | Solo se valida con `proot-distro list` |
| Entorno Termux | Solo válido si existe `$TERMUX_VERSION` |
| Entorno Debian | Solo válido si NO existe `$TERMUX_VERSION` |
| `$PREFIX` | Solo existe en Termux, no se usa en Debian |
| proot-distro | Solo se ejecuta en Termux, NUNCA dentro de Debian |
| "container already exists" | No es error, es estado válido |
| Mensajes de consola | No son verdad verificable, solo exit codes |

## Lo que ves en VNC (Fase 1)

- ✅ Escritorio vacío con fondo oscuro
- ✅ Cursor del ratón funcional y responsive
- ✅ Barra Tint2 en la parte inferior con reloj (formato 24h)
- ✅ Botón de menú visible (esquina inferior izquierda)
- ✅ Click derecho en el escritorio → menú con "Terminal" y "Reiniciar Openbox"
- ✅ Alt+F4 para cerrar ventanas
- ✅ Entorno estable sin crasheos

## Solución de Problemas

### "No se detecto $TERMUX_VERSION"
Estás dentro de Debian. Sal con `exit` y ejecuta desde Termux.

### "Se detecto $TERMUX_VERSION" (en vertil-start)
Estás en Termux, no en Debian. Entra a Debian primero:
```bash
proot-distro login debian --bind ~/vertil-os:/root/vertil-os
```

### "proot-distro detectado en PATH"
vertil-start se está ejecutando en Termux en vez de Debian. Usa `./vertil` para lanzarlo correctamente.

### "Debian no esta instalado"
Ejecuta `bash vertil-build.sh` desde Termux.

## Roadmap

| Fase | Nombre | Estado |
|------|--------|--------|
| 1 | BASE VIVA | ✅ Completa |
| 2 | IDENTIDAD VISUAL | 🔜 Pendiente |
| 3 | BOOT ANIMADO | 🔜 Pendiente |
| 4 | ECOSISTEMA .VERTIL | 🔜 Pendiente |
| 5 | PROTECCIÓN Y MARCA | 🔜 Pendiente |

Ver [docs/ROADMAP.md](docs/ROADMAP.md) para detalles completos.

## Licencia

[GNU General Public License v3.0](LICENSE)

---

<p align="center">
  <strong>Vertil OS</strong> — Un escritorio Linux en tu Android, sin root.
</p>
