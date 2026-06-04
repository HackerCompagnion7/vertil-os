# Vertil OS — Hoja de Ruta

## Fase 1: BASE VIVA ✅ (Actual)

**Objetivo:** Sistema mínimo que arranque y muestre un escritorio en VNC.

**Componentes:**
- Termux + proot-distro (Debian 12)
- Xvfb (display virtual X11)
- Openbox (gestor de ventanas)
- Tint2 (barra de tareas básica)
- TigerVNC / x11vnc (servidor VNC)

**Resultado:** Escritorio vacío visible en VNC con cursor funcional, barra con reloj y menú contextual.

---

## Fase 2: IDENTIDAD VISUAL 🔜

**Objetivo:** Añadir identidad visual coherente al escritorio.

**Componentes:**
- Logo y wallpaper estático mediante `feh`
- Paleta de colores oficial: fondo `#0D1117`, acento `#00FF88`
- Tipografía `Fira Code` (o monospace alternativa)
- `rofi` como menú de aplicaciones vinculado al botón de Tint2
- Tema oscuro para Openbox: bordes con acento `#00FF88`, botones minimalistas

**Resultado:** Escritorio con identidad visual coherente, sin protecciones aún.

---

## Fase 3: BOOT ANIMADO 🔜

**Objetivo:** Pantalla de carga con progreso real sincronizado a hitos del sistema.

**Hitos verificables:**
1. Proot montado y rootfs accesible
2. Servidor X iniciado
3. Openbox cargado
4. VNC principal listo
5. Transición al escritorio real

**Componentes:**
- Servidor VNC temporal (Xvfb + x11vnc) para pantalla de carga
- `boot-animator`: gestiona la pantalla temporal
- `boot-milestones`: comunica el estado de cada hito
- Modificación de `vertil-start` para orquestar el flujo

**Prohibido:** Barras de progreso que avancen por tiempo fijo sin reflejar eventos reales.

**Resultado:** Experiencia de arranque profesional con retroalimentación visual real.

---

## Fase 4: ECOSISTEMA .VERTIL 🔜

**Objetivo:** Sistema de paquetes propio con instalación gráfica.

**Formato `.vertil`:**
```
paquete.vertil (tar.gz)
├── manifest.json    — nombre, versión, autor, dependencias, script de entrada
├── install.sh       — script de instalación
└── assets/          — recursos del paquete
```

**Componentes:**
- Instalador gráfico con `yad` (o `zenity` como fallback)
- `vertil-watcher`: demonio que monitorea `~/Downloads` para archivos `.vertil`
- Comando CLI `vertil`: `install`, `remove`, `list`

**Resultado:** El usuario puede descargar un `.vertil` y el sistema lo detecta e instala gráficamente.

---

## Fase 5: PROTECCIÓN Y MARCA DE AGUA 🔜

**Objetivo:** Sistema resiliente y auto-regenerativo.

**Principio:** En proot sin root no hay protección absoluta. Se implementa resiliencia que hace la manipulación incómoda y fácilmente reversible.

**Componentes:**
- `vertil-watermark`: verifica cada 2s si el wallpaper es el oficial; lo restaura con `feh` si fue modificado
- `vertil-guardian`: watchdog que supervisa procesos críticos y los reinicia si mueren
- Wrappers `vertil-feh` / `vertil-nitrogen`: redirigen al wallpaper oficial y loguean intentos de cambio
- Widget `conky` con logo Vertil fijo en el escritorio

**Lenguaje correcto:** El sistema es "resiliente y auto-regenerativo", NO "irrompible" ni "irremovible".

**Resultado:** Escritorio protegido con marca de agua persistente y mecanismos de auto-regeneración.
