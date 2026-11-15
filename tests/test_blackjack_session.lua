local Economy = require("src/systems/economy")
local Blackjack = require("src/states/casino/blackjack/blackjack")
local StateMachine = require("src/states/casino/state_machine")
local original_love = love
local ellipses = 0
love = {
  graphics = setmetatable({
    newImage = function()
      return { getWidth = function() return 1280 end, getHeight = function() return 800 end }
    end,
    newFont = function() return {} end,
    newQuad = function() return {} end,
    getDimensions = function() return 1280, 800 end,
    ellipse = function() ellipses = ellipses + 1 end,
  }, { __index = function() return function() end end }),
  mouse = { isVisible = function() return true end, setVisible = function() end,
    getPosition = function() return 0, 0 end },
}
local money = Economy.new(100)
local plays, amount = 0, 0
local machine = StateMachine.new({ blackjack = Blackjack, otra = {} })
machine:enter({ economy = money })
assert(machine:switch("blackjack", {
  minimo = 2, semilla = 42, pausa = 0.05,
  puede_jugar = function() return plays < 3 end,
  al_jugar = function(bet)
    assert(Blackjack.motor.fase == "resultado", "cuenta despues de liquidar la mano")
    plays, amount = plays + 1, bet
  end,
}))
local function locked()
  local motor = Blackjack.motor
  machine:keypressed("escape")
  Blackjack:ejecutar("confirmar_salir")
  Blackjack:mousepressed(1100, 50, 1)
  assert(not machine:switch(nil) and not machine:switch("otra"), "la maquina bloquea cambios de mesa sin terminar")
  assert(machine.current == Blackjack and Blackjack.motor == motor, "no reinicia el mazo al intentar salir")
end
locked()
Blackjack:draw()
assert(ellipses == 0, "no hay fichas apostadas antes de confirmar")

local function complete_game(before)
  for hand = 1, 2 do
    if hand == 2 then Blackjack:ejecutar("siguiente") end
    locked()
    Blackjack:ejecutar("confirmar")
    assert(Blackjack.partidas == hand and plays == before, "apostar no cuenta como una sesion completa")
    locked()
    local ticks = 0
    while Blackjack.motor.fase ~= "resultado" do
      ticks = ticks + 1
      assert(ticks < 200, "la ronda debe terminar")
      if Blackjack.motor.fase == "turnos" and Blackjack.motor.turno == 1 then
        Blackjack:ejecutar("plantarse")
      end
      machine:update(1)
    end
    if hand == 1 then
      assert(plays == before and machine.current == Blackjack, "la primera mano no termina la sesion")
      locked()
      ellipses = 0
      Blackjack:draw()
      assert(ellipses > 0, "las apuestas tienen fichas visibles")
    end
  end
  assert(plays == before + 1 and amount == 4 and machine.current == Blackjack,
    "dos manos suman una jugada sin expulsar al jugador")
  assert(Blackjack.jugada_registrada and Blackjack:puede_salir(), "el resultado ofrece la salida")
  machine:update(0)
  assert(plays == before + 1, "el aviso no duplica el contador")
  Blackjack:ejecutar("siguiente")
  assert(Blackjack.motor.fase == "resultado", "solo una decision explicita inicia otra sesion")
  Blackjack:draw()
end

complete_game(0)
local motor, random, recursos = Blackjack.motor, Blackjack.motor.random, Blackjack.recursos
local balance = money:get_money()
money:spend_money(balance)
assert(not Blackjack:repetir(), "sin saldo no se compromete a otra sesion")
assert(Blackjack.jugada_registrada and Blackjack:puede_salir())
money:add_money(balance)
Blackjack:mousepressed(800, 450, 1)
assert(Blackjack.motor == motor and motor.random == random and Blackjack.recursos == recursos,
  "repetir mantiene la maquina, recursos y secuencia aleatoria")
assert(plays == 1 and money:get_money() == balance and Blackjack.partidas == 0,
  "elegir repetir no cobra ni suma la siguiente jugada todavia")
locked()
complete_game(1)
machine:keypressed("right")
machine:keypressed("return")
assert(not Blackjack.jugada_registrada and Blackjack.partidas == 0)
complete_game(2)
assert(not Blackjack:puede_repetir() and not Blackjack:repetir(), "el limite del casino impide otra sesion")
Blackjack:mousepressed(800, 450, 1)
assert(plays == 3 and Blackjack.jugada_registrada, "el boton desactivado no reinicia la mesa")
machine:keypressed("escape")
assert(machine.current == nil and Blackjack.motor == nil, "salir devuelve el control al salon y limpia blackjack")

for _, monto in ipairs({ 0, 2, 4, 6, 17, 2000 }) do
  local total, pilas = 0, Blackjack.Reglas.fichas(monto)
  for _, pila in ipairs(pilas) do total = total + pila.valor * pila.cantidad end
  assert(total == monto and #pilas <= 4, "las fichas representan el importe exacto con pilas acotadas")
end
love = original_love
print("blackjack repeat, chips and guarded state machine: ok")
