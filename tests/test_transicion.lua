local love_real = love
local pedidas = {}

love = {
  filesystem = {
    load = function(ruta)
      return loadfile(ruta)
    end,
  },
  graphics = {
    newImage = function(ruta)
      pedidas[#pedidas + 1] = ruta
      error("archivo no disponible")
    end,
  },
}

package.loaded["src/states/transicion"] = nil
local transicion = require("src/states/transicion")
assert(#pedidas == 0, "abrir el juego no carga imagenes de la transicion")

local imprimir = print
print = function() end
transicion:enter({})
print = imprimir

assert(#pedidas == 2, "al entrar pide el jugador y el fondo")
assert(transicion.player == nil and transicion.background == nil, "si una imagen falla sigue sin ella")
assert(transicion.dialogue, "el dialogo se crea aunque falten imagenes")

for _, ruta in ipairs(pedidas) do
  local archivo = io.open(ruta, "rb")
  assert(archivo, "la transicion usa una imagen que no existe: " .. ruta)
  archivo:close()
end

love = love_real
package.loaded["src/states/transicion"] = nil

print("test_transicion: ok")
