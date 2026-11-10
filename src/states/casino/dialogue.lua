local VistaDialogo = {}
VistaDialogo.__index = VistaDialogo

local FONDO = { 0.15, 0.15, 0.15, 0.95 }
local TITULO = { 0.75, 0.75, 0.75 }
local LETRA = { 0.95, 0.95, 0.95 }

function VistaDialogo.new(dialogo, al_terminar)
  return setmetatable({ dialogo = dialogo, al_terminar = al_terminar, opcion = 1 }, VistaDialogo)
end

function VistaDialogo:keypressed(tecla)
  local opciones = self.dialogo:get_choices() or {}
  if tecla == "up" or tecla == "w" then
    self.opcion = math.max(1, self.opcion - 1)
  elseif tecla == "down" or tecla == "s" then
    self.opcion = math.min(math.max(1, #opciones), self.opcion + 1)
  elseif tecla == "z" or tecla == "return" then
    local elegida = opciones[self.opcion]
    if elegida then
      self.dialogo:choose(self.opcion)
    else
      self.dialogo:advance()
    end
    self.opcion = 1
    if self.dialogo:is_finished() then
      self.al_terminar(elegida and elegida.choice)
    end
  end
end

function VistaDialogo:draw(ancho, alto, fuente)
  local margen, caja = alto * 0.04, alto * 0.25
  local x, y, w = margen, alto - caja - margen, ancho - margen * 2
  local renglon = fuente:getHeight() * 1.35
  love.graphics.setColor(FONDO)
  love.graphics.rectangle("fill", x, y, w, caja, 14)
  love.graphics.setColor(TITULO)
  love.graphics.setLineWidth(4)
  love.graphics.rectangle("line", x, y, w, caja, 14)
  love.graphics.setFont(fuente)
  love.graphics.print(self.dialogo:current_speaker() or "", x + margen, y + margen * 0.6)
  love.graphics.setColor(LETRA)
  love.graphics.printf(self.dialogo:current_line() or "", x + margen, y + margen * 0.6 + renglon, w - margen * 2)
  for i, entrada in ipairs(self.dialogo:get_choices() or {}) do
    local marca = i == self.opcion and "> " or "   "
    love.graphics.print(marca .. entrada.choice.text, x + margen, y + margen * 0.6 + renglon * (1 + i))
  end
end

return VistaDialogo
