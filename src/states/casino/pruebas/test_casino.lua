local Economy = require("src/systems/economy")
local Progress = require("src/systems/progress")
local Plano = require("src/states/casino/plano")

local love_real = love
local pulsadas = {}
local ventana_ancho, ventana_alto = 1600, 900
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
    newImage = function(path)
      if path:find("src/states/casino/assets/", 1, true) then error("sin foto") end
      return { getWidth = function() return 1920 end, getHeight = function() return 1080 end }
    end,
    getDimensions = function()
      return ventana_ancho, ventana_alto
    end,
    getHeight = function()
      return ventana_alto
    end,
    getWidth = function()
      return ventana_ancho
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
    listo_para_salir = function(self) return self.resultado ~= false end,
  }
end

local function entrar(dinero)
  casino:leave()
  progreso = Progress.new({ values = { casino_games_today = 0, casino_wins = 0 } })
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
  assert(contexto.economy:get_money() == 0, "entrar al casino reinicia solo el dinero a cero")
  assert(casino.sub_estado.current == nil, "entrar abre el salon, no blackjack")
  contexto.economy:add_money(dinero)
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
assert(casino.camara.scale == math.max(1600 / Plano.vista.ancho, 900 / Plano.vista.alto),
  "la escala llena la pantalla recortando el salon")
local screen_x, screen_y = casino.camara:cameraCoords(casino.jugador.x, casino.jugador.y)
assert(screen_x > 0 and screen_x < 1600 and screen_y > 0 and screen_y < 900,
  "el jugador permanece visible con la camara ampliada")
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
assert(contexto.economy:get_money() == 0, "main ya no regala dinero con F1 en el salon")
contexto.economy:add_money(3)
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
assert(not opciones.puede_jugar(), "la primera tanda termina a las 3 jugadas")
opciones.al_jugar(1)
assert(casino.jornada.jugadas == 3, "no permite sobrepasar el limite sin aceptar")
casino:update(0)
assert(casino.dialogo and casino.sub_estado.current, "pide levantarse al llegar a tres")
pulsar("return")
assert(not casino.sub_estado.current and casino.dialogo, "ofrece otras tres desde el salon")
assert(contexto.time_of_day == 0, "tres juegos no cambian la hora")
pulsar("return")
assert(contexto.time_of_day == 2 and casino.jornada.maximo == 6, "aceptar activa noche y seis juegos")
junto_a("ruleta")
pulsar("z")
opciones = mesa().opciones
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
pulsar("return")
junto_a("ruleta")
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
assert(casino.jornada.jugadas == 0 and progreso:get_value("casino_games_today") == 0, "una partida nueva empieza sin jugadas")
assert(casino.jugador.velocidad == RAPIDEZ, "el dia nuevo empieza sin cansancio")

-- El contador de ruleta sube al apostar; el tercer resultado debe pagarse antes
-- de mostrar el aviso y congelar la mesa.
junto_a("ruleta")
pulsar("z")
casino.sub_estado.current.resultado = false
for _ = 1, 3 do mesa().opciones.al_jugar(1) end
casino:update(0)
assert(casino.dialogo == nil and casino.sub_estado.current, "espera a que termine el tercer juego")
casino.sub_estado.current.resultado = true
casino:update(0)
assert(casino.dialogo and casino.sub_estado.current, "muestra el aviso al terminar el resultado")
local table_keys = 0
casino.sub_estado.current.keypressed = function() table_keys = table_keys + 1 end
pulsar("escape")
assert(table_keys == 0 and casino.dialogo, "el aviso bloquea las entradas de la mesa")
pulsar("return")
assert(not casino.sub_estado.current and casino.dialogo, "la eleccion se muestra sobre el salon")
pulsar("down", "return")
assert(casino:puede_salir() and contexto.time_of_day == 0, "rechazar permite salir sin activar noche")

local function historial()
  return table.concat(casino.historial, ", ")
end

entrar(30)
junto_a("ruleta")
pulsar("z")
mesa().opciones.al_jugar(2)
levantarse()
pulsar("f1")
assert(historial() == "entrar, sentarse ruleta, apuesta ruleta 2", "anota lo que pasa: " .. historial())

entrar(2)
junto_a("poker")
pulsar("z", "z")
assert(historial() == "entrar, rechazo poker", "anota el rechazo: " .. historial())

local function salir_por_la_puerta()
  casino.en_puerta = false
  casino.jugador.x, casino.jugador.y = Plano.puerta.centro.x, Plano.puerta.centro.y
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
local cambios_antes = #cambios
assert(salir_por_la_puerta() == 0 and #cambios == cambios_antes, "sin jugar no puede salir ni cambia la hora")
jugar_veces(2)
assert(salir_por_la_puerta() == 0 and #cambios == cambios_antes, "con dos juegos tampoco puede salir")
jugar_veces(1)
casino:update(0)
pulsar("down", "return")
assert(casino.decision_tomada and casino.jornada.maximo == 3, "rechazar termina la primera tanda")
assert(salir_por_la_puerta() == 0, "rechazar permite salir de dia")
assert(cambios[#cambios] == "transicion", "y pasa a la transicion")
assert(casino.historial[#casino.historial] == "salir", "anota la salida")

entrar(30)
jugar_veces(3)
casino:update(0)
pulsar("return")
assert(contexto.time_of_day == 2, "aceptar la segunda tanda activa noche")
cambios_antes = #cambios
salir_por_la_puerta()
assert(#cambios == cambios_antes, "aceptar obliga a completar seis")
jugar_veces(2)
salir_por_la_puerta()
assert(#cambios == cambios_antes, "con cinco no puede salir")
jugar_veces(1)
casino:update(0)
assert(salir_por_la_puerta() == 2, "con 6 jugadas sale de noche")

entrar(30)
jugar_veces(3)
casino:update(0)
pulsar("down", "return")
casino.jugador.x, casino.jugador.y = Plano.puerta.centro.x, Plano.puerta.centro.y
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
assert(en_pantalla("Dinero: 30 M", "Jugadas: 0 de 3"), "al entrar se ve el dinero y las jugadas")
jugar_veces(1)
contexto.economy:spend_money(2)
assert(en_pantalla("Dinero: 28 M", "Jugadas: 1 de 3"), "muestra el dinero y las jugadas del dia")

local function reentrar()
  casino:leave()
  casino:enter(contexto)
  assert(contexto.economy:get_money() == 0, "volver al casino reinicia el saldo de prueba")
  abiertas = {}
  casino.sub_estado.states = {
    ruleta = mesa_de_prueba("ruleta"),
    blackjack = mesa_de_prueba("blackjack"),
    poker = mesa_de_prueba("poker"),
  }
end

reentrar()
assert(casino.jornada.jugadas == 1 and progreso:get_value("casino_games_today") == 1,
  "volver al casino conserva el contador")
assert(cerca(casino.jugador.velocidad, RAPIDEZ * 0.92), "volver conserva el cansancio")
contexto.economy:add_money(3)
jugar_veces(2)
reentrar()
casino:update(0)
assert(casino.dialogo and not casino.decision_tomada, "recupera una decision pendiente al volver")
pulsar("down", "return")
assert(progreso:get_flag("casino_decision_made") and not progreso:get_flag("casino_extra_games_accepted"))
salir_por_la_puerta()
reentrar()
assert(casino.jornada.jugadas == 3 and casino.jornada.maximo == 3 and casino:puede_salir(),
  "rechazar y volver no reinicia la tanda ni la decision")
junto_a("ruleta")
pulsar("z")
assert(not casino.sub_estado.current and mensaje() == "Ya no quedan jugadas por hoy.",
  "no puede reabrir mesas tras terminar a las tres")

entrar(30)
jugar_veces(3)
casino:update(0)
pulsar("return")
jugar_veces(2)
reentrar()
assert(casino.jornada.jugadas == 5 and casino.jornada.maximo == 6 and casino.decision_tomada,
  "conserva la segunda tanda y sus cinco juegos")
assert(not casino:puede_salir() and contexto.time_of_day == 2, "mantiene el compromiso y la noche")
assert(cerca(casino.jugador.velocidad, RAPIDEZ * 0.60), "conserva el cansancio de cinco juegos")
contexto.economy:add_money(3)
jugar_veces(1)
casino:update(0)
salir_por_la_puerta()
reentrar()
assert(casino.jornada.jugadas == 6 and casino.jornada.maximo == 6 and casino:puede_salir(),
  "salir y volver tras seis juegos no concede juegos nuevos")
junto_a("poker")
pulsar("z")
assert(not casino.sub_estado.current, "poker sigue cerrado despues de volver")

love = love_real
print("test_casino: ok")
