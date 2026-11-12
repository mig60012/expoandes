local Caminante = require("src/states/casino/caminante")
local Colision = require("src/states/casino/colision")
local Encuadre = require("src/states/casino/encuadre")
local Plano = require("src/states/casino/plano")
local VistaDialogo = require("src/states/casino/dialogue")
local Camara = require("lib/camera")
local Dialogue = require("src/systems/dialogue")
local CasinoStateMachine = require("src/states/casino/state_machine")
local Poker = require("src/states/casino/poker/poker")
local Blackjack = require("src/states/casino/blackjack/blackjack")
local Ruleta = require("src/states/casino/ruleta/ruleta")

local casino = {}

local RIGIDEZ_CAMARA = 7
local ALTURA_CAMARA = 70
local TAMANO_LETRA = 18
local ALTURA_AVISO = 240
local CARPETA_FOTOS = "src/states/casino/assets/"

local PISO = { 0.88, 0.88, 0.88 }
local PARED_IZQUIERDA = { 0.74, 0.74, 0.74 }
local PARED_DERECHA = { 0.66, 0.66, 0.66 }
local FIGURA = { 0.8, 0.8, 0.8 }
local BORDE = { 0.2, 0.2, 0.2 }
local TEXTO = { 0.1, 0.1, 0.1 }
local PERSONAJE = { 0.3, 0.3, 0.3 }

local function rotulo(texto, x, y, ancho, color)
  love.graphics.setColor(color or TEXTO)
  love.graphics.printf(texto, x - ancho / 2, y - TAMANO_LETRA, ancho, "center")
end

local function figura(poligono, color)
  love.graphics.setColor(color)
  for _, triangulo in ipairs(love.math.triangulate(poligono)) do
    love.graphics.polygon("fill", triangulo)
  end
  love.graphics.setColor(BORDE)
  love.graphics.setLineWidth(3)
  love.graphics.polygon("line", poligono)
end

local function cargar_fotos()
  local fotos = {}
  for _, objeto in ipairs(Plano.objetos) do
    if objeto.foto then
      local ok, imagen = pcall(love.graphics.newImage, CARPETA_FOTOS .. objeto.foto.archivo .. ".png")
      if ok then
        fotos[objeto] = imagen
      end
    end
  end
  return fotos
end

local function dibujar_mesa(objeto, imagen)
  local foto = objeto.foto
  love.graphics.setColor(1, 1, 1)
  love.graphics.draw(imagen, foto.x, foto.y, 0, foto.ancho / imagen:getWidth(), foto.alto / imagen:getHeight())
  rotulo(objeto.nombre, foto.x + foto.ancho / 2, foto.y + foto.alto * 0.42, foto.ancho, PISO)
end

local function dibujar_mapa(fuente, fotos)
  local lienzo = love.graphics.newCanvas(Plano.ancho, Plano.alto, { msaa = 4 })
  love.graphics.push("all")
  love.graphics.origin()
  love.graphics.setCanvas(lienzo)
  love.graphics.clear(PISO[1], PISO[2], PISO[3], 1)
  love.graphics.setFont(fuente)
  figura(Plano.paredes.izquierda, PARED_IZQUIERDA)
  figura(Plano.paredes.derecha, PARED_DERECHA)
  rotulo("pared", 620, 430, 300)
  rotulo("pared", 1600, 400, 300)
  rotulo("piso", 1200, 1290, 300)
  figura(Plano.puerta.marco, FIGURA)
  rotulo("puerta", 1970, 680, 140)
  figura(Plano.puerta.zona, PISO)
  for _, objeto in ipairs(Plano.objetos) do
    if not fotos[objeto] then
      figura(objeto.choque, FIGURA)
      rotulo(objeto.nombre, objeto.x, objeto.y, 240)
    end
  end
  love.graphics.pop()
  return lienzo
end

local function dibujar_jugador(jugador)
  local ancho, alto = Plano.jugador.ancho, Plano.jugador.alto
  love.graphics.setColor(BORDE)
  love.graphics.ellipse("fill", jugador.x, jugador.y, Plano.jugador.radio, Plano.jugador.radio / Plano.estiramiento)
  love.graphics.setColor(PERSONAJE)
  love.graphics.rectangle("fill", jugador.x - ancho / 2, jugador.y - alto, ancho, alto)
end

local function dibujar_aviso(objeto, fuente)
  local texto = "Z  " .. objeto.etiqueta
  local ancho, alto = fuente:getWidth(texto) + 30, fuente:getHeight() + 14
  love.graphics.setColor(PERSONAJE)
  love.graphics.rectangle("fill", objeto.x - ancho / 2, objeto.y - ALTURA_AVISO - alto, ancho, alto)
  love.graphics.setColor(PISO)
  love.graphics.print(texto, objeto.x - ancho / 2 + 15, objeto.y - ALTURA_AVISO - alto + 7)
end

function casino:encuadrar(dt)
  local ancho, alto = love.graphics.getDimensions()
  local zoom = Encuadre.zoom(ancho, alto, Plano.vista.ancho, Plano.vista.alto)
  local x, y = Encuadre.centro(self.jugador.x, self.jugador.y - ALTURA_CAMARA, ancho, alto, zoom, Plano.ancho, Plano.alto)
  if dt then
    x = Encuadre.suavizar(self.camara.x, x, dt, RIGIDEZ_CAMARA)
    y = Encuadre.suavizar(self.camara.y, y, dt, RIGIDEZ_CAMARA)
  end
  self.camara:zoomTo(zoom)
  self.camara:lookAt(x, y)
end

function casino:enter(context)
  self.context = context
  self.sub_estado = CasinoStateMachine.new({
    blackjack = Blackjack,
    poker = Poker,
    ruleta = Ruleta,
  })
  self.sub_estado:enter(context)
  self.fuente = love.graphics.newFont(TAMANO_LETRA)
  self.fuente_dialogo = love.graphics.newFont(math.max(16, math.floor(love.graphics.getHeight() * 0.032)))
  self.fotos = cargar_fotos()
  self.mapa = dibujar_mapa(self.fuente, self.fotos)
  self.interactuables = {}
  local poligonos = { Plano.suelo }
  for _, objeto in ipairs(Plano.objetos) do
    poligonos[#poligonos + 1] = objeto.choque
    if objeto.interaccion then
      self.interactuables[#self.interactuables + 1] = objeto
    end
  end
  self.jugador = Caminante.new({
    x = Plano.inicio.x,
    y = Plano.inicio.y,
    velocidad = Plano.jugador.velocidad,
    radio = Plano.jugador.radio,
    estiramiento = Plano.estiramiento,
    poligonos = poligonos,
  })
  self.camara = Camara(self.jugador.x, self.jugador.y, 1)
  self:encuadrar()
end

function casino:leave()
  if self.sub_estado then
    self.sub_estado:leave()
  end
  self.context, self.fuente, self.fuente_dialogo, self.mapa, self.jugador, self.camara = nil
  self.fotos, self.interactuables, self.cercano, self.dialogo, self.en_puerta, self.sub_estado = nil
end

function casino:abrir(nodo)
  local dialogo = Dialogue.new({ start = "inicio", nodes = { inicio = nodo } }, self.context)
  self.dialogo = VistaDialogo.new(dialogo, function(opcion)
    self.dialogo = nil
    if opcion and opcion.salir then
      self.context.state_machine:switch("transicion")
    end
  end)
end

function casino:keypressed(tecla, scancode, isrepeat)
  if self.sub_estado.current then
    self.sub_estado:keypressed(tecla, scancode, isrepeat)
    return
  end
  if self.dialogo then
    self.dialogo:keypressed(tecla)
  elseif self.cercano and (tecla == "z" or tecla == "return") then
    if self.cercano.interaccion then
      self.sub_estado:switch(self.cercano.interaccion)
    end
  end
end

function casino:update(dt)
  if self.sub_estado.current then
    self.sub_estado:update(dt)
    return
  end
  if not self.dialogo then
    local tecla = love.keyboard.isDown
    local dx = (tecla("right", "d") and 1 or 0) - (tecla("left", "a") and 1 or 0)
    local dy = (tecla("down", "s") and 1 or 0) - (tecla("up", "w") and 1 or 0)
    self.jugador:mover(dx, dy, dt)
    self.cercano = self.jugador:mas_cercano(self.interactuables, Plano.jugador.alcance)
    local en_puerta = Colision.dentro(self.jugador.x, self.jugador.y, Plano.puerta.zona)
    if en_puerta and not self.en_puerta then
      self:abrir({ speaker = "Puerta", text = "¿Quieres salir del casino?", choices = { { text = "Sí", salir = true }, { text = "No" } } })
    end
    self.en_puerta = en_puerta
  end
  self:encuadrar(dt)
end

function casino:draw()
  if self.sub_estado.current then
    self.sub_estado:draw()
    return
  end
  love.graphics.push("all")
  self.camara:attach()
  love.graphics.setFont(self.fuente)
  love.graphics.setColor(1, 1, 1)
  love.graphics.draw(self.mapa)
  for objeto, imagen in pairs(self.fotos) do
    if not self.jugador:detras_de(objeto) then
      dibujar_mesa(objeto, imagen)
    end
  end
  dibujar_jugador(self.jugador)
  for objeto, imagen in pairs(self.fotos) do
    if self.jugador:detras_de(objeto) then
      dibujar_mesa(objeto, imagen)
    end
  end
  if self.cercano and not self.dialogo then
    dibujar_aviso(self.cercano, self.fuente)
  end
  self.camara:detach()
  if self.dialogo then
    local ancho, alto = love.graphics.getDimensions()
    self.dialogo:draw(ancho, alto, self.fuente_dialogo)
  end
  love.graphics.pop()
end

function casino:keyreleased(tecla, scancode)
  if self.sub_estado.current then
    self.sub_estado:keyreleased(tecla, scancode)
  end
end

function casino:mousepressed(x, y, button, istouch, presses)
  if self.sub_estado.current then
    self.sub_estado:mousepressed(x, y, button, istouch, presses)
  end
end

return casino
