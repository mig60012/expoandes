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
local progreso, contexto, abiertas

local function mesa_de_prueba(nombre)
  return {
    enter = function(_, _, maquina, opciones)
      abiertas[#abiertas + 1] = { nombre = nombre, maquina = maquina, opciones = opciones }
    end,
  }
end

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
  abiertas = {}
  casino.sub_estado.states = {
    ruleta = mesa_de_prueba("ruleta"),
    blackjack = mesa_de_prueba("blackjack"),
    poker = mesa_de_prueba("poker"),
  }
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

local function mesa()
  return abiertas[#abiertas]
end

local function levantarse()
  casino.sub_estado:switch(nil)
end

entrar(30)
for nombre, minimo in pairs({ ruleta = 1, blackjack = 2, poker = 3 }) do
  junto_a(nombre)
  pulsar("z")
  assert(casino.sub_estado.current_name == nombre, "z junto a " .. nombre .. " abre su mesa")
  assert(mesa().opciones.minimo == minimo, nombre .. " recibe su minimo")
  levantarse()
  assert(casino.sub_estado.current == nil, "al levantarse vuelve al salon")
end

entrar(2)
junto_a("poker")
pulsar("z")
assert(casino.sub_estado.current == nil, "sin el minimo no abre la mesa")
assert(mensaje() == "El mínimo de esta mesa es 3 M y tienes 2 M.", "explica por que no puede sentarse")
pulsar("z")
assert(casino.dialogo == nil, "z cierra el aviso")
junto_a("blackjack")
pulsar("z")
assert(casino.sub_estado.current_name == "blackjack", "con 2 M si alcanza para el blackjack")

entrar(0)
junto_a("ruleta")
pulsar("z")
assert(mensaje() == "El mínimo de esta mesa es 1 M y tienes 0 M.", "sin dinero no se sienta en ninguna mesa")
pulsar("z", "f1")
assert(contexto.economy:get_money() == 3, "F1 da 3 M de prueba en el salon")
pulsar("z")
assert(casino.sub_estado.current_name == "ruleta", "con el dinero de prueba ya puede sentarse")

local function cerca(a, b)
  return math.abs(a - b) < 0.000001
end
local RAPIDEZ = Plano.jugador.velocidad

entrar(30)
junto_a("ruleta")
pulsar("z")
local opciones = mesa().opciones
assert(opciones.puede_jugar(), "al empezar el dia se puede jugar")
for _ = 1, 3 do
  opciones.al_jugar(2)
end
assert(casino.jornada.jugadas == 3, "cada apuesta de la mesa cuenta como jugada")
assert(progreso:get_value("casino_games_today") == 3, "las jugadas se guardan en el progreso")
assert(cerca(casino.jugador.velocidad, RAPIDEZ * 0.76), "con 3 jugadas camina al 76 %")
for _ = 1, 3 do
  opciones.al_jugar(1)
end
assert(not opciones.puede_jugar(), "con 6 jugadas la mesa ya no deja apostar")
assert(cerca(casino.jugador.velocidad, RAPIDEZ * 0.52), "con 6 jugadas camina al 52 %")
local x, y = casino.jugador.x, casino.jugador.y
pulsadas.right = true
casino:update(0.1)
pulsadas.right = nil
assert(casino.jugador.x == x and casino.jugador.y == y, "sentado en la mesa no camina")
levantarse()
pulsar("z")
assert(casino.sub_estado.current == nil, "a las 6 jugadas no abre la mesa")
assert(mensaje() == "Ya no quedan jugadas por hoy.", "a las 6 jugadas las mesas se cierran")
pulsar("z")
assert(casino.jornada.jugadas == 6, "una mesa cerrada no suma jugadas")

entrar(2)
junto_a("poker")
pulsar("z", "z")
assert(casino.jornada.jugadas == 0 and progreso:get_value("casino_games_today") == 0, "un rechazo no cuenta como jugada")

entrar(30)
assert(casino.jornada.jugadas == 0 and progreso:get_value("casino_games_today") == 0, "cada entrada al casino empieza un dia nuevo")
assert(casino.jugador.velocidad == RAPIDEZ, "el dia nuevo empieza sin cansancio")

local function historial()
  return table.concat(casino.historial, ", ")
end

entrar(30)
junto_a("ruleta")
pulsar("z")
mesa().opciones.al_jugar(2)
levantarse()
pulsar("f1")
assert(historial() == "entrar, sentarse ruleta, apuesta ruleta 2, dinero_prueba 3", "anota lo que pasa: " .. historial())

entrar(2)
junto_a("poker")
pulsar("z", "z")
assert(historial() == "entrar, rechazo poker", "anota el rechazo: " .. historial())

local function salir_por_la_puerta()
  casino.jugador.x, casino.jugador.y = 1925, 810
  casino:update(0)
  pulsar("return")
  return contexto.time_of_day
end

local function jugar_veces(n)
  junto_a("ruleta")
  pulsar("z")
  for _ = 1, n do
    mesa().opciones.al_jugar(1)
  end
  levantarse()
end

entrar(30)
assert(salir_por_la_puerta() == 1, "sin jugar sale de tarde")
assert(cambios[#cambios] == "transicion", "y pasa a la transicion")
assert(casino.historial[#casino.historial] == "salir", "anota la salida")

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

casino:leave()
assert(casino.historial == nil and casino.jornada == nil, "al salir del casino se libera todo")

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
jugar_veces(1)
contexto.economy:spend_money(2)
assert(en_pantalla("Dinero: 28 M", "Jugadas: 1 de 6"), "muestra el dinero y las jugadas del dia")

love = love_real
print("test_casino: ok")
