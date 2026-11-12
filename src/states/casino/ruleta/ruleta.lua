local RUTA = (...):match('^(.*[%./])[^%.%/]+$') or ''
local Rueda = require(RUTA .. "rueda")
local Apuestas = require(RUTA .. "apuestas")
local Giro = require(RUTA .. "giro")
local Vista = require(RUTA .. "vista")

local Ruleta = {}

local CODICIA, DINERO_PRUEBA, MINIMO, PAUSA = 100, 3, 1, 0.8

local function posicion(numero)
  for i, n in ipairs(Rueda.orden) do
    if n == numero then
      return i
    end
  end
end

function Ruleta:enter(context, machine)
  self.context, self.machine = context, machine
  self.recursos = Vista.recursos()
  self.indices = {}
  for i, apuesta in ipairs(Apuestas.lista) do
    self.indices[apuesta.nombre] = i
  end
  self.reloj, self.angulo_rueda, self.monto = 0, 0, MINIMO
  self.eleccion, self.giro, self.encima, self.angulo_pelota = nil
  self.raton_visible = love.mouse.isVisible()
  love.mouse.setVisible(true)
  self:etapa_nueva("mesa", "Elige tu apuesta y pulsa APOSTAR.")
end

function Ruleta:leave()
  love.mouse.setVisible(self.raton_visible)
  love.mouse.setCursor()
  self.context, self.machine, self.recursos, self.indices, self.giro, self.jugadas, self.encima = nil
end

function Ruleta:etapa_nueva(etapa, mensaje)
  self.etapa, self.mensaje, self.en_etapa, self.arrastrando = etapa, mensaje, 0, false
end

function Ruleta:dinero()
  return self.context.economy:get_money()
end

function Ruleta:apostar()
  if not self.eleccion then
    self.mensaje = "Primero elige una apuesta en el paño."
  elseif self:dinero() < MINIMO then
    self.mensaje = "No te alcanza: necesitas al menos " .. MINIMO .. " M."
  else
    self.monto = math.max(MINIMO, math.min(self.monto, self:dinero()))
    self:etapa_nueva("monto")
  end
end

function Ruleta:cambiar_monto(paso)
  self.monto = math.max(MINIMO, math.min(self.monto + paso, self:dinero()))
end

function Ruleta:deslizar(x)
  self.monto = MINIMO + math.floor(Vista.deslizador(x) * (self:dinero() - MINIMO) + 0.5)
end

function Ruleta:girar()
  self.context.economy:spend_money(self.monto)
  self.jugadas = { { apuesta = Apuestas.lista[self.eleccion], monto = self.monto } }
  self.numero = Apuestas.girar(self.jugadas, love.math.random, CODICIA)
  self.giro = Giro.nuevo(posicion(self.numero), #Rueda.orden, self.angulo_rueda)
  self:etapa_nueva("giro")
end

function Ruleta:cobrar()
  local numero, apuesta = self.numero, Apuestas.lista[self.eleccion]
  local pago = Apuestas.pago(self.jugadas, numero)
  self.context.economy:add_money(pago)
  self.gano = pago > 0
  local razon = (numero == 0 and not self.gano) and "El 0 solo gana si apuestas al 0"
    or ("El " .. numero .. (self.gano and " está" or " no está") .. " en tu apuesta")
  self.explicacion = {
    "La pelota cayó en el " .. numero .. " " .. Rueda.color(numero) .. ".",
    "Tu apuesta, " .. apuesta.nombre .. ", " .. apuesta.descripcion .. ".",
    razon .. (self.gano and (": ganas " .. (pago - self.monto) .. " M.") or (": pierdes " .. self.monto .. " M.")),
  }
  self:etapa_nueva("resultado")
end

function Ruleta:update(dt)
  self.reloj, self.en_etapa = self.reloj + dt, self.en_etapa + dt
  if self.arrastrando then
    if love.mouse.isDown(1) then
      self:deslizar((love.mouse.getPosition()))
    else
      self.arrastrando = false
    end
  end
  if self.etapa == "giro" then
    self.angulo_rueda, self.angulo_pelota, self.radio_pelota, self.salto = Giro.estado(self.giro, self.en_etapa)
    if self.en_etapa >= self.giro.duracion + PAUSA then
      self:cobrar()
    end
  end
  self.encima = Vista.tocar(self.recursos, self.etapa, love.mouse.getPosition())
  if self.encima then
    love.mouse.setCursor(self.recursos.mano)
  else
    love.mouse.setCursor()
  end
end

function Ruleta:mousepressed(x, y, boton)
  local zona = boton == 1 and Vista.tocar(self.recursos, self.etapa, x, y)
  if not zona then
    return
  end
  if zona.apuesta then
    self.eleccion, self.mensaje = self.indices[zona.apuesta], nil
  elseif zona.accion == "apostar" then
    self:apostar()
  elseif zona.accion == "barra" then
    self.arrastrando = true
    self:deslizar(x)
  elseif zona.accion == "confirmar" then
    self:girar()
  elseif zona.accion == "volver" or zona.accion == "otra" then
    self:etapa_nueva("mesa")
  else
    self.machine:switch(nil)
  end
end

function Ruleta:keypressed(tecla)
  local confirmar = tecla == "z" or tecla == "return"
  if self.etapa == "mesa" then
    if tecla == "escape" then
      self.machine:switch(nil)
    elseif tecla == "f1" then
      self.context.economy:add_money(DINERO_PRUEBA)
      self.mensaje = "Recibiste " .. DINERO_PRUEBA .. " M de prueba."
    elseif confirmar then
      self:apostar()
    end
  elseif self.etapa == "monto" then
    if tecla == "escape" then
      self:etapa_nueva("mesa")
    elseif tecla == "left" or tecla == "down" then
      self:cambiar_monto(-1)
    elseif tecla == "right" or tecla == "up" then
      self:cambiar_monto(1)
    elseif confirmar then
      self:girar()
    end
  elseif self.etapa == "resultado" then
    if tecla == "escape" then
      self.machine:switch(nil)
    elseif confirmar then
      self:etapa_nueva("mesa")
    end
  end
end

function Ruleta:draw()
  local aparicion = math.min(1, self.en_etapa * 3)
  local avance = self.giro and (self.etapa == "giro" and math.min(1, self.en_etapa / self.giro.duracion) or 1) or 0
  Vista.dibujar({
    etapa = self.etapa,
    reloj = self.reloj,
    aparicion = aparicion,
    fundido = (self.etapa == "mesa" or self.etapa == "giro") and 1 - aparicion or 0,
    apuesta = self.eleccion and Apuestas.lista[self.eleccion],
    monto = self.monto,
    minimo = MINIMO,
    maximo = self:dinero(),
    dinero = self:dinero(),
    mensaje = self.mensaje,
    encima = self.encima,
    angulo_rueda = self.angulo_rueda,
    angulo_pelota = self.angulo_pelota,
    radio_pelota = self.radio_pelota,
    salto = self.salto,
    numero = self.etapa == "resultado" and self.numero or nil,
    acercamiento = 1 + 0.06 * avance,
    gano = self.gano,
    explicacion = self.explicacion,
  }, self.recursos)
end

return Ruleta
