local Ruleta = {}

function Ruleta:enter(context, machine)
  self.context, self.machine = context, machine
end

function Ruleta:keypressed(key)
  if key == "escape" then
    self.machine:switch(nil)
  end
end

function Ruleta:draw()
  local width, height = love.graphics.getDimensions()
  love.graphics.clear(0.18, 0.05, 0.08)
  love.graphics.setColor(1, 1, 1)
  love.graphics.printf("RULETA", 0, height * 0.28, width, "center")
  love.graphics.printf("Subestado activo", 0, height * 0.42, width, "center")
  love.graphics.printf("Esc: volver al casino", 0, height * 0.58, width, "center")
end

return Ruleta
