#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
# vertil-build.sh — Script de instalacion unica para Vertil OS
# Fase 1: BASE VIVA
# Debe ejecutarse dentro de Termux en Android (sin root)
# ============================================================

set -e

# ============================================================
# 1. VERIFICACION DE ENTORNO TERMUX
# ============================================================
if [ -z "$TERMUX_VERSION" ] && [ ! -d "$PREFIX" ]; then
    echo ""
    echo "  ERROR: Este script debe ejecutarse dentro de Termux."
    echo "  No se detecto \$TERMUX_VERSION ni \$PREFIX."
    echo "  Descargue Termux desde F-Droid: https://f-droid.org/packages/com.termux/"
    echo ""
    exit 1
fi

echo ""
echo "  ========================================="
echo "    Vertil OS - Fase 1: Construccion Base"
echo "  ========================================="
echo ""

# ============================================================
# 2. INSTALAR PROOT-DISTRO
# ============================================================
echo "[1/7] Verificando proot-distro..."
if ! command -v proot-distro &>/dev/null; then
    echo "       Instalando proot-distro..."
    pkg install -y proot-distro
else
    echo "       proot-distro ya esta instalado."
fi

# ============================================================
# 3. INSTALAR DEBIAN EN PROOT-DISTRO
# ============================================================
echo "[2/7] Verificando distribucion Debian..."
if proot-distro list 2>/dev/null | grep -q "debian.*installed"; then
    echo "       Debian ya esta instalado en proot-distro."
else
    echo "       Instalando Debian (esto puede tardar varios minutos)..."
    proot-distro install debian
fi

# ============================================================
# 4. DEFINIR RUTA DEL ROOTFS
# ============================================================
ROOTFS="${PREFIX}/var/lib/proot-distro/installed-rootfs/debian"

if [ ! -d "${ROOTFS}" ]; then
    echo "  ERROR: El rootfs de Debian no se encuentra en: ${ROOTFS}"
    echo "  La instalacion de Debian puede haber fallado."
    echo "  Intente ejecutar: proot-distro install debian"
    exit 1
fi

echo "       Rootfs encontrado en: ${ROOTFS}"

# ============================================================
# 5. INSTALAR PAQUETES DENTRO DE DEBIAN
# ============================================================
echo "[3/7] Instalando paquetes dentro de Debian..."
echo "       (Esto puede tardar unos minutos la primera vez)"

proot-distro login debian -- bash -c '
    export DEBIAN_FRONTEND=noninteractive
    apt update -y
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
        psmisc
'

echo "       Paquetes instalados correctamente."

# ============================================================
# 6. CREAR CONFIGURACION DE OPENBOX (rc.xml)
# ============================================================
echo "[4/7] Configurando Openbox..."

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

# ============================================================
# 6b. CREAR MENU DE OPENBOX (menu.xml)
# ============================================================

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
echo "[5/7] Configurando Tint2..."

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
# ============================================================
echo "[6/7] Generando script vertil-start..."

cat > "${HOME}/vertil-start" << 'VERTILSTART'
#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
# vertil-start — Script de lanzamiento de Vertil OS Fase 1
# Se ejecuta desde Termux (fuera del proot)
# Gestiona el entorno proot internamente.
# El usuario nunca debe teclear proot-distro login manualmente.
# ============================================================

set -euo pipefail

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
    stale_procs=$(pgrep -f "Xvfb.*${DISPLAY_NUM}" 2>/dev/null || true)
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

    # 4. Limpiar flag de listo
    rm -f "${READY_FLAG}"

    info "Limpieza completada. Vertil OS detenido."
    exit 0
}

# Capturar senales de terminacion
trap cleanup SIGINT SIGTERM

# ============================================================
# VERIFICAR QUE EL ROOTFS EXISTE
# ============================================================
info "Verificando entorno..."

if [ ! -d "${ROOTFS}" ]; then
    error "No se encontro el rootfs de Debian en: ${ROOTFS}"
    error "Ejecute primero: bash vertil-build.sh"
    exit 1
fi

if [ ! -f "${ROOTFS}/usr/bin/Xvfb" ]; then
    error "Xvfb no encontrado en el rootfs."
    error "Los paquetes pueden no haberse instalado correctamente."
    error "Ejecute nuevamente: bash vertil-build.sh"
    exit 1
fi

info "Rootfs de Debian verificado."

# ============================================================
# LIMPIAR ESTADO ANTERIOR
# ============================================================
rm -f "${READY_FLAG}"
rm -f "${PID_FILE}"

# ============================================================
# GENERAR SCRIPT INTERNO (se ejecuta dentro del proot)
# Este script inicia Xvfb, Openbox, Tint2 y VNC.
# Se genera dinamicamente en cada ejecucion para asegurar
# que los valores de configuracion esten actualizados.
# ============================================================
info "Preparando entorno interno..."

cat > "${ROOTFS}${INNER_SCRIPT}" << 'INNERSCRIPT'
#!/bin/bash
# ============================================================
# vertil-inner.sh — Script interno de Vertil OS
# Se ejecuta dentro del entorno proot/Debian.
# Inicia todos los servicios graficos y los monitorea.
# ============================================================

# --- Constantes internas ---
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
    # No abortamos; el escritorio sigue funcional sin la barra
else
    inner_info "Tint2 iniciado (PID ${TINT2_PID})"
fi

# ============================================================
# 5. INICIAR SERVIDOR VNC
# ============================================================
inner_info "Iniciando servidor VNC (x0vncserver) en puerto ${INNER_VNC_PORT}..."

x0vncserver \
    -display "${INNER_DISPLAY}" \
    -rfbport "${INNER_VNC_PORT}" \
    -SecurityTypes None \
    >> "${INNER_LOG_DIR}/vnc.log" 2>&1 &
VNC_PID=$!
echo "VNC:${VNC_PID}" >> "${INNER_PID_FILE}"

sleep 2
if ! kill -0 "${VNC_PID}" 2>/dev/null; then
    inner_error "x0vncserver no pudo iniciarse. Intentando x11vnc como fallback..."
    
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
    # Actualizar PID en archivo
    sed -i "s/VNC:.*/VNC:${VNC_PID}/" "${INNER_PID_FILE}"
    
    sleep 2
    if ! kill -0 "${VNC_PID}" 2>/dev/null; then
        inner_error "Ni x0vncserver ni x11vnc pudieron iniciarse."
        inner_error "Ver ${INNER_LOG_DIR}/vnc.log para detalles."
        inner_cleanup
        exit 1
    fi
    inner_info "x11vnc iniciado como fallback (PID ${VNC_PID})"
else
    inner_info "x0vncserver iniciado (PID ${VNC_PID})"
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
    # Verificar procesos criticos
    if ! kill -0 "${XVFB_PID}" 2>/dev/null; then
        inner_error "Xvfb ha muerto inesperadamente. Deteniendo sistema."
        break
    fi
    
    if ! kill -0 "${OPENBOX_PID}" 2>/dev/null; then
        inner_error "Openbox ha muerto inesperadamente. Intentando reiniciar..."
        openbox >> "${INNER_LOG_DIR}/openbox.log" 2>&1 &
        OPENBOX_PID=$!
        sed -i "s/Openbox:.*/Openbox:${OPENBOX_PID}/" "${INNER_PID_FILE}"
        sleep 1
    fi
    
    if ! kill -0 "${VNC_PID}" 2>/dev/null; then
        inner_info "VNC ha muerto, intentando reiniciar con x11vnc..."
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
    fi
    
    # Tint2 es no-critico; si muere, intentamos reiniciar
    if [ -n "${TINT2_PID:-}" ] && kill -0 "${TINT2_PID}" 2>/dev/null; then
        : # tint2 sigue corriendo, todo bien
    else
        inner_info "Reiniciando Tint2..."
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
# ============================================================
info "Esperando a que los servicios internos se inicien..."

TIMEOUT=30
ELAPSED=0
READY=false

while [ ${ELAPSED} -lt ${TIMEOUT} ]; do
    if [ -f "${ROOTFS}/root/.vertil/ready" ]; then
        READY=true
        break
    fi
    sleep 1
    ELAPSED=$((ELAPSED + 1))
    # Mostrar progreso cada 5 segundos
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
        error "Intentando mostrar los ultimas lineas del log interno..."
        tail -20 "${ROOTFS}/root/.vertil/logs/inner.log" 2>/dev/null || true
    fi
    
    cleanup
    exit 1
fi

info "Servicios internos iniciados correctamente."

# ============================================================
# MOSTRAR INFORMACION DE CONEXION
# ============================================================

# Intentar obtener la IP local del dispositivo
LOCAL_IP=""
# Metodo 1: comando ip
if command -v ip &>/dev/null; then
    LOCAL_IP=$(ip -4 addr show 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | head -1)
fi
# Metodo 2: ifconfig
if [ -z "${LOCAL_IP}" ] && command -v ifconfig &>/dev/null; then
    LOCAL_IP=$(ifconfig 2>/dev/null | grep 'inet ' | grep -v '127.0.0.1' | head -1 | awk '{print $2}' | sed 's/addr://')
fi
# Metodo 3: hostname
if [ -z "${LOCAL_IP}" ]; then
    LOCAL_IP=$(hostname -I 2>/dev/null | awk '{print $1}')
fi
# Fallback
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

# Esperar al proceso proot. Cuando reciba SIGINT,
# la funcion cleanup() se ejecutara automaticamente.
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
echo "[7/7] Verificando qrencode en Termux..."
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
echo "  Para iniciar Vertil OS, ejecute:"
echo ""
echo "      ${HOME}/vertil-start"
echo ""
echo "  Luego conecte su cliente VNC a localhost:5901"
echo ""
echo "  Cliente VNC recomendado: bVNC (disponible en F-Droid)"
echo ""
