local VistaApuesta = {}
VistaApuesta.__index = VistaApuesta

function VistaApuesta.new(opciones)
  return setmetatable({
    apuesta = opciones.apuesta,
    salto_chico = opciones.salto_chico,
    salto_grande = opciones.salto_grande,
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

return VistaApuesta
