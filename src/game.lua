-- En este modulo se tiene todo el contexto del juego, es decir, las decisiones tomadas por el jugador, la cantidad de dinero que tenga etc.

local StateMachine = require("src/state_machine")
local Economy = require("src/systems/economy")

local Game = {}

function Game.load()
  Game.context = {
    economy = Economy.new(),
    state_machine = StateMachine,
  }

  StateMachine.load(Game.context)
end

function Game.update(dt)
  StateMachine:update(dt)
end

function Game.draw()
  StateMachine:draw()
end

function Game.keypressed(key, scancode, isrepeat)
  StateMachine:keypressed(key, scancode, isrepeat)
end

function Game.keyreleased(key, scancode)
  StateMachine:keyreleased(key, scancode)
end

return Game
