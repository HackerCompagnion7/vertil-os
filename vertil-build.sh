#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
# vertil-build.sh — Script de instalacion unica para Vertil OS
# Fase 1: BASE VIVA
# DEBE ejecutarse dentro de Termux (fuera de cualquier proot)
# ============================================================

set -e

# ============================================================
# 0. VALORES POR DEFECTO PARA VARIABLES TERMUX
#    Estas variables existen nativamente en Termux, pero
#    definimos defaults defensivos para evitar crashes.
# ============================================================
PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
HOME="${HOME:-/data/data/com.termux/files/home}"

# ============================================================
# 1. VERIFICACION DE ENTORNO — CAPA 1: TERMUX OBLIGATORIO
# ============================================================
# 1a. Verificar que NO estamos dentro de un proot
if [ -n "${PROOT:-}" ] || [ -n "${PROOT_TMP:-}" ]; then
    echo ""
    echo "  ERROR CRITICO: Este script se esta ejecutando dentro de un entorno proot."
    echo "  vertil-build.sh DEBE ejecutarse en Termux nativo, NO dentro de Debian."
    echo ""
    echo "  Salga del entorno proot primero:"
    echo "    exit"
    echo ""
    echo "  Luego ejecute desde Termux:"
    echo "    bash vertil-build.sh"
    echo ""
    exit 1
fi

# 1b. Verificar que estamos en Termux (variable exclusiva de Termux)
if [ -z "${TERMUX_VERSION:-}" ]; then
    # Doble verificacion: buscar binarios caracteristicos de Termux
    if [ ! -x "${PREFIX}/bin/pkg" ] && [ ! -x "${PREFIX}/bin/apt" ]; then
        echo ""
        echo "  ERROR: Este script debe ejecutarse dentro de Termux."
        echo "  No se detecto \$TERMUX_VERSION ni binarios de Termux."
        echo "  Descargue Termux desde F-Droid: https://f-droid.org/packages/com.termux/"
        echo ""
        exit 1
    fi
    # Si llegamos aqui, hay binarios Termux pero no la variable
    echo "  AVISO: \$TERMUX_VERSION no esta definida, pero se detectaron binarios de Termux."
    echo "  Continuando con cautela..."
fi

# 1c. Verificar que proot-distro NO esta ejecutandose actualmente
#     (previene el error "proot-distro should not be executed under PRoot")
if [ -f "/.proot-env" ] 2>/dev/null || grep -q "proot" /proc/self/maps 2>/dev/null; then
    echo ""
    echo "  ERROR CRITICO: Se detecto que el proceso actual esta bajo proot."
    echo "  vertil-build.sh no puede ejecutarse dentro de proot."
    echo "  Salga del entorno proot e intente de nuevo."
    echo ""
    exit 1
fi

echo ""
echo "  ========================================="
echo "    Vertil OS - Fase 1: Construccion Base"
echo "  ========================================="
echo ""
echo "  Entorno detectado: Termux (OK)"
echo "  PREFIX: ${PREFIX}"
echo "  HOME: ${HOME}"
echo ""

# ============================================================
# 2. INSTALAR PROOT-DISTRO
# ============================================================
echo "[1/8] Verificando proot-distro..."
if ! command -v proot-distro &>/dev/null; then
    echo "       Instalando proot-distro..."
    pkg install -y proot-distro
else
    echo "       proot-distro ya esta instalado."
fi

# ============================================================
# 3. INSTALAR DEBIAN EN PROOT-DISTRO
#    Usar `proot-distro list` para validacion confiable
#    en lugar de verificar rutas internas del filesystem.
# ============================================================
echo "[2/8] Verificando distribucion Debian..."

DEBIAN_INSTALLED=false
# Metodo primario: proot-distro list (mas confiable)
if proot-distro list 2>/dev/null | grep -qi "debian.*installed"; then
    DEBIAN_INSTALLED=true
fi
# Metodo secundario: verificar directorio rootfs
ROOTFS="${PREFIX}/var/lib/proot-distro/installed-rootfs/debian"
if [ -d "${ROOTFS}" ] && [ -d "${ROOTFS}/usr" ]; then
    DEBIAN_INSTALLED=true
fi

if [ "${DEBIAN_INSTALLED}" = "true" ]; then
    echo "       Debian ya esta instalado en proot-distro."
else
    echo "       Instalando Debian (esto puede tardar varios minutos)..."
    proot-distro install debian
    
    # Esperar a que el registro se complete
    echo "       Verificando instalacion..."
    sleep 3
    
    # Verificar que la instalacion tuvo exito
    if ! proot-distro list 2>/dev/null | grep -qi "debian.*installed"; then
        echo "  ERROR: La instalacion de Debian no se registro correctamente."
        echo "  Intentando verificar por directorio rootfs..."
        if [ ! -d "${ROOTFS}" ] || [ ! -d "${ROOTFS}/usr" ]; then
            echo "  ERROR: El rootfs no se creo. Intente manualmente:"
            echo "    proot-distro install debian"
            exit 1
        fi
    fi
    echo "       Debian instalado correctamente."
fi

# ============================================================
# 4. VALIDAR ROOTFS
# ============================================================
echo "[3/8] Validando rootfs de Debian..."

if [ ! -d "${ROOTFS}" ]; then
    echo "  ERROR: El rootfs de Debian no se encuentra en: ${ROOTFS}"
    echo "  La instalacion de Debian puede haber fallado."
    echo "  Intente ejecutar: proot-distro install debian"
    exit 1
fi

if [ ! -d "${ROOTFS}/usr" ]; then
    echo "  ERROR: El rootfs de Debian parece incompleto (falta /usr)."
    echo "  Intente ejecutar: proot-distro install debian"
    exit 1
fi

echo "       Rootfs validado en: ${ROOTFS}"

# ============================================================
# 5. INSTALAR PAQUETES DENTRO DE DEBIAN
#    Esto se ejecuta via proot-distro login desde Termux.
# ============================================================
echo "[4/8] Instalando paquetes dentro de Debian..."
echo "       (Esto puede tardar unos minutos la primera vez)"

proot-distro login debian -- bash -c '
    export DEBIAN_FRONTEND=noninteractive
    
    # Verificar que estamos en Debian y no en Termux
    if [ ! -f /etc/debian_version ]; then
        echo "ERROR: No se detecto Debian dentro del proot."
        exit 1
    fi
    
    apt update -y
    
    # Instalar paquetes esenciales
    apt install -y \
        xvfb \
        openbox \
        tigervnc-standalone-server \
        x11vnc \
        xfonts-base \
        tint2 \
        xterm \
        qrencode \
        adwaita-icon-theme \
        dbus \
        procps \
        psmisc \
        2>&1 | tail -5
    
    # Verificar que los paquetes criticos se instalaron
    for pkg in xvfb openbox x11vnc tint2 xterm; do
        if ! command -v "$pkg" &>/dev/null; then
            echo "AVISO: $pkg no se encontro en PATH, verificando en ubicaciones comunes..."
        fi
    done
    
    echo "INSTALACION_COMPLETADA=1"
'

# Verificar que x0vncserver o x11vnc se instalaron en el rootfs
VNC_FOUND=false
if [ -x "${ROOTFS}/usr/bin/x0vncserver" ] || [ -x "${ROOTFS}/usr/bin/x11vnc" ]; then
    VNC_FOUND=true
fi
if [ "${VNC_FOUND}" = "false" ]; then
    echo "  AVISO: No se encontro servidor VNC en el rootfs."
    echo "  El sistema intentara usar x11vnc como fallback al iniciar."
fi

echo "       Paquetes instalados correctamente."

# ============================================================
# 6. CREAR CONFIGURACION DE OPENBOX (rc.xml)
# ============================================================
echo "[5/8] Configurando Openbox..."

mkdir -p "${ROOTFS}/root/.config/openbox"

cat > "${ROOTFS}/root/.config/openbox/rc.xml" << 'OPENBOXRC'
<?xml version="1.0" encoding="UTF-8"?>
<openbox_config xmlns="http://openbox.org/3.4/rc"
  xmlns:xi="http://www.w3.org/2001/XInclude">

  <resistance>
    <strength>10</strength>
    <screen_edge_strength>20</screen_edge_strength>
  </resistance>

  <focus>
    <focusNew>yes</focusNew>
    <followMouse>no</followMouse>
    <focusLast>yes</focusLast>
    <underMouse>no</underMouse>
    <focusDelay>200</focusDelay>
    <raiseOnFocus>no</raiseOnFocus>
  </focus>

  <placement>
    <policy>Smart</policy>
    <center>yes</center>
    <monitor>Active</monitor>
    <primaryMonitor>Active</primaryMonitor>
  </placement>

  <theme>
    <name>Clearlooks</name>
    <titleLayout>NLIMC</titleLayout>
    <titleFont>sans 10</titleFont>
    <keepBorder>yes</keepBorder>
    <animateIconify>no</animateIconify>
    <font place="ActiveWindow">
      <name>sans</name><size>10</size>
      <weight>Bold</weight><slant>Normal</slant>
    </font>
    <font place="InactiveWindow">
      <name>sans</name><size>10</size>
      <weight>Normal</weight><slant>Normal</slant>
    </font>
    <font place="MenuHeader">
      <name>sans</name><size>10</size>
      <weight>Normal</weight><slant>Normal</slant>
    </font>
    <font place="MenuItem">
      <name>sans</name><size>10</size>
      <weight>Normal</weight><slant>Normal</slant>
    </font>
    <font place="OnScreenDisplay">
      <name>sans</name><size>10</size>
      <weight>Bold</weight><slant>Normal</slant>
    </font>
  </theme>

  <desktops>
    <number>1</number>
    <firstdesk>1</firstdesk>
    <names><name>Desktop 1</name></names>
    <popupTime>0</popupTime>
  </desktops>

  <resize>
    <drawContents>yes</drawContents>
    <popupShow>Never</popupShow>
    <popupPosition>Center</popupPosition>
  </resize>

  <margins>
    <top>0</top><bottom>0</bottom><left>0</left><right>0</right>
  </margins>

  <keyboard>
    <chainQuitKey>C-g</chainQuitKey>
    <!-- Alt+F4: Cerrar ventana -->
    <keybind key="A-F4">
      <action name="Close"/>
    </keybind>
  </keyboard>

  <mouse>
    <doubleClickTime>400</doubleClickTime>
    <context name="Frame">
      <mousebind button="A-Left" action="Press">
        <action name="Focus"/>
        <action name="Raise"/>
      </mousebind>
      <mousebind button="A-Left" action="Drag">
        <action name="Move"/>
      </mousebind>
      <mousebind button="A-Right" action="Drag">
        <action name="Resize"/>
      </mousebind>
    </context>
    <context name="Titlebar">
      <mousebind button="Left" action="Press">
        <action name="Focus"/>
        <action name="Raise"/>
      </mousebind>
      <mousebind button="Left" action="Drag">
        <action name="Move"/>
      </mousebind>
    </context>
    <context name="Desktop">
      <mousebind button="Right" action="Press">
        <action name="ShowMenu"><menu>root-menu</menu></action>
      </mousebind>
      <mousebind button="Left" action="Press">
        <action name="Focus"/>
        <action name="Raise"/>
      </mousebind>
    </context>
    <context name="Client">
      <mousebind button="Left" action="Press">
        <action name="Focus"/>
        <action name="Raise"/>
      </mousebind>
    </context>
    <context name="Root">
      <mousebind button="Right" action="Press">
        <action name="ShowMenu"><menu>root-menu</menu></action>
      </mousebind>
    </context>
  </mouse>

  <menu>
    <file>menu.xml</file>
  </menu>

  <applications></applications>
</openbox_config>
OPENBOXRC

# 6b. CREAR MENU DE OPENBOX (menu.xml)
cat > "${ROOTFS}/root/.config/openbox/menu.xml" << 'OPENBOXMENU'
<?xml version="1.0" encoding="UTF-8"?>
<openbox_menu xmlns="http://openbox.org/3.4/menu">
  <menu id="root-menu" label="Vertil OS">
    <item label="Terminal">
      <action name="Execute"><command>xterm</command></action>
    </item>
    <separator/>
    <item label="Reiniciar Openbox">
      <action name="Reconfigure"/>
    </item>
  </menu>
</openbox_menu>
OPENBOXMENU

echo "       Openbox configurado (rc.xml + menu.xml)"

# ============================================================
# 7. CREAR CONFIGURACION DE TINT2 (tint2rc)
# ============================================================
echo "[6/8] Configurando Tint2..."

mkdir -p "${ROOTFS}/root/.config/tint2"

cat > "${ROOTFS}/root/.config/tint2/tint2rc" << 'TINT2RC'
#-------------------------------------
# Tint2 config - Vertil OS Fase 1
# Configuracion minima: barra con reloj y boton de menu
#-------------------------------------

#----- Panel -----
panel_items = LC
panel_monitor = all
panel_position = bottom center horizontal
panel_size = 100% 28
panel_margin = 0 0
panel_padding = 4 0 4
panel_background_id = 1
panel_layer = top
strut_policy = follow_size

#----- Fondo del panel -----
rounded = 0
border_width = 0
background_color = #1a1a1a 100
border_color = #000000 0
background_id = 1

#----- Segundo fondo (no usado, requerido por tint2) -----
rounded = 0
border_width = 0
background_color = #1a1a1a 100
border_color = #000000 0

#----- Launcher (boton de menu) -----
launcher_padding = 4 2 4
launcher_background_id = 0
launcher_icon_size = 20
launcher_item_app = /usr/share/applications/vertil-menu.desktop

#----- Taskbar (desactivado en Fase 1) -----
taskbar_mode = single_desktop
taskbar_padding = 0 0 0
taskbar_background_id = 0
taskbar_active_background_id = 0
taskbar_name = 0
taskbar_name_padding = 0 0

#----- Tareas (desactivado en Fase 1) -----
task_text = 0
task_icon = 0

#----- Systray (desactivado) -----
systray_padding = 0 0 0
systray_background_id = 0

#----- Clock -----
time1_format = %H:%M
time1_font = sans bold 10
clock_font_color = #cccccc 100
clock_padding = 8 2
clock_background_id = 0
clock_tooltip_format = %A %d de %B de %Y - %H:%M

#----- Tooltip -----
tooltip_padding = 4 4
tooltip_show_timeout = 0.5
tooltip_hide_timeout = 0.3
tooltip_background_id = 1
tooltip_font_color = #cccccc 100
tooltip_font = sans 9

#----- Battery (desactivado) -----
battery = 0

#----- Mouse -----
mouse_middle = none
mouse_right = close
mouse_scroll_up = none
mouse_scroll_down = none
TINT2RC

# Crear .desktop para el boton de menu en tint2
mkdir -p "${ROOTFS}/usr/share/applications"

cat > "${ROOTFS}/usr/share/applications/vertil-menu.desktop" << 'DESKTOPMENU'
[Desktop Entry]
Name=Menu
Comment=Vertil OS - Menu (Fase 1)
Exec=echo "Menu no disponible en Fase 1"
Icon=utilities-terminal
Type=Application
Categories=System;
DESKTOPMENU

echo "       Tint2 configurado (tint2rc + .desktop)"

# ============================================================
# 8. CREAR SCRIPT VERTIL-START EN $HOME
#    Este script se ejecuta desde Termux y gestiona proot internamente.
# ============================================================
echo "[7/8] Generando script vertil-start..."

cat > "${HOME}/vertil-start" << 'VERTILSTART'
#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
# vertil-start — Script de lanzamiento de Vertil OS Fase 1
# ============================================================
# CAPA: Termux (fuera del proot)
# PROPOSITO: Lanzar proot-distro con el script interno que
#            inicia Xvfb, Openbox, Tint2 y VNC.
# REGLA: El usuario NUNCA debe teclear proot-distro login.
# ============================================================

set -eo pipefail

# ============================================================
# VALORES POR DEFECTO PARA VARIABLES TERMUX
#    Evita el crash "PREFIX: unbound variable"
#    Estas variables siempre existen en Termux nativo,
#    pero las definimos defensivamente.
# ============================================================
PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
HOME="${HOME:-/data/data/com.termux/files/home}"

# ============================================================
# VERIFICACIONES DE ENTORNO — PRIMERO QUE NADA
# ============================================================

# 1. Verificar que NO estamos dentro de un proot
if [ -n "${PROOT:-}" ] || [ -n "${PROOT_TMP:-}" ]; then
    echo ""
    echo "  ERROR: Este script se esta ejecutando dentro de un entorno proot."
    echo "  vertil-start DEBE ejecutarse en Termux nativo."
    echo ""
    echo "  Salga del proot primero:"
    echo "    exit"
    echo ""
    echo "  Luego ejecute desde Termux:"
    echo "    ./vertil-start"
    echo ""
    exit 1
fi

# 2. Verificar que estamos en Termux
if [ -z "${TERMUX_VERSION:-}" ] && [ ! -x "${PREFIX}/bin/pkg" ]; then
    echo ""
    echo "  ERROR: Este script requiere Termux."
    echo "  No se detecto \$TERMUX_VERSION ni el binario 'pkg'."
    echo ""
    exit 1
fi

# ============================================================
# CONSTANTES
# ============================================================
ROOTFS="${PREFIX}/var/lib/proot-distro/installed-rootfs/debian"
LOG_DIR="${HOME}/.vertil/logs"
PID_FILE="${HOME}/.vertil/pids"
READY_FLAG="${HOME}/.vertil/ready"
INNER_SCRIPT="/root/vertil-inner.sh"
DISPLAY_NUM=":0"
RESOLUTION="1280x720x24"
VNC_PORT="5901"

# Colores para la terminal
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ============================================================
# DIRECTORIOS Y LOG PRINCIPAL
# ============================================================
mkdir -p "${LOG_DIR}"

MAIN_LOG="${LOG_DIR}/vertil-$(date +%Y%m%d-%H%M%S).log"

log() {
    local level="$1"; shift
    local msg="$*"
    local ts
    ts=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${ts}] [${level}] ${msg}" | tee -a "${MAIN_LOG}"
}

info()  { log "INFO"  "$@"; }
warn()  { log "WARN"  "$@"; }
error() { log "ERROR" "$@"; }

# ============================================================
# PROOT PID (inicializar vacio)
# ============================================================
PROOT_PID=""

# ============================================================
# FUNCION DE LIMPIEZA
# ============================================================
cleanup() {
    echo ""
    info "Senal de terminacion recibida. Limpiando procesos..."

    # 1. Leer PIDs del archivo y matar procesos internos
    if [ -f "${PID_FILE}" ]; then
        info "Leyendo PIDs desde ${PID_FILE}..."
        while IFS= read -r pid_entry; do
            local name
            name=$(echo "$pid_entry" | cut -d: -f1 | tr -d ' ')
            local pid
            pid=$(echo "$pid_entry" | cut -d: -f2 | tr -d ' ')
            if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
                info "Deteniendo ${name} (PID ${pid})..."
                kill "$pid" 2>/dev/null || true
                sleep 0.3
            fi
        done < "${PID_FILE}"
        rm -f "${PID_FILE}"
    fi

    # 2. Matar el proceso proot si sigue vivo
    if [ -n "${PROOT_PID:-}" ] && kill -0 "${PROOT_PID}" 2>/dev/null; then
        info "Deteniendo sesion proot (PID ${PROOT_PID})..."
        kill "${PROOT_PID}" 2>/dev/null || true
        sleep 0.5
        # Forzar terminacion si sigue vivo
        if kill -0 "${PROOT_PID}" 2>/dev/null; then
            warn "Forzando terminacion de proot..."
            kill -9 "${PROOT_PID}" 2>/dev/null || true
        fi
    fi

    # 3. Limpieza residual de procesos Xvfb/VNC
    # Estos procesos se ejecutan dentro de proot pero sus PIDs son
    # visibles desde Termux. Si no fueron limpiados por el script
    # interno, los intentamos matar aqui.
    local stale_procs
    stale_procs=$(pgrep -f "Xvfb" 2>/dev/null || true)
    if [ -n "${stale_procs}" ]; then
        info "Limpiando procesos Xvfb residuales..."
        echo "${stale_procs}" | xargs kill 2>/dev/null || true
    fi

    stale_procs=$(pgrep -f "x0vncserver" 2>/dev/null || true)
    if [ -n "${stale_procs}" ]; then
        info "Limpiando procesos x0vncserver residuales..."
        echo "${stale_procs}" | xargs kill 2>/dev/null || true
    fi

    stale_procs=$(pgrep -f "x11vnc" 2>/dev/null || true)
    if [ -n "${stale_procs}" ]; then
        info "Limpiando procesos x11vnc residuales..."
        echo "${stale_procs}" | xargs kill 2>/dev/null || true
    fi

    # 4. Limpiar archivos de estado
    rm -f "${READY_FLAG}"
    rm -f "${ROOTFS}/root/.vertil/ready" 2>/dev/null || true

    info "Limpieza completada. Vertil OS detenido."
    exit 0
}

# Capturar senales de terminacion
trap cleanup SIGINT SIGTERM

# ============================================================
# VERIFICAR QUE EL ROOTFS EXISTE (validacion robusta)
# ============================================================
info "Verificando entorno..."

# Metodo 1: Verificar via proot-distro list (mas confiable)
DEBIAN_READY=false
if command -v proot-distro &>/dev/null; then
    if proot-distro list 2>/dev/null | grep -qi "debian.*installed"; then
        DEBIAN_READY=true
    fi
fi

# Metodo 2: Verificar directorio rootfs directamente
if [ "${DEBIAN_READY}" = "false" ] && [ -d "${ROOTFS}" ] && [ -d "${ROOTFS}/usr" ]; then
    DEBIAN_READY=true
fi

if [ "${DEBIAN_READY}" = "false" ]; then
    error "No se encontro una instalacion de Debian valida."
    error "  proot-distro list no muestra Debian como instalado."
    error "  Rootfs esperado en: ${ROOTFS}"
    error ""
    error "Ejecute primero: bash vertil-build.sh"
    exit 1
fi

# Verificar que los binarios criticos existen en el rootfs
CRITICAL_MISSING=""
for binary in Xvfb openbox xterm; do
    if [ ! -x "${ROOTFS}/usr/bin/${binary}" ]; then
        CRITICAL_MISSING="${CRITICAL_MISSING} ${binary}"
    fi
done

if [ -n "${CRITICAL_MISSING}" ]; then
    error "Faltan binarios criticos en el rootfs:${CRITICAL_MISSING}"
    error "Los paquetes pueden no haberse instalado correctamente."
    error "Ejecute nuevamente: bash vertil-build.sh"
    exit 1
fi

# Verificar que al menos un servidor VNC esta disponible
VNC_SERVER=""
if [ -x "${ROOTFS}/usr/bin/x0vncserver" ]; then
    VNC_SERVER="x0vncserver"
elif [ -x "${ROOTFS}/usr/bin/x11vnc" ]; then
    VNC_SERVER="x11vnc"
else
    error "No se encontro ningun servidor VNC en el rootfs."
    error "Se necesita x0vncserver o x11vnc."
    error "Ejecute nuevamente: bash vertil-build.sh"
    exit 1
fi

info "Entorno validado: Debian instalado, VNC server: ${VNC_SERVER}"

# ============================================================
# LIMPIAR ESTADO ANTERIOR
# ============================================================
rm -f "${READY_FLAG}"
rm -f "${PID_FILE}"
rm -f "${ROOTFS}/root/.vertil/ready" 2>/dev/null || true

# ============================================================
# GENERAR SCRIPT INTERNO (se ejecuta dentro del proot)
# Este script se ejecuta en CAPA DEBIAN (dentro de proot).
# NO usa variables de Termux ($PREFIX, $TERMUX_VERSION, etc.)
# ============================================================
info "Preparando entorno interno..."

mkdir -p "${ROOTFS}/root/.vertil/logs"

cat > "${ROOTFS}${INNER_SCRIPT}" << 'INNERSCRIPT'
#!/bin/bash
# ============================================================
# vertil-inner.sh — Script interno de Vertil OS
# CAPA: Debian (dentro del entorno proot)
# ============================================================
# REGLA CRITICA: Este script se ejecuta dentro de Debian/proot.
# NO usar variables de Termux ($PREFIX, $TERMUX_VERSION, etc.)
# Todas las variables deben ser definidas localmente.
# ============================================================

# --- Constantes internas (definidas aqui, sin depender de Termux) ---
INNER_DISPLAY=":0"
INNER_RESOLUTION="1280x720x24"
INNER_VNC_PORT="5901"
INNER_LOG_DIR="/root/.vertil/logs"
INNER_PID_FILE="/root/.vertil/pids"
INNER_READY_FLAG="/root/.vertil/ready"

mkdir -p "${INNER_LOG_DIR}"

# --- Funciones de log ---
inner_log() {
    local level="$1"; shift
    local msg="$*"
    local ts
    ts=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${ts}] [${level}] ${msg}" | tee -a "${INNER_LOG_DIR}/inner.log"
}

inner_info()  { inner_log "INFO"  "$@"; }
inner_error() { inner_log "ERROR" "$@"; }

# --- Funcion de limpieza interna ---
inner_cleanup() {
    inner_info "Limpiando procesos internos..."
    if [ -f "${INNER_PID_FILE}" ]; then
        while IFS= read -r entry; do
            local iname
            iname=$(echo "$entry" | cut -d: -f1 | tr -d ' ')
            local ipid
            ipid=$(echo "$entry" | cut -d: -f2 | tr -d ' ')
            if [ -n "${ipid}" ] && kill -0 "${ipid}" 2>/dev/null; then
                inner_info "Deteniendo ${iname} (PID ${ipid})..."
                kill "${ipid}" 2>/dev/null || true
                sleep 0.2
            fi
        done < "${INNER_PID_FILE}"
        rm -f "${INNER_PID_FILE}"
    fi
    rm -f "${INNER_READY_FLAG}"
    inner_info "Limpieza interna completada."
    exit 0
}

# Capturar senales dentro del proot
trap inner_cleanup SIGINT SIGTERM SIGHUP

# Inicializar archivo de PIDs
> "${INNER_PID_FILE}"

# --- Asegurar directorio de sockets X11 ---
mkdir -p /tmp/.X11-unix
chmod 1777 /tmp/.X11-unix 2>/dev/null || true

# --- Asegurar directorio .vnc para x0vncserver ---
mkdir -p /root/.vnc

# ============================================================
# 1. INICIAR Xvfb
# ============================================================
inner_info "Iniciando Xvfb en display ${INNER_DISPLAY} con resolucion ${INNER_RESOLUTION}..."

Xvfb "${INNER_DISPLAY}" \
    -screen 0 "${INNER_RESOLUTION}" \
    -ac \
    +extension GLX \
    +extension RENDER \
    -noreset \
    >> "${INNER_LOG_DIR}/xvfb.log" 2>&1 &
XVFB_PID=$!
echo "Xvfb:${XVFB_PID}" >> "${INNER_PID_FILE}"

# Esperar a que Xvfb este listo
sleep 1.5
if ! kill -0 "${XVFB_PID}" 2>/dev/null; then
    inner_error "Xvfb no pudo iniciarse. Ver ${INNER_LOG_DIR}/xvfb.log"
    inner_cleanup
    exit 1
fi
inner_info "Xvfb iniciado (PID ${XVFB_PID})"

# ============================================================
# 2. ESTABLECER DISPLAY
# ============================================================
export DISPLAY="${INNER_DISPLAY}"

# ============================================================
# 3. INICIAR Openbox
# ============================================================
inner_info "Iniciando Openbox..."

openbox \
    >> "${INNER_LOG_DIR}/openbox.log" 2>&1 &
OPENBOX_PID=$!
echo "Openbox:${OPENBOX_PID}" >> "${INNER_PID_FILE}"

sleep 1.5
if ! kill -0 "${OPENBOX_PID}" 2>/dev/null; then
    inner_error "Openbox no pudo iniciarse. Ver ${INNER_LOG_DIR}/openbox.log"
    inner_cleanup
    exit 1
fi
inner_info "Openbox iniciado (PID ${OPENBOX_PID})"

# ============================================================
# 4. INICIAR TINT2 (no critico para Fase 1)
# ============================================================
inner_info "Iniciando Tint2..."

tint2 \
    >> "${INNER_LOG_DIR}/tint2.log" 2>&1 &
TINT2_PID=$!
echo "Tint2:${TINT2_PID}" >> "${INNER_PID_FILE}"

sleep 1
if ! kill -0 "${TINT2_PID}" 2>/dev/null; then
    inner_info "AVISO: Tint2 no pudo iniciarse (no critico para Fase 1)"
else
    inner_info "Tint2 iniciado (PID ${TINT2_PID})"
fi

# ============================================================
# 5. INICIAR SERVIDOR VNC
#    Intenta x0vncserver primero; si falla, usa x11vnc.
# ============================================================
VNC_STARTED=false

# Intento 1: x0vncserver (TigerVNC)
if command -v x0vncserver &>/dev/null; then
    inner_info "Iniciando x0vncserver en puerto ${INNER_VNC_PORT}..."

    x0vncserver \
        -display "${INNER_DISPLAY}" \
        -rfbport "${INNER_VNC_PORT}" \
        -SecurityTypes None \
        >> "${INNER_LOG_DIR}/vnc.log" 2>&1 &
    VNC_PID=$!
    echo "VNC:${VNC_PID}" >> "${INNER_PID_FILE}"

    sleep 2
    if kill -0 "${VNC_PID}" 2>/dev/null; then
        inner_info "x0vncserver iniciado (PID ${VNC_PID})"
        VNC_STARTED=true
    else
        inner_info "x0vncserver fallo, intentando x11vnc como fallback..."
        sed -i "/^VNC:/d" "${INNER_PID_FILE}"
    fi
fi

# Intento 2: x11vnc (fallback universal)
if [ "${VNC_STARTED}" = "false" ] && command -v x11vnc &>/dev/null; then
    inner_info "Iniciando x11vnc en puerto ${INNER_VNC_PORT}..."

    x11vnc \
        -display "${INNER_DISPLAY}" \
        -rfbport "${INNER_VNC_PORT}" \
        -nopw \
        -forever \
        -shared \
        -noxrecord \
        -noxdamage \
        >> "${INNER_LOG_DIR}/vnc.log" 2>&1 &
    VNC_PID=$!
    echo "VNC:${VNC_PID}" >> "${INNER_PID_FILE}"

    sleep 2
    if kill -0 "${VNC_PID}" 2>/dev/null; then
        inner_info "x11vnc iniciado (PID ${VNC_PID})"
        VNC_STARTED=true
    fi
fi

# Verificar que ALGUN servidor VNC arranco
if [ "${VNC_STARTED}" = "false" ]; then
    inner_error "Ningun servidor VNC pudo iniciarse."
    inner_error "Ver ${INNER_LOG_DIR}/vnc.log para detalles."
    inner_cleanup
    exit 1
fi

# ============================================================
# 6. ESCRIBIR FLAG DE LISTO
# ============================================================
date '+%Y-%m-%d %H:%M:%S' > "${INNER_READY_FLAG}"
inner_info "Todos los servicios estan en ejecucion. Flag de listo escrito."

# ============================================================
# 7. MONITOREAR PROCESOS
# ============================================================
inner_info "Monitoreando servicios... (Ctrl+C para detener)"

while true; do
    # Verificar proceso critico: Xvfb
    if ! kill -0 "${XVFB_PID}" 2>/dev/null; then
        inner_error "Xvfb ha muerto inesperadamente. Deteniendo sistema."
        break
    fi
    
    # Auto-reinicio: Openbox
    if ! kill -0 "${OPENBOX_PID}" 2>/dev/null; then
        inner_info "Openbox ha muerto. Reiniciando..."
        openbox >> "${INNER_LOG_DIR}/openbox.log" 2>&1 &
        OPENBOX_PID=$!
        sed -i "s/Openbox:.*/Openbox:${OPENBOX_PID}/" "${INNER_PID_FILE}"
        sleep 1
    fi
    
    # Auto-reinicio: VNC
    if ! kill -0 "${VNC_PID}" 2>/dev/null; then
        inner_info "VNC ha muerto. Reiniciando con x11vnc..."
        if command -v x11vnc &>/dev/null; then
            x11vnc \
                -display "${INNER_DISPLAY}" \
                -rfbport "${INNER_VNC_PORT}" \
                -nopw \
                -forever \
                -shared \
                -noxrecord \
                -noxdamage \
                >> "${INNER_LOG_DIR}/vnc.log" 2>&1 &
            VNC_PID=$!
            sed -i "s/VNC:.*/VNC:${VNC_PID}/" "${INNER_PID_FILE}"
            sleep 1
        else
            inner_error "VNC murio y x11vnc no esta disponible. Deteniendo."
            break
        fi
    fi
    
    # Auto-reinicio: Tint2 (no critico)
    if [ -n "${TINT2_PID:-}" ] && ! kill -0 "${TINT2_PID}" 2>/dev/null; then
        inner_info "Tint2 ha muerto. Reiniciando..."
        tint2 >> "${INNER_LOG_DIR}/tint2.log" 2>&1 &
        TINT2_PID=$!
        sed -i "s/Tint2:.*/Tint2:${TINT2_PID}/" "${INNER_PID_FILE}"
        sleep 1
    fi
    
    sleep 5
done

# Si salimos del bucle, algo murio inesperadamente
inner_error "Saliendo del monitor por fallo critico."
inner_cleanup
INNERSCRIPT

chmod +x "${ROOTFS}${INNER_SCRIPT}"

info "Script interno generado en ${ROOTFS}${INNER_SCRIPT}"

# ============================================================
# INICIAR VERTIL OS
# ============================================================
echo ""
echo -e "${CYAN}  =========================================${NC}"
echo -e "${CYAN}   Iniciando Vertil OS - Fase 1${NC}"
echo -e "${CYAN}  =========================================${NC}"
echo ""
info "Lanzando entorno proot con Debian..."

# Lanzar proot-distro en segundo plano
# --bind comparte el directorio home de Termux dentro del proot
proot-distro login debian \
    --bind "${HOME}":/root/termux-home \
    -- bash "${INNER_SCRIPT}" &
PROOT_PID=$!

info "Sesion proot iniciada (PID ${PROOT_PID})"

# ============================================================
# ESPERAR A QUE EL SISTEMA ESTE LISTO
#    Espera a que el script interno escriba el flag de listo.
#    Lee directamente del rootfs (accesible desde Termux).
# ============================================================
info "Esperando a que los servicios internos se inicien..."

TIMEOUT=45
ELAPSED=0
READY=false

while [ ${ELAPSED} -lt ${TIMEOUT} ]; do
    # Verificar que el proceso proot sigue vivo
    if ! kill -0 "${PROOT_PID}" 2>/dev/null; then
        error "El proceso proot ha muerto prematuramente."
        error "Verifique los logs en ${ROOTFS}/root/.vertil/logs/"
        tail -20 "${ROOTFS}/root/.vertil/logs/inner.log" 2>/dev/null || true
        cleanup
        exit 1
    fi
    
    # Verificar flag de listo
    if [ -f "${ROOTFS}/root/.vertil/ready" ]; then
        READY=true
        break
    fi
    
    sleep 1
    ELAPSED=$((ELAPSED + 1))
    if [ $((ELAPSED % 5)) -eq 0 ]; then
        info "Esperando... (${ELAPSED}s / ${TIMEOUT}s)"
    fi
done

if [ "${READY}" != "true" ]; then
    error "Los servicios internos no se iniciaron dentro del tiempo limite (${TIMEOUT}s)."
    error "Verifique los logs en ${ROOTFS}/root/.vertil/logs/"
    
    # Verificar si el proceso proot sigue vivo
    if kill -0 "${PROOT_PID}" 2>/dev/null; then
        error "El proceso proot sigue vivo pero los servicios no arrancaron."
        error "Ultimas lineas del log interno:"
        tail -20 "${ROOTFS}/root/.vertil/logs/inner.log" 2>/dev/null || true
    fi
    
    cleanup
    exit 1
fi

info "Servicios internos iniciados correctamente."

# ============================================================
# MOSTRAR INFORMACION DE CONEXION
# ============================================================

# Obtener IP local
LOCAL_IP=""
if command -v ip &>/dev/null; then
    LOCAL_IP=$(ip -4 addr show 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | head -1)
fi
if [ -z "${LOCAL_IP}" ] && command -v ifconfig &>/dev/null; then
    LOCAL_IP=$(ifconfig 2>/dev/null | grep 'inet ' | grep -v '127.0.0.1' | head -1 | awk '{print $2}' | sed 's/addr://')
fi
if [ -z "${LOCAL_IP}" ]; then
    LOCAL_IP=$(hostname -I 2>/dev/null | awk '{print $1}')
fi
if [ -z "${LOCAL_IP}" ]; then
    LOCAL_IP="localhost"
fi

echo ""
echo -e "${GREEN}  +------------------------------------------+${NC}"
echo -e "${GREEN}  |  Vertil OS esta en ejecucion             |${NC}"
echo -e "${GREEN}  +------------------------------------------+${NC}"
echo -e "${GREEN}  |                                          |${NC}"
echo -e "${GREEN}  |  VNC Host: ${BOLD}${LOCAL_IP}${NC}                    "
echo -e "${GREEN}  |  VNC Port: ${BOLD}${VNC_PORT}${NC}                    "
echo -e "${GREEN}  |  Display:  ${BOLD}${DISPLAY_NUM}${NC}                    "
echo -e "${GREEN}  |  Resolucion: 1280x720                   |${NC}"
echo -e "${GREEN}  |  Seguridad: Ninguna (Fase 1)            |${NC}"
echo -e "${GREEN}  |                                          |${NC}"
echo -e "${GREEN}  |  Presione ${BOLD}Ctrl+C${NC} para detener            "
echo -e "${GREEN}  +------------------------------------------+${NC}"
echo ""
echo -e "${CYAN}  Conecte su cliente VNC a: ${BOLD}${LOCAL_IP}:${VNC_PORT}${NC}"
echo -e "${CYAN}  (Clientes recomendados: bVNC, RealVNC, MultiVNC)${NC}"
echo ""

# Generar codigo QR si qrencode esta disponible
if command -v qrencode &>/dev/null; then
    echo -e "${YELLOW}  Codigo QR de conexion VNC:${NC}"
    qrencode -t ANSIUTF8 "vnc://${LOCAL_IP}:${VNC_PORT}" 2>/dev/null || true
    echo ""
fi

# ============================================================
# MONITOREO PRINCIPAL - Esperar hasta Ctrl+C
# ============================================================
info "Vertil OS en ejecucion. Presione Ctrl+C para detener."

wait "${PROOT_PID}" 2>/dev/null || true

# Si llegamos aqui, el proceso proot termino por si solo
warn "El proceso proot ha terminado inesperadamente."
warn "Verifique los logs en ${ROOTFS}/root/.vertil/logs/ y ${LOG_DIR}/"
cleanup
VERTILSTART

chmod +x "${HOME}/vertil-start"

echo "       Script vertil-start creado en ${HOME}/vertil-start"

# ============================================================
# 9. INSTALAR QRENCODE EN TERMUX (OPCIONAL)
# ============================================================
echo "[8/8] Verificando qrencode en Termux..."
if ! command -v qrencode &>/dev/null; then
    echo "       Instalando qrencode para generar codigos QR..."
    pkg install -y qrencode 2>/dev/null || echo "       (No se pudo instalar qrencode, es opcional)"
else
    echo "       qrencode ya esta disponible."
fi

# ============================================================
# FINALIZACION
# ============================================================
echo ""
echo -e "\033[0;32m  =========================================\033[0m"
echo -e "\033[0;32m   Vertil OS Fase 1 - Construccion lista\033[0m"
echo -e "\033[0;32m  =========================================\033[0m"
echo ""
echo "  Para iniciar Vertil OS, ejecute DESDE TERMUX:"
echo ""
echo "      ${HOME}/vertil-start"
echo ""
echo "  Luego conecte su cliente VNC a localhost:5901"
echo ""
echo "  Cliente VNC recomendado: bVNC (disponible en F-Droid)"
echo ""
echo "  IMPORTANTE: vertil-start DEBE ejecutarse en Termux,"
echo "  NO dentro de proot-distro login debian."
echo ""
