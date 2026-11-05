local StateMachine = require("src/state_machine")
local Economy = require("src/systems/economy")

local Game = {}

function Game.load()
  Game.context = {
    economy = Economy.new(),
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
