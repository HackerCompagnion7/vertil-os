#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
# vertil-build.sh — Bootstrap de Vertil OS (Fase 1)
# ============================================================
# CAPA: TERMUX (obligatorio)
# PROPOSITO: Instalar Debian + paquetes + configuraciones
# REGLA: Solo se ejecuta en Termux. Aborta si detecta Debian.
# VALIDACION: Debian instalado via proot-distro (multiples metodos)
# ============================================================

set -eo pipefail

# ============================================================
# 1. VERIFICACION DE ENTORNO — TERMUX OBLIGATORIO
# ============================================================

if [ -z "${TERMUX_VERSION:-}" ]; then
    echo ""
    echo "  ERROR: No se detecto \$TERMUX_VERSION."
    echo "  Este script SOLO se ejecuta en Termux."
    echo ""
    echo "  Si estas dentro de Debian, sal con: exit"
    echo "  Luego ejecuta desde Termux: bash vertil-build.sh"
    echo ""
    exit 1
fi

PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
HOME="${HOME:-/data/data/com.termux/files/home}"

echo ""
echo "  ========================================="
echo "    Vertil OS - Fase 1: Bootstrap"
echo "  ========================================="
echo ""
echo "  Entorno: Termux (verificado)"
echo ""

# ============================================================
# 2. FUNCION: Verificar si Debian esta instalado
#    Estrategia multi-metodo para manejar TODOS los formatos
#    conocidos de `proot-distro list`:
#
#    Formato A: "  debian [installed]" en la misma linea
#    Formato B: Seccion "Installed distributions:" + "debian" aparte
#    Formato C: "  debian (12) [installed]" con version
#    Formato D: Cualquier otro formato (fallback a login)
# ============================================================

debian_is_installed() {
    local output

    # Capturar salida de proot-distro list (stdout + stderr)
    output=$(proot-distro list 2>&1) || true

    # Eliminar codigos ANSI (colores de terminal)
    output=$(printf '%s' "$output" | sed 's/\x1b\[[0-9;]*[a-zA-Z]//g')

    # Guardar output para debug (visible si la validacion falla)
    printf '%s\n' "$output" > "${HOME}/.vertil-debug-proot-list.txt" 2>/dev/null || true

    # --- Metodo 1: "debian" con "[installed]" o "installed" en la misma linea ---
    # Formato: "  debian [installed]" o "  debian (12) [installed]"
    if printf '%s\n' "$output" | grep -i "debian" | grep -qi "install"; then
        return 0
    fi

    # --- Metodo 2: Contar cuantas veces aparece "debian" ---
    # Si esta instalado, aparece en "Supported" Y en "Installed" → 2+ veces
    # Si NO esta instalado, solo aparece en "Supported" → 1 vez
    local count
    count=$(printf '%s\n' "$output" | grep -ci "debian" 2>/dev/null || true)
    count=$(echo "$count" | tr -cd '0-9')
    if [ "${count:-0}" -ge 2 ]; then
        return 0
    fi

    # --- Metodo 3: Seccion "Installed distributions:" con "debian" debajo ---
    # Usar awk: busca la linea "Installed" y luego "debian" despues
    if printf '%s\n' "$output" | awk '
        /[Ii]nstalled.*:/ { in_installed=1; next }
        /^[A-Z]/ { in_installed=0 }
        in_installed && /debian/ { exit 0 }
        END { exit 1 }
    ' 2>/dev/null; then
        return 0
    fi

    # --- Metodo 4: Login test (DEFINITIVO - si puedes entrar, esta instalado) ---
    # Este es el test mas confiable que existe
    if proot-distro login debian -- true 2>/dev/null; then
        return 0
    fi

    return 1
}

# ============================================================
# 3. INSTALAR PROOT-DISTRO
# ============================================================
echo "[1/6] Verificando proot-distro..."

if ! command -v proot-distro &>/dev/null; then
    echo "       Instalando proot-distro..."
    pkg install -y proot-distro
fi

if ! command -v proot-distro &>/dev/null; then
    echo "  ERROR: proot-distro no se pudo instalar."
    exit 1
fi

echo "       proot-distro disponible."

# ============================================================
# 4. VERIFICAR/INSTALAR DEBIAN
#    VALIDACION con debian_is_installed() (multiples metodos)
#    "container already exists" NO es error.
# ============================================================
echo "[2/6] Verificando Debian..."

if debian_is_installed; then
    echo "       Debian ya esta instalado. (OK)"
else
    echo "       Instalando Debian (puede tardar varios minutos)..."

    # Ejecutar instalacion - "container already exists" no es error
    proot-distro install debian || {
        if debian_is_installed; then
            echo "       Debian ya existia (no es error). Continuando..."
        else
            echo ""
            echo "  ERROR: La instalacion de Debian fallo."
            echo "  Intenta manualmente: proot-distro install debian"
            echo ""
            exit 1
        fi
    }

    # Verificacion post-instalacion
    if debian_is_installed; then
        echo "       Debian instalado correctamente."
    else
        echo ""
        echo "  ERROR: Debian se instalo pero la validacion falla."
        echo "  Esto puede ser un bug en el formato de proot-distro list."
        echo ""
        echo "  DEBUG: Salida de proot-distro list:"
        cat "${HOME}/.vertil-debug-proot-list.txt" 2>/dev/null || echo "  (no se pudo leer el archivo de debug)"
        echo ""
        echo "  Intenta manualmente:"
        echo "    proot-distro list"
        echo "    proot-distro login debian -- echo ok"
        echo ""
        exit 1
    fi
fi

# ============================================================
# 5. INSTALAR PAQUETES DENTRO DE DEBIAN
# ============================================================
echo "[3/6] Instalando paquetes en Debian..."
echo "       (Esto puede tardar la primera vez)"

proot-distro login debian -- bash -c '
    export DEBIAN_FRONTEND=noninteractive

    apt update -y

    apt install -y \
        xvfb \
        openbox \
        tigervnc-standalone-server \
        x11vnc \
        x11-utils \
        xfonts-base \
        tint2 \
        xterm \
        qrencode \
        adwaita-icon-theme \
        dbus \
        procps \
        psmisc
'

# Verificar que los paquetes criticos se instalaron
echo "       Verificando paquetes instalados..."

PKG_CHECK=$(proot-distro login debian -- bash -c '
    MISSING=""
    for cmd in Xvfb openbox xterm x11vnc tint2; do
        if ! command -v "$cmd" &>/dev/null; then
            MISSING="$MISSING $cmd"
        fi
    done
    if [ -n "$MISSING" ]; then
        echo "MISSING:$MISSING"
    else
        echo "OK"
    fi
')

if echo "${PKG_CHECK}" | grep -q "^MISSING:"; then
    MISSING_PKGS=$(echo "${PKG_CHECK}" | sed 's/^MISSING://')
    echo "  AVISO: Algunos paquetes no se encontraron en PATH:${MISSING_PKGS}"
    echo "  Los binarios pueden estar en ubicaciones no estandar."
else
    echo "       Paquetes verificados correctamente."
fi

# ============================================================
# 6. INSTALAR CONFIGURACIONES DENTRO DE DEBIAN
# ============================================================
echo "[4/6] Instalando configuraciones..."

proot-distro login debian -- bash -c '
    # --- Openbox rc.xml ---
    mkdir -p /root/.config/openbox

    cat > /root/.config/openbox/rc.xml << '"'"'OPENBOXRC'"'"'
<?xml version="1.0" encoding="UTF-8"?>
<openbox_config xmlns="http://openbox.org/3.4/rc">
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
    <font place="ActiveWindow"><name>sans</name><size>10</size><weight>Bold</weight><slant>Normal</slant></font>
    <font place="InactiveWindow"><name>sans</name><size>10</size><weight>Normal</weight><slant>Normal</slant></font>
    <font place="MenuHeader"><name>sans</name><size>10</size><weight>Normal</weight><slant>Normal</slant></font>
    <font place="MenuItem"><name>sans</name><size>10</size><weight>Normal</weight><slant>Normal</slant></font>
    <font place="OnScreenDisplay"><name>sans</name><size>10</size><weight>Bold</weight><slant>Normal</slant></font>
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
    <keybind key="A-F4">
      <action name="Close"/>
    </keybind>
  </keyboard>
  <mouse>
    <doubleClickTime>400</doubleClickTime>
    <context name="Frame">
      <mousebind button="A-Left" action="Press"><action name="Focus"/><action name="Raise"/></mousebind>
      <mousebind button="A-Left" action="Drag"><action name="Move"/></mousebind>
      <mousebind button="A-Right" action="Drag"><action name="Resize"/></mousebind>
    </context>
    <context name="Titlebar">
      <mousebind button="Left" action="Press"><action name="Focus"/><action name="Raise"/></mousebind>
      <mousebind button="Left" action="Drag"><action name="Move"/></mousebind>
    </context>
    <context name="Desktop">
      <mousebind button="Right" action="Press"><action name="ShowMenu"><menu>root-menu</menu></action></mousebind>
      <mousebind button="Left" action="Press"><action name="Focus"/><action name="Raise"/></mousebind>
    </context>
    <context name="Client">
      <mousebind button="Left" action="Press"><action name="Focus"/><action name="Raise"/></mousebind>
    </context>
    <context name="Root">
      <mousebind button="Right" action="Press"><action name="ShowMenu"><menu>root-menu</menu></action></mousebind>
    </context>
  </mouse>
  <menu><file>menu.xml</file></menu>
  <applications></applications>
</openbox_config>
OPENBOXRC

    # --- Openbox menu.xml ---
    cat > /root/.config/openbox/menu.xml << '"'"'OPENBOXMENU'"'"'
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

    # --- Tint2 tint2rc ---
    mkdir -p /root/.config/tint2

    cat > /root/.config/tint2/tint2rc << '"'"'TINT2RC'"'"'
#-------------------------------------
# Tint2 config - Vertil OS Fase 1
#-------------------------------------
panel_items = LC
panel_monitor = all
panel_position = bottom center horizontal
panel_size = 100% 28
panel_margin = 0 0
panel_padding = 4 0 4
panel_background_id = 1
panel_layer = top
strut_policy = follow_size

rounded = 0
border_width = 0
background_color = #1a1a1a 100
border_color = #000000 0
background_id = 1

rounded = 0
border_width = 0
background_color = #1a1a1a 100
border_color = #000000 0

launcher_padding = 4 2 4
launcher_background_id = 0
launcher_icon_size = 20
launcher_item_app = /usr/share/applications/vertil-menu.desktop

taskbar_mode = single_desktop
taskbar_padding = 0 0 0
taskbar_background_id = 0
taskbar_active_background_id = 0
taskbar_name = 0
taskbar_name_padding = 0 0

task_text = 0
task_icon = 0

systray_padding = 0 0 0
systray_background_id = 0

time1_format = %H:%M
time1_font = sans bold 10
clock_font_color = #cccccc 100
clock_padding = 8 2
clock_background_id = 0
clock_tooltip_format = %A %d de %B de %Y - %H:%M

tooltip_padding = 4 4
tooltip_show_timeout = 0.5
tooltip_hide_timeout = 0.3
tooltip_background_id = 1
tooltip_font_color = #cccccc 100
tooltip_font = sans 9

battery = 0

mouse_middle = none
mouse_right = close
mouse_scroll_up = none
mouse_scroll_down = none
TINT2RC

    # --- .desktop para boton de menu ---
    mkdir -p /usr/share/applications

    cat > /usr/share/applications/vertil-menu.desktop << '"'"'DESKTOPMENU'"'"'
[Desktop Entry]
Name=Menu
Comment=Vertil OS - Menu (Fase 1)
Exec=echo "Menu no disponible en Fase 1"
Icon=utilities-terminal
Type=Application
Categories=System;
DESKTOPMENU

    echo "CONFIGS_INSTALADAS=1"
'

# Verificar que las configs se instalaron
CONFIG_CHECK=$(proot-distro login debian -- bash -c '
    OK=true
    [ -f /root/.config/openbox/rc.xml ] || OK=false
    [ -f /root/.config/openbox/menu.xml ] || OK=false
    [ -f /root/.config/tint2/tint2rc ] || OK=false
    [ -f /usr/share/applications/vertil-menu.desktop ] || OK=false
    if $OK; then echo "OK"; else echo "FAIL"; fi
')

if [ "${CONFIG_CHECK}" = "OK" ]; then
    echo "       Configuraciones instaladas y verificadas."
else
    echo "  AVISO: Algunas configuraciones pueden no haberse instalado."
    echo "  El sistema intentara funcionar con defaults si es necesario."
fi

# ============================================================
# 7. INSTALAR QRENCODE EN TERMUX (OPCIONAL)
# ============================================================
echo "[5/6] Verificando qrencode en Termux..."
if ! command -v qrencode &>/dev/null; then
    pkg install -y qrencode 2>/dev/null || echo "       (qrencode no disponible, es opcional)"
else
    echo "       qrencode disponible."
fi

# ============================================================
# 8. FINALIZACION
# ============================================================
echo "[6/6] Verificacion final..."

if ! debian_is_installed; then
    echo "  ERROR: Debian no aparece como instalado. Algo salio mal."
    echo ""
    echo "  DEBUG: Salida de proot-distro list:"
    cat "${HOME}/.vertil-debug-proot-list.txt" 2>/dev/null || echo "  (no disponible)"
    echo ""
    exit 1
fi

echo ""
echo -e "\033[0;32m  =========================================\033[0m"
echo -e "\033[0;32m   Vertil OS Fase 1 - Bootstrap completo\033[0m"
echo -e "\033[0;32m  =========================================\033[0m"
echo ""
echo "  Proximos pasos:"
echo ""
echo "  1. Entra a Debian:"
echo "     proot-distro login debian --bind ~/vertil-os:/root/vertil-os"
echo ""
echo "  2. Dentro de Debian, ejecuta:"
echo "     cd /root/vertil-os"
echo "     chmod +x vertil-start"
echo "     ./vertil-start"
echo ""
echo "  3. Conecta tu cliente VNC a localhost:5901"
echo ""
echo "  Alternativa rapida desde Termux:"
echo "     ./vertil"
echo ""
