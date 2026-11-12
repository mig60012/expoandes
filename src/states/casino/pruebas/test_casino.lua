local Economy = require("src/systems/economy")
local Progress = require("src/systems/progress")
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
    getWidth = function()
      return 1600
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

local cambios = {}
local progreso, contexto

local function entrar(dinero)
  casino:leave()
  progreso = Progress.new({ values = { casino_games_today = 4, casino_wins = 0 } })
  contexto = {
    economy = Economy.new(dinero),
    progress = progreso,
    time_of_day = 0,
    state_machine = {
      switch = function(_, nombre)
        cambios[#cambios + 1] = nombre
      end,
    },
  }
  casino:enter(contexto)
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

local function historial()
  return table.concat(casino.historial, ", ")
end

entrar(30)
junto_a("ruleta")
pulsar("z", "x", "z", "up", "return", "z")
assert(historial() == "entrar, sentarse ruleta, cancelar ruleta, sentarse ruleta, apuesta ruleta 2", "anota sentarse, cancelar y apostar: " .. historial())

entrar(2)
junto_a("poker")
pulsar("z", "z")
assert(historial() == "entrar, rechazo poker", "anota el rechazo: " .. historial())

entrar(30)
junto_a("blackjack")
for _ = 1, 6 do
  pulsar("z", "return", "z")
end
pulsar("z", "z")
assert(#casino.historial == 14, "cada jugada anota sentarse y apuesta")
assert(casino.historial[14] == "mesa_cerrada blackjack", "anota la mesa cerrada")

casino.jugador.x, casino.jugador.y = 1925, 810
casino:update(0)
assert(mensaje() == "¿Quieres salir del casino?", "pisar la puerta pregunta si salir")
pulsar("return")
assert(casino.historial[15] == "salir", "anota la salida")
assert(cambios[#cambios] == "transicion", "al salir pasa a la transicion")

casino:leave()
assert(casino.historial == nil, "al salir del casino se libera el historial")

local movimientos
local function espiar_dinero()
  movimientos = {}
  local economia = casino.context.economy
  local gastar, sumar = economia.spend_money, economia.add_money
  function economia.spend_money(e, n)
    movimientos[#movimientos + 1] = "cobra " .. n
    return gastar(e, n)
  end
  function economia.add_money(e, n)
    movimientos[#movimientos + 1] = "devuelve " .. n
    return sumar(e, n)
  end
end

entrar(30)
espiar_dinero()
junto_a("ruleta")
pulsar("z", "x")
assert(#movimientos == 0, "cancelar no mueve dinero")
pulsar("z", "up", "up", "return")
assert(table.concat(movimientos, ", ") == "cobra 3, devuelve 3", "la mesa cobra la apuesta y el empate la devuelve: " .. table.concat(movimientos, ", "))
assert(casino.context.economy:get_money() == 30, "con el empate el dinero queda igual")

entrar(5)
espiar_dinero()
junto_a("poker")
pulsar("z", "right", "return")
assert(table.concat(movimientos, ", ") == "cobra 5, devuelve 5", "puede apostar todo su dinero: " .. table.concat(movimientos, ", "))
assert(casino.context.economy:get_money() == 5, "apostar todo con empate deja el mismo dinero")

entrar(2)
espiar_dinero()
junto_a("poker")
pulsar("z")
assert(#movimientos == 0, "un rechazo no mueve dinero")

local function jugadas_guardadas()
  return progreso:get_value("casino_games_today")
end

entrar(30)
assert(jugadas_guardadas() == 0, "al entrar las jugadas del dia guardadas vuelven a 0")
junto_a("ruleta")
pulsar("z", "x")
assert(jugadas_guardadas() == 0, "cancelar no se guarda como jugada")
pulsar("z", "return", "z")
assert(jugadas_guardadas() == 1, "cada apuesta confirmada se guarda en el progreso")
for _ = 1, 5 do
  pulsar("z", "return", "z")
end
assert(jugadas_guardadas() == 6, "el progreso llega a 6 jugadas")
pulsar("z", "z")
assert(jugadas_guardadas() == 6, "una mesa cerrada no suma al progreso")
assert(progreso:get_value("casino_wins") == 0, "con el empate no hay victorias")

entrar(2)
junto_a("poker")
pulsar("z", "z")
assert(jugadas_guardadas() == 0, "un rechazo no se guarda como jugada")

local function salir_por_la_puerta()
  casino.jugador.x, casino.jugador.y = 1925, 810
  casino:update(0)
  pulsar("return")
  return contexto.time_of_day
end

local function jugar_veces(n)
  junto_a("ruleta")
  for _ = 1, n do
    pulsar("z", "return", "z")
  end
end

entrar(30)
assert(salir_por_la_puerta() == 1, "sin jugar sale de tarde")
assert(cambios[#cambios] == "transicion", "y pasa a la transicion")

entrar(30)
jugar_veces(5)
assert(salir_por_la_puerta() == 1, "con 5 jugadas sale de tarde")

entrar(30)
jugar_veces(6)
assert(salir_por_la_puerta() == 2, "con 6 jugadas sale de noche")

entrar(30)
casino.jugador.x, casino.jugador.y = 1925, 810
casino:update(0)
pulsar("down", "return")
assert(contexto.time_of_day == 0 and casino.dialogo == nil, "responder No no cambia la hora")

local impresos
love.graphics.print = function(texto)
  impresos[texto] = true
end
local function en_pantalla(...)
  impresos = {}
  casino:draw()
  for _, texto in ipairs({ ... }) do
    if not impresos[texto] then
      return false
    end
  end
  return true
end

entrar(30)
assert(en_pantalla("Dinero: 30 M", "Jugadas: 0 de 6"), "al entrar se ve el dinero y las jugadas")
junto_a("ruleta")
pulsar("z", "up")
assert(en_pantalla("Dinero: 30 M", "Jugadas: 0 de 6", "Ruleta"), "con el selector abierto sigue a la vista")
pulsar("return", "z")
assert(en_pantalla("Dinero: 30 M", "Jugadas: 1 de 6"), "cada apuesta confirmada sube las jugadas en pantalla")
contexto.economy:spend_money(5)
assert(en_pantalla("Dinero: 25 M"), "muestra el dinero actual del juego")

love = love_real
print("test_casino: ok")
