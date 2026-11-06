# ExpoAndes Game

Videojuego desarrollado para ExpoAndes 2026, una feria universitaria de ingeniería sostenible.

El proyecto utiliza [LÖVE](https://love2d.org/) y Lua. La meta es crear una experiencia pequeña, clara y educativa sobre una problemática ambiental.

## Cómo ejecutar el juego

Desde la carpeta raíz del repositorio:

```bash
love .
```

También se puede arrastrar la carpeta del proyecto sobre el ejecutable de LÖVE. Se recomienda utilizar LÖVE 11.5 o una versión compatible.

## Por dónde empezar

Si es tu primera vez en el proyecto, lee estos documentos en orden:

1. [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md): explicación general de la estructura.
2. [`src/README.md`](src/README.md): cómo se conectan los módulos.
3. [`src/states/README.md`](src/states/README.md): cómo crear una pantalla.
4. [`src/systems/README.md`](src/systems/README.md): cómo crear lógica reutilizable.

## Reglas importantes

- `main.lua` solo conecta LÖVE con `Game`; no se debe colocar allí la lógica del juego.
- Cada módulo debe ser local y terminar con `return nombre_del_modulo`.
- Los estados representan pantallas o etapas del juego.
- Los sistemas contienen lógica reutilizable y no deben dibujar directamente.
- Antes de crear una abstracción nueva, busca si ya existe un módulo que resuelva el problema.

## Estado actual

`casa` es el estado inicial y contiene una entidad de jugador de prueba. Los estados `casino`, `transicion` y `animacion` son esqueletos preparados para ser desarrollados cuando se defina el diseño final del juego.
