local VistaApuesta = {}
VistaApuesta.__index = VistaApuesta

local FONDO = { 0.15, 0.15, 0.15, 0.95 }
local TITULO = { 0.75, 0.75, 0.75 }
local LETRA = { 0.95, 0.95, 0.95 }

function VistaApuesta.new(opciones)
  return setmetatable({
    apuesta = opciones.apuesta,
    salto_chico = opciones.salto_chico,
    salto_grande = opciones.salto_grande,
    titulo = opciones.titulo,
    renglones = opciones.renglones,
  }, VistaApuesta)
end

function VistaApuesta:keypressed(tecla)
  if tecla == "up" or tecla == "w" then
    self.apuesta:cambiar(self.salto_chico)
  elseif tecla == "down" or tecla == "s" then
    self.apuesta:cambiar(-self.salto_chico)
  elseif tecla == "right" or tecla == "d" then
    self.apuesta:cambiar(self.salto_grande)
  elseif tecla == "left" or tecla == "a" then
    self.apuesta:cambiar(-self.salto_grande)
  elseif tecla == "z" or tecla == "return" then
    self.apuesta:confirmar()
  elseif tecla == "x" or tecla == "backspace" then
    self.apuesta:cancelar()
  end
end

function VistaApuesta:draw(ancho, alto, fuente)
  local margen, caja = alto * 0.04, alto * 0.25
  local x, y, w = margen, alto - caja - margen, ancho - margen * 2
  local renglon = fuente:getHeight() * 1.35
  love.graphics.setColor(FONDO)
  love.graphics.rectangle("fill", x, y, w, caja, 14)
  love.graphics.setColor(TITULO)
  love.graphics.setLineWidth(4)
  love.graphics.rectangle("line", x, y, w, caja, 14)
  love.graphics.setFont(fuente)
  love.graphics.print(self.titulo, x + margen, y + margen * 0.6)
  love.graphics.setColor(LETRA)
  for i, texto in ipairs(self.renglones(self.apuesta)) do
    love.graphics.print(texto, x + margen, y + margen * 0.6 + renglon * i)
  end
end

return VistaApuesta
