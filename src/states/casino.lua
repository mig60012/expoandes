local Caminante = require("src/states/casino/caminante")
local Encuadre = require("src/states/casino/encuadre")
local Plano = require("src/states/casino/plano")
local Camara = require("lib/camera")

local casino = {}

local RIGIDEZ_CAMARA = 7
local ALTURA_CAMARA = 70
local TAMANO_LETRA = 18
local PENDIENTE = "\n(arte pendiente)"

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

local function dibujar_mapa(fuente)
  local lienzo = love.graphics.newCanvas(Plano.ancho, Plano.alto, { msaa = 4 })
  love.graphics.push("all")
  love.graphics.origin()
  love.graphics.setCanvas(lienzo)
  love.graphics.clear(PISO[1], PISO[2], PISO[3], 1)
  love.graphics.setFont(fuente)
  figura(Plano.paredes.izquierda, PARED_IZQUIERDA)
  figura(Plano.paredes.derecha, PARED_DERECHA)
  rotulo("pared" .. PENDIENTE, 620, 430, 300)
  rotulo("pared" .. PENDIENTE, 1600, 400, 300)
  rotulo("piso" .. PENDIENTE, 1200, 1290, 300)
  figura(Plano.puerta.marco, FIGURA)
  rotulo("puerta" .. PENDIENTE, 1970, 680, 140)
  figura(Plano.puerta.zona, PISO)
  rotulo("salida", 1925, 815, 140)
  for _, objeto in ipairs(Plano.objetos) do
    figura(objeto.choque, FIGURA)
    rotulo(objeto.nombre .. PENDIENTE, objeto.x, objeto.y, 240)
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
  rotulo("jugador", jugador.x, jugador.y - alto / 2, 100, PISO)
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
  self.fuente = love.graphics.newFont(TAMANO_LETRA)
  self.mapa = dibujar_mapa(self.fuente)
  local poligonos = { Plano.suelo }
  for _, objeto in ipairs(Plano.objetos) do
    poligonos[#poligonos + 1] = objeto.choque
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
  self.context, self.fuente, self.mapa, self.jugador, self.camara = nil
end

function casino:update(dt)
  local tecla = love.keyboard.isDown
  local dx = (tecla("right", "d") and 1 or 0) - (tecla("left", "a") and 1 or 0)
  local dy = (tecla("down", "s") and 1 or 0) - (tecla("up", "w") and 1 or 0)
  self.jugador:mover(dx, dy, dt)
  self:encuadrar(dt)
end

function casino:draw()
  love.graphics.push("all")
  self.camara:attach()
  love.graphics.setFont(self.fuente)
  love.graphics.setColor(1, 1, 1)
  love.graphics.draw(self.mapa)
  dibujar_jugador(self.jugador)
  self.camara:detach()
  love.graphics.pop()
end

return casino
