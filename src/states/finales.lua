local FinalEvaluation = require("src/systems/final_evaluation")
local FinalData = require("src/data/dialogues/finals")

local Finales = {}

function Finales:enter(context)
  self.context = context
  self.id = FinalEvaluation.evaluate(context)
  self.data = FinalData[self.id]
  self.font = love.graphics.newFont(28)
  self.small_font = love.graphics.newFont(18)
end

function Finales:update(_dt)
end

function Finales:keypressed(key)
  if key == "r" then
    self.context.progress:reset()
    self.context.day_flow:start_day(1)
    self.context.state_machine:switch("casa")
  end
end

function Finales:draw()
  local w, h = love.graphics.getDimensions()
  love.graphics.clear(0.04, 0.04, 0.06)
  love.graphics.setColor(1, 1, 1)
  love.graphics.setFont(self.font)
  love.graphics.printf(self.data.title, 40, h * 0.28, w - 80, "center")
  love.graphics.setFont(self.small_font)
  love.graphics.printf(self.data.text, 100, h * 0.46, w - 200, "center")
  love.graphics.printf("Pulsa R para comenzar una nueva partida", 40, h * 0.78, w - 80, "center")
end

return Finales
