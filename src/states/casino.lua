local casino = {}

function casino:enter(context)
  self.context = context
end

local x, y
function casino:update(dt)
  x = 300 + math.sin(love.timer.getTime()) * 100
  y = 300 + math.cos(love.timer.getTime()) * 100
end

function casino:draw()
  love.graphics.print("Casino - estado pendiente", 20, 20)
  love.graphics.circle("fill", x, y, 10)
end

return casino
