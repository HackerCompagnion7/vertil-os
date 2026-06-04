#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
# vertil-build.sh — Bootstrap de Vertil OS (Fase 1)
# ============================================================
# CAPA: TERMUX (obligatorio)
# PROPOSITO: Instalar Debian + paquetes + configuraciones
# REGLA: Solo se ejecuta en Termux. Aborta si detecta Debian.
# VALIDACION: Debian instalado SOLO via `proot-distro list`
# ============================================================

set -eo pipefail

# ============================================================
# 1. VERIFICACION DE ENTORNO — TERMUX OBLIGATORIO
# ============================================================

# Regla: Solo válido si existe $TERMUX_VERSION
if [ -z "${TERMUX_VERSION:-}" ]; then
    echo ""
    echo "  ERROR: No se detecto \$TERMUX_VERSION."
    echo "  Este script SOLO se ejecuta en Termux."
    echo ""
    echo "  Si estas dentro de Debian, sal con:"
    echo "    exit"
    echo ""
    echo "  Luego ejecuta desde Termux:"
    echo "    bash vertil-build.sh"
    echo ""
    exit 1
fi

# Defensivo: defaults para variables que siempre existen en Termux
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
# 2. INSTALAR PROOT-DISTRO
# ============================================================
echo "[1/6] Verificando proot-distro..."

if ! command -v proot-distro &>/dev/null; then
    echo "       Instalando proot-distro..."
    pkg install -y proot-distro
fi

# Validar que realmente se instalo (verificacion con comando real)
if ! command -v proot-distro &>/dev/null; then
    echo "  ERROR: proot-distro no se pudo instalar."
    exit 1
fi

echo "       proot-distro disponible."

# ============================================================
# 3. VERIFICAR/INSTALAR DEBIAN
#    VALIDACION SOLO con `proot-distro list`
#    "container already exists" NO es error.
# ============================================================
echo "[2/6] Verificando Debian..."

DEBIAN_INSTALLED=false

# Metodo UNICO de validacion: proot-distro list
if proot-distro list 2>/dev/null | grep -q "debian"; then
    # Verificar que dice "installed" (no solo disponible)
    if proot-distro list 2>/dev/null | grep -i "debian" | grep -qi "installed"; then
        DEBIAN_INSTALLED=true
    fi
fi

if [ "${DEBIAN_INSTALLED}" = "true" ]; then
    echo "       Debian ya esta instalado. (OK)"
else
    echo "       Instalando Debian (puede tardar varios minutos)..."
    
    # Ejecutar instalacion
    # "container already exists" no es error — se ignora
    proot-distro install debian || {
        # Verificar si fallo realmente o si ya existia
        if proot-distro list 2>/dev/null | grep -i "debian" | grep -qi "installed"; then
            echo "       Debian ya existia (no es error). Continuando..."
        else
            echo "  ERROR: La instalacion de Debian fallo."
            echo "  Intenta manualmente: proot-distro install debian"
            exit 1
        fi
    }
    
    # Verificacion post-instalacion con comando real
    if proot-distro list 2>/dev/null | grep -i "debian" | grep -qi "installed"; then
        echo "       Debian instalado correctamente."
    else
        echo "  ERROR: Debian no aparece como instalado en proot-distro list."
        echo "  Intenta manualmente: proot-distro install debian"
        exit 1
    fi
fi

# ============================================================
# 4. INSTALAR PAQUETES DENTRO DE DEBIAN
#    Solo exit code != 0 es error real.
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
# Usamos proot-distro login para verificar DENTRO de Debian
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
    echo "  AVISO: Algunos paquetes no se encontraron en PATH:${MISS_PKGS}"
    echo "  Los binarios pueden estar en ubicaciones no estandar."
else
    echo "       Paquetes verificados correctamente."
fi

# ============================================================
# 5. INSTALAR CONFIGURACIONES DENTRO DE DEBIAN
#    Se escriben via proot-distro login, NO via rutas directas.
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

# Verificar que las configs se instalaron (verificacion con comando real)
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
# 6. INSTALAR QRENCODE EN TERMUX (OPCIONAL)
# ============================================================
echo "[5/6] Verificando qrencode en Termux..."
if ! command -v qrencode &>/dev/null; then
    pkg install -y qrencode 2>/dev/null || echo "       (qrencode no disponible, es opcional)"
else
    echo "       qrencode disponible."
fi

# ============================================================
# 7. FINALIZACION
# ============================================================
echo "[6/6] Verificacion final..."

# Verificacion final: Debian sigue instalado
if ! proot-distro list 2>/dev/null | grep -i "debian" | grep -qi "installed"; then
    echo "  ERROR: Debian no aparece como instalado. Algo salio mal."
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
echo "     ./vertil-start"
echo ""
echo "  3. Conecta tu cliente VNC a localhost:5901"
echo ""
echo "  Alternativa rapida desde Termux:"
echo "     ./vertil"
echo ""
