# Datos del juego

Esta carpeta contiene información que conviene editar sin cambiar la lógica del programa. Aquí se encuentran los diálogos.

Los archivos de texto se leen usando rutas relativas a la raíz del proyecto. Por ejemplo, un diálogo llamado `intro.txt` se carga así:

```lua
local Dialogue = require("src/systems/dialogue")
local intro = Dialogue.new("intro.txt")
print(intro:current_line())
intro:next()
```

Los archivos `.txt` antiguos siguen representando una línea por diálogo. Para decisiones se utilizan archivos `.lua` que devuelven una tabla de nodos:

```lua
return {
  start = "inicio",
  nodes = {
    inicio = {
      speaker = "Guía",
      text = "¿Quieres continuar?",
      choices = {
        {
          text = "Sí",
          next = "final",
          effects = {
            { type = "set_flag", key = "car_sold", value = true },
          },
        },
      },
    },
    final = { text = "La conversación terminó.", ending = true },
  },
}
```

Una opción puede incluir `condition`, `effects` y `next`. `Dialogue` consulta las condiciones y delega las consecuencias en los sistemas independientes de decisiones.
