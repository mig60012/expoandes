local Poker = {}

local Cards = require("lib/cards")

function Poker:enter(context, machine)
  self.context, self.machine = context, machine
end

function Poker:keypressed(key)
  if key == "escape" then
    self.machine:switch(nil)
  end
end

function Poker:draw()
  local width, height = love.graphics.getDimensions()
  love.graphics.clear(0.04, 0.10, 0.18)
  love.graphics.setColor(1, 1, 1)
  love.graphics.printf("PÓKER", 0, height * 0.28, width, "center")
  love.graphics.printf("Subestado activo", 0, height * 0.42, width, "center")
  love.graphics.printf("Esc: volver al casino", 0, height * 0.58, width, "center")
end

return Poker
