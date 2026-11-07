local transicion = {}
local player = love.graphics.newImage("assets/ugandan_knuckles.png")
local background = love.graphics.newImage("assets/transicion/background.png")
local player_pos = 0

local dialogue_player = { is_active = false, dialogue = require("src/systems/dialogue").new("dialogo.txt") }

function dialogue_player:draw()
  local w, h = love.graphics.getDimensions()
  if self.is_active then
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("fill", 0, h - h / 6, w, h)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(self.dialogue:current_line(), w / 2 - #(self.dialogue:current_line()) * 8, h - h / 12 - 10, 0, 2)
  end
end

function transicion:enter(context)
  self.context = context
end

function transicion:update(dt)
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
  if key == "space" then
    if dialogue_player.is_active then
      dialogue_player.dialogue:next()
    end
    dialogue_player.is_active = true
  end
end

function transicion:draw()
  local _, h = love.graphics.getDimensions()
  local _, bh = background:getDimensions()
  love.graphics.draw(background, 0, 0, 0, h / bh)
  local mx, my = love.mouse.getPosition()
  local _, ph = player:getDimensions()
  love.graphics.draw(player, player_pos, 655, 0, (h / ph) / 6)
  love.graphics.print(tostring(mx) .. " " .. tostring(my))
  dialogue_player:draw()
end

return transicion
