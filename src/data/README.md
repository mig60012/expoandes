# Datos del juego

Esta carpeta contiene información que conviene editar sin cambiar la lógica del programa. Aquí se encuentran los diálogos.

Los archivos de texto se leen usando rutas relativas a la raíz del proyecto. Por ejemplo, un diálogo llamado `intro.txt` se carga así:

```lua
local Dialogue = require("src/systems/dialogue")
local intro = Dialogue.new("intro.txt")
print(intro:current_line())
intro:next()
```

Una línea del archivo representa una línea de diálogo. Si en el futuro se necesitan personajes, decisiones o efectos, primero hay que acordar un formato simple y documentarlo antes de cambiar el lector.
