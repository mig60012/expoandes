# Diálogos de `transicion`

`dialogue.lua` es la capa específica de la pantalla `transicion`. No decide la
historia: usa `src/systems/dialogue.lua` para esa tarea y se ocupa únicamente
de cómo se interactúa y cómo se dibuja la conversación en esta pantalla.

## Responsabilidades

- Crear la instancia del diálogo que necesita `transicion`.
- Activar y cerrar la interfaz de conversación.
- Mover la selección entre opciones.
- Interpretar `space`, `return`, `up`, `down`, `w` y `s`.
- Dibujar el panel, el personaje, el texto y las opciones.

## Reutilizar la lógica en otro estado

Otro estado no debería importar este módulo si necesita una apariencia distinta.
Debe crear su propio adaptador, por ejemplo:

```text
src/states/casa/dialogue.lua
src/states/casino/dialogue.lua
```

Esos módulos pueden reutilizar `src/systems/dialogue.lua` y tener diferentes
colores, controles, posiciones, fuentes o animaciones.

La comunicación recomendada es:

```text
estado
  └── adaptador visual del diálogo
        └── sistema narrativo Dialogue
              ├── Conditions
              └── Effects
```

`transicion.lua` solo crea el adaptador y delega sus callbacks. La misma regla
debería aplicarse al implementar diálogos en otros estados.
