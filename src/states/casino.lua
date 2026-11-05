local casino = {}

function casino:enter(context)
  self.context = context
end

function casino:draw()
  love.graphics.print("Casino - estado pendiente", 20, 20)
end

return casino
