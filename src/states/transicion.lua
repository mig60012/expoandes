local transicion = {}
local player = love.graphics.newImage("assets/ugandan_knuckles.png")
local background = love.graphics.newImage("assets/transicion/background.png")
local player_pos = 0
local DialogueView = require("src/states/transicion/dialogue")

function transicion:enter(context)
  self.context = context
  self.dialogue = DialogueView.new(context, "dialogo.lua")
end

function transicion:update(dt)
  self.dialogue:update(dt)
  local dir = 0
  local _, h = love.graphics.getDimensions()
  local pw, ph = player:getDimensions()
  if love.keyboard.isDown("a") then
    dir = dir - (h / 4) * dt
  end
  if love.keyboard.isDown("d") then
    dir = dir + (h / 4) * dt
  end
  player_pos = player_pos + dir
end

function transicion:keypressed(key)
  self.dialogue:keypressed(key)
end

function transicion:draw()
  local _, h = love.graphics.getDimensions()
  local _, bh = background:getDimensions()
  love.graphics.draw(background, 0, 0, 0, h / bh)
  local mx, my = love.mouse.getPosition()
  local _, ph = player:getDimensions()
  love.graphics.draw(player, player_pos, 655, 0, (h / ph) / 6)
  love.graphics.print(tostring(mx) .. " " .. tostring(my))
  self.dialogue:draw()
end

return transicion
