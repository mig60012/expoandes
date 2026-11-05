local Player = require("src/entities/player")

local casa = {}

function casa:enter(context)
  self.context = context
  self.player = Player.new(500, 500)
end

function casa:draw()
  love.graphics.print("Casa - estado de prueba", 20, 20)
  self.player:draw()
end

function casa:update(dt)
  self.player:update(dt)
end

return casa
