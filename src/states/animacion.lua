local animacion = {}

function animacion:enter(context)
  self.context = context
end

function animacion:draw()
  love.graphics.print("Animación - estado pendiente", 20, 20)
end

return animacion
