local Dialogue = require("src/systems/dialogue")
local VistaDialogo = require("src/states/casino/dialogue")

local terminado, elegida
local function al_terminar(opcion)
  terminado, elegida = true, opcion
end

local vista = VistaDialogo.new(Dialogue.new({
  start = "a",
  nodes = { a = { speaker = "Dueno", text = "Hola", ending = true } },
}, {}), al_terminar)

vista:keypressed("x")
assert(not terminado, "otra tecla no cierra el mensaje")
vista:keypressed("z")
assert(terminado and elegida == nil, "z cierra un mensaje sin opciones")

terminado, elegida = nil, nil
vista = VistaDialogo.new(Dialogue.new({
  start = "a",
  nodes = { a = { text = "Salir?", choices = { { text = "Si", salir = true }, { text = "No" } } } },
}, {}), al_terminar)

vista:keypressed("up")
assert(vista.opcion == 1, "no sube de la primera opcion")
vista:keypressed("s")
assert(vista.opcion == 2, "s baja a la segunda opcion")
vista:keypressed("down")
assert(vista.opcion == 2, "no baja de la ultima opcion")
vista:keypressed("w")
assert(vista.opcion == 1, "w sube a la primera opcion")
vista:keypressed("return")
assert(terminado and elegida.salir == true, "enter elige la opcion marcada")

terminado, elegida = nil, nil
vista = VistaDialogo.new(Dialogue.new({
  start = "a",
  nodes = {
    a = { text = "Uno", next = "b" },
    b = { text = "Dos", ending = true },
  },
}, {}), al_terminar)

vista:keypressed("z")
assert(not terminado and vista.dialogo:current_line() == "Dos", "avanza al siguiente nodo")
vista:keypressed("z")
assert(terminado, "termina en el ultimo nodo")

print("test_dialogo: ok")
