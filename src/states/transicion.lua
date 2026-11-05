local transicion = {}

function transicion:enter(context)
  self.context = context
end

function transicion:draw()
  love.graphics.print("Transición - estado pendiente", 20, 20)
end

return transicion
