local transicion = {}
local player_pos = 0
local DialogueView = require("src/states/transicion/dialogue")

local PLAYER_IMAGE = "assets/ugandan_knuckles.png"
local BACKGROUND_IMAGE = "assets/transicion/manana_tarde.PNG"

local function load_image(path)
  local ok, image = pcall(love.graphics.newImage, path)
  if ok then
    return image
  end
  print("No se pudo cargar la imagen: " .. path)
end

function transicion:enter(context)
  self.context = context
  self.player = load_image(PLAYER_IMAGE)
  self.background = load_image(BACKGROUND_IMAGE)
  self.dialogue = DialogueView.new(context, "dialogo.lua")
end

function transicion:update(dt)
  self.dialogue:update(dt)
  local dir = 0
  local _, h = love.graphics.getDimensions()
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
  if self.background then
    love.graphics.draw(self.background, 0, 0, 0, h / self.background:getHeight())
  end
  local mx, my = love.mouse.getPosition()
  if self.player then
    love.graphics.draw(self.player, player_pos, 655, 0, (h / self.player:getHeight()) / 6)
  end
  love.graphics.print(tostring(mx) .. " " .. tostring(my))
  self.dialogue:draw()
end

return transicion
