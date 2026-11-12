local Poker = {}

local Cards = require("lib/cards")

local ATLAS = "assets/casino/poker/cards_atlas.png"
local FONDO = love.graphics.newImage("assets/casino/poker/fondo_poker.png")
local FILTRO_ADD_PRIMERO = love.graphics.newImage("assets/casino/filtro_add_primero.png")
local FILTRO_MULTIPLY = love.graphics.newImage("assets/casino/filtro_multiply_mitad.png")
local FILTRO_ADD_ULTIMO = love.graphics.newImage("assets/casino/filtro_add_ultimo.png")

local CARTAS_POR_JUGADOR = 2
local CARTAS_COMUNALES = 5

local function ocultar_carta(carta)
  carta.visible = false
  carta.turning = false
  carta.turned = true
  carta.turn_factor = 0
end

local function revelar_inmediatamente(carta)
  carta.visible = true
  carta.turning = false
  carta.turned = true
  carta.turn_factor = 1
end

local function mostrar_carta(carta)
  carta:turn()
end

local function preparar_mano(mano, cartas_visibles)
  for indice, carta in ipairs(mano.cards) do
    if indice <= cartas_visibles then
      revelar_inmediatamente(carta)
    else
      ocultar_carta(carta)
    end
  end
end

local function dibujar_mano(mano, x, y, ancho, escala)
  love.graphics.push()
  love.graphics.translate(x, y)
  love.graphics.scale(escala or 1, escala or 1)
  mano:draw(ancho)
  love.graphics.pop()
end

local function rotulo(texto, x, y, ancho)
  love.graphics.setColor(1, 1, 1)
  love.graphics.printf(texto, x - ancho / 2, y, ancho, "center")
end

local function layout_fondo(width, height)
  local fondo_ancho, fondo_alto = FONDO:getDimensions()
  local escala = math.max(width / fondo_ancho, height / fondo_alto)
  local x = (width - fondo_ancho * escala) / 2
  local y = (height - fondo_alto * escala) / 2
  return x, y, escala
end

local function crear_multiply_shader()
  return love.graphics.newShader([[
    extern Image canvas_base;
    extern vec2 resolucion;

    vec4 effect(vec4 color, Image textura_filtro,
                vec2 coords_textura, vec2 coords_pantalla) {
      vec2 uv = coords_pantalla / resolucion;
      vec4 base = Texel(canvas_base, uv);
      vec4 blend = Texel(textura_filtro, coords_textura) * color;
      vec3 resultado = base.rgb * blend.rgb;

      // El alpha de la capa controla cuánto se aplica el multiply.
      return vec4(mix(base.rgb, resultado, blend.a), base.a);
    }
  ]])
end

local function asegurar_canvas(estado, width, height)
  if not estado.canvas_a
      or estado.canvas_a:getWidth() ~= width
      or estado.canvas_a:getHeight() ~= height then
    estado.canvas_a = love.graphics.newCanvas(width, height)
    estado.canvas_b = love.graphics.newCanvas(width, height)
  end
end

local function copiar_composicion(src, dst)
  love.graphics.setCanvas(dst)
  love.graphics.clear(0, 0, 0, 0)
  love.graphics.setShader()
  love.graphics.setBlendMode("replace")
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(src, 0, 0)
end

local function aplicar_add(estado, imagen, x, y, escala)
  local src = estado.current
  local dst = src == estado.canvas_a and estado.canvas_b or estado.canvas_a
  copiar_composicion(src, dst)

  love.graphics.setBlendMode("add")
  love.graphics.draw(imagen, x, y, 0, escala, escala)

  love.graphics.setBlendMode("alpha")
  love.graphics.setCanvas()
  estado.current = dst
end

local function aplicar_multiply(estado, imagen, x, y, escala, width, height)
  local src = estado.current
  local dst = src == estado.canvas_a and estado.canvas_b or estado.canvas_a
  copiar_composicion(src, dst)

  estado.multiply_shader:send("canvas_base", src)
  estado.multiply_shader:send("resolucion", { width, height })
  love.graphics.setShader(estado.multiply_shader)
  love.graphics.setBlendMode("replace")
  love.graphics.draw(imagen, x, y, 0, escala, escala)

  love.graphics.setShader()
  love.graphics.setBlendMode("alpha")
  love.graphics.setCanvas()
  estado.current = dst
end

function Poker:enter(context, machine)
  self.context, self.machine = context, machine
  self.fuente_titulo = love.graphics.newFont(28)
  self.fuente_indicaciones = love.graphics.newFont(18)
  self.multiply_shader = crear_multiply_shader()
  self.cartas = Cards.new({ atlas_path = ATLAS })
  self.baraja = self.cartas:create_deck()
  self.baraja:shuffle(5)

  self.jugadores = {}
  for indice = 1, 4 do
    local mano = self.cartas:create_hand()
    mano:draw_card(self.baraja, CARTAS_POR_JUGADOR)
    preparar_mano(mano, indice == 1 and CARTAS_POR_JUGADOR or 0)
    self.jugadores[#self.jugadores + 1] = mano
  end

  self.comunales = self.cartas:create_hand()
  self.comunales:draw_card(self.baraja, CARTAS_COMUNALES)
  preparar_mano(self.comunales, 0)
  self.comunales_reveladas = 0
end

function Poker:keypressed(key)
  if key == "escape" then
    self.machine:switch(nil)
  elseif key == "space" then
    self:revelar_siguiente()
  end
end

function Poker:revelar_siguiente()
  local siguiente
  if self.comunales_reveladas == 0 then
    siguiente = 3
  elseif self.comunales_reveladas == 3 then
    siguiente = 4
  elseif self.comunales_reveladas == 4 then
    siguiente = 5
  else
    return
  end

  for indice = self.comunales_reveladas + 1, siguiente do
    mostrar_carta(self.comunales.cards[indice])
  end
  self.comunales_reveladas = siguiente
end

function Poker:update(dt)
  for _, mano in ipairs(self.jugadores) do
    mano:update(dt)
  end
  self.comunales:update(dt)
end

local function dibujar_comunales(estado, x, y)
  dibujar_mano(estado.comunales, x, y, 370, 0.9)
end

local function dibujar_jugadores(estado, width, height)
  -- La escala representa la perspectiva: el jugador inferior está más cerca.
  local jugadores = {
    { indice = 1, nombre = "Jugador 1", x = width / 2, y_rotulo = height * 0.76, y_cartas = height * 0.84, escala = 1.30 },
    { indice = 2, nombre = "Jugador 2", x = width * 0.17, y_rotulo = height * 0.45, y_cartas = height * 0.53, escala = 0.82 },
    { indice = 3, nombre = "Jugador 3", x = width / 2, y_rotulo = height * 0.09, y_cartas = height * 0.15, escala = 0.64 },
    { indice = 4, nombre = "Jugador 4", x = width * 0.83, y_rotulo = height * 0.45, y_cartas = height * 0.53, escala = 0.82 },
  }

  for _, jugador in ipairs(jugadores) do
    rotulo(jugador.nombre, jugador.x, jugador.y_rotulo, 180)
    dibujar_mano(estado.jugadores[jugador.indice], jugador.x, jugador.y_cartas, 150, jugador.escala)
  end
end

local function dibujar_escena(estado, width, height)
  local centro_x, centro_y = width / 2, height / 2

  love.graphics.setFont(estado.fuente_titulo)
  rotulo("PÓKER", width / 2, 28, 240)
  love.graphics.setFont(estado.fuente_indicaciones)
  rotulo("Espacio: revelar flop, turn y river", width / 2, height - 42, 500)
  rotulo("Escape: volver al casino", width / 2, height - 20, 400)

  dibujar_comunales(estado, centro_x, centro_y - 38)
  dibujar_jugadores(estado, width, height)
end

function Poker:draw()
  local width, height = love.graphics.getDimensions()
  local x, y, escala = layout_fondo(width, height)
  asegurar_canvas(self, width, height)

  love.graphics.push("all")
  love.graphics.setCanvas(self.canvas_a)
  love.graphics.clear(0, 0, 0, 0)
  love.graphics.setShader()
  love.graphics.setBlendMode("alpha")
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(FONDO, x, y, 0, escala, escala)
  dibujar_escena(self, width, height)
  love.graphics.setCanvas()
  self.current = self.canvas_a

  aplicar_add(self, FILTRO_ADD_PRIMERO, x + (love.math.noise(love.timer.getTime() / 3) - 0.5) * 50, y, escala)
  aplicar_multiply(self, FILTRO_MULTIPLY, x, y, escala, width, height)
  aplicar_add(self, FILTRO_ADD_ULTIMO, x, y + (love.math.noise(love.timer.getTime() / 3 + 80) - 1) * 30, escala)

  love.graphics.setCanvas()
  love.graphics.setShader()
  love.graphics.setBlendMode("alpha")
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(self.current, 0, 0)
  love.graphics.pop()
end

function Poker:leave()
  self.context, self.machine = nil, nil
  self.cartas, self.baraja, self.jugadores, self.comunales = nil, nil, nil, nil
  self.comunales_reveladas = nil
  self.fuente_titulo, self.fuente_indicaciones = nil, nil
  self.multiply_shader = nil
  self.canvas_a, self.canvas_b, self.current = nil, nil, nil
end

return Poker
