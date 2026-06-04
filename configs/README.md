# Archivos de configuración de Vertil OS — Fase 1

Estos archivos son copias de referencia. Las configuraciones reales se embeben
dentro de `vertil-build.sh` y se instalan automáticamente al ejecutarlo.

## Archivos

| Archivo | Destino en el rootfs | Descripción |
|---------|---------------------|-------------|
| `openbox-rc.xml` | `/root/.config/openbox/rc.xml` | Configuración de Openbox: bordes, atajos, mouse bindings |
| `openbox-menu.xml` | `/root/.config/openbox/menu.xml` | Menú contextual: Terminal y Reiniciar Openbox |
| `tint2rc` | `/root/.config/tint2/tint2rc` | Barra de tareas: color, reloj, botón de menú |

## Modificación

Si deseas personalizar la configuración:

1. Edita los archivos en este directorío
2. Copia los valores modificados a los heredocs correspondientes en `vertil-build.sh`
3. Ejecuta `bash vertil-build.sh` para reinstalar

En fases futuras, los archivos de configuración se gestionarán de forma separada.
