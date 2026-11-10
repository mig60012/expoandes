local Apuesta = require("src/states/casino/apuesta")
local VistaApuesta = require("src/states/casino/vista_apuesta")

local confirmado, cancelado

local function nueva()
  confirmado, cancelado = nil, nil
  local apuesta = Apuesta.new({
    minimo = 2,
    dinero = 50,
    al_confirmar = function(monto)
      confirmado = monto
    end,
    al_cancelar = function()
      cancelado = true
    end,
  })
  return VistaApuesta.new({ apuesta = apuesta, salto_chico = 1, salto_grande = 10 }), apuesta
end

local function pulsar(vista, teclas)
  for _, tecla in ipairs(teclas) do
    vista:keypressed(tecla)
  end
end

local vista, apuesta = nueva()
pulsar(vista, { "up", "w" })
assert(apuesta.monto == 4, "arriba y w suben el salto chico")
pulsar(vista, { "down", "s" })
assert(apuesta.monto == 2, "abajo y s bajan el salto chico")
pulsar(vista, { "right", "d" })
assert(apuesta.monto == 22, "derecha y d suben el salto grande")
pulsar(vista, { "left", "a" })
assert(apuesta.monto == 2, "izquierda y a bajan el salto grande")

vista:keypressed("space")
assert(apuesta.monto == 2 and confirmado == nil and not cancelado, "otra tecla no hace nada")

for _, tecla in ipairs({ "z", "return" }) do
  vista, apuesta = nueva()
  vista:keypressed("up")
  vista:keypressed(tecla)
  assert(confirmado == 3 and not cancelado, tecla .. " confirma el monto elegido")
end

for _, tecla in ipairs({ "x", "backspace" }) do
  vista, apuesta = nueva()
  vista:keypressed(tecla)
  assert(cancelado and confirmado == nil, tecla .. " cancela la apuesta")
end

vista, apuesta = nueva()
vista:keypressed("escape")
assert(not cancelado, "escape queda libre para la pausa")

local impresos = {}
local love_real = love
love = {
  graphics = setmetatable({
    print = function(texto)
      impresos[#impresos + 1] = texto
    end,
  }, {
    __index = function()
      return function() end
    end,
  }),
}

apuesta = Apuesta.new({ minimo = 2, dinero = 50 })
vista = VistaApuesta.new({
  apuesta = apuesta,
  salto_chico = 1,
  salto_grande = 10,
  titulo = "Mesa",
  renglones = function(actual)
    return { "Apuesta " .. actual.monto, "Tope " .. actual.maximo }
  end,
})
vista:keypressed("up")
vista:draw(1600, 900, {
  getHeight = function()
    return 30
  end,
})
love = love_real

assert(impresos[1] == "Mesa", "dibuja el titulo que recibe")
assert(impresos[2] == "Apuesta 3", "dibuja el monto actual de la apuesta")
assert(impresos[3] == "Tope 50", "dibuja cada renglon que recibe")
assert(#impresos == 3, "no dibuja textos propios")

print("test_vista_apuesta: ok")
