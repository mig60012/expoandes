local Economy = require("src/systems/economy")
local Plano = require("src/states/casino/plano")

local love_real = love
local pulsadas = {}
local fuente = {
  getHeight = function()
    return 20
  end,
  getWidth = function()
    return 100
  end,
}
love = {
  graphics = setmetatable({
    newFont = function()
      return fuente
    end,
    newCanvas = function()
      return {}
    end,
    newImage = function()
      error("la prueba no carga imagenes")
    end,
    getDimensions = function()
      return 1600, 900
    end,
    getHeight = function()
      return 900
    end,
  }, {
    __index = function()
      return function() end
    end,
  }),
  math = {
    triangulate = function()
      return {}
    end,
  },
  keyboard = {
    isDown = function(...)
      for _, tecla in ipairs({ ... }) do
        if pulsadas[tecla] then
          return true
        end
      end
      return false
    end,
  },
}

local casino = require("src/states/casino")

local function entrar(dinero)
  casino:leave()
  casino:enter({ economy = Economy.new(dinero), state_machine = { switch = function() end } })
end

local function junto_a(nombre)
  for _, objeto in ipairs(casino.interactuables) do
    if objeto.interaccion == nombre then
      casino.cercano = objeto
    end
  end
end

local function pulsar(...)
  for _, tecla in ipairs({ ... }) do
    casino:keypressed(tecla)
  end
end

local function mensaje()
  return casino.dialogo and casino.dialogo.dialogo:current_line()
end

entrar(30)
for nombre, minimo in pairs({ ruleta = 1, blackjack = 2, poker = 3 }) do
  junto_a(nombre)
  pulsar("z")
  assert(casino.selector, "z junto a " .. nombre .. " abre el selector")
  assert(casino.selector.apuesta.minimo == minimo, nombre .. " tiene su minimo")
  assert(casino.selector.apuesta.monto == minimo, nombre .. " empieza en su minimo")
  assert(casino.selector.apuesta.maximo == 30, "el tope es el dinero del jugador")
  pulsar("x")
  assert(casino.selector == nil and casino.dialogo == nil, "x cierra el selector sin mensaje")
end

junto_a("ruleta")
pulsar("z", "up", "right")
assert(casino.selector.apuesta.monto == 12, "las teclas llegan al selector")
local x, y = casino.jugador.x, casino.jugador.y
pulsadas.right = true
casino:update(0.1)
pulsadas.right = nil
assert(casino.jugador.x == x and casino.jugador.y == y, "con el selector abierto no camina")
pulsar("escape")
assert(casino.selector, "escape no cierra el selector")
pulsar("return")
assert(casino.selector == nil, "confirmar cierra el selector")
assert(mensaje() == "Mesa de ruleta. El juego todavía no está disponible.", "confirmar muestra el aviso de la mesa")
pulsar("z")
assert(casino.dialogo == nil, "z cierra el aviso")

entrar(2)
junto_a("poker")
pulsar("z")
assert(casino.selector == nil, "sin el minimo no abre el selector")
assert(mensaje() == "El mínimo de esta mesa es 3 M y tienes 2 M.", "explica por que no puede sentarse")

entrar(0)
junto_a("ruleta")
pulsar("z")
assert(mensaje() == "El mínimo de esta mesa es 1 M y tienes 0 M.", "sin dinero no se sienta en ninguna mesa")

entrar(30)
junto_a("ruleta")
pulsar("z")
casino:leave()
assert(casino.selector == nil, "al salir del casino no queda el selector abierto")

local function cerca(a, b)
  return math.abs(a - b) < 0.000001
end
local RAPIDEZ = Plano.jugador.velocidad

entrar(30)
junto_a("ruleta")
pulsar("z", "x")
assert(casino.jornada.jugadas == 0, "cancelar no cuenta como jugada")
for _ = 1, 3 do
  pulsar("z", "return", "z")
end
assert(casino.jornada.jugadas == 3, "cada apuesta confirmada cuenta como jugada")
assert(cerca(casino.jugador.velocidad, RAPIDEZ * 0.76), "con 3 jugadas camina al 76 %")
for _ = 1, 3 do
  pulsar("z", "return", "z")
end
assert(casino.jornada.jugadas == 6, "llega a 6 jugadas")
assert(cerca(casino.jugador.velocidad, RAPIDEZ * 0.52), "con 6 jugadas camina al 52 %")
pulsar("z")
assert(casino.selector == nil, "con 6 jugadas no se abre el selector")
assert(mensaje() == "Ya no quedan jugadas por hoy.", "a las 6 jugadas las mesas se cierran")
pulsar("z")
assert(casino.dialogo == nil and casino.jornada.jugadas == 6, "una mesa cerrada no suma jugadas")

entrar(2)
junto_a("poker")
pulsar("z", "z")
assert(casino.jornada.jugadas == 0, "un rechazo no cuenta como jugada")

entrar(30)
assert(casino.jornada.jugadas == 0, "cada entrada al casino empieza un dia nuevo")
assert(casino.jugador.velocidad == RAPIDEZ, "el dia nuevo empieza sin cansancio")

love = love_real
print("test_casino: ok")
