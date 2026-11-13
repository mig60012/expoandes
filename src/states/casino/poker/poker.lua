local Poker = {}

local Cards = require("lib/cards")
local Bot = require("src/systems/poker_bot")
local PokerGame = require("src/systems/poker_game")
local HoldemCard = require("holdem.card")
local Analysis = require("holdem.analysis")

local ATLAS = "assets/casino/poker/cards_atlas.png"
local LIGHT = love.graphics.newImage("assets/casino/poker/light_poker.png")
local FONDO = love.graphics.newImage("assets/casino/poker/fondo_poker_2.png")
local FILTRO_ADD_PRIMERO = love.graphics.newImage("assets/casino/filtro_add_primero.png")
local FILTRO_MULTIPLY = love.graphics.newImage("assets/casino/filtro_multiply_mitad.png")
local FILTRO_ADD_ULTIMO = love.graphics.newImage("assets/casino/filtro_add_ultimo.png")

local CARTAS_POR_JUGADOR = 2
local CARTAS_COMUNALES = 5
local DINERO_INICIAL_BOT = 1000
local APUESTA_MINIMA = 10
local DEAL_DELAY = 0.085

local SUIT_BY_NAME = {
  spades = 1,
  hearts = 2,
  diamonds = 3,
  clubs = 4,
}

local function convertir_carta(carta)
  -- cards.lua representa el as como rango 1; holdem usa 14.
  local rango = carta.rank == 1 and 14 or carta.rank
  return HoldemCard.Card(rango, SUIT_BY_NAME[carta.suit])
end

local function convertir_mano(mano)
  local cartas = {}
  for _, carta in ipairs(mano.cards) do
    cartas[#cartas + 1] = convertir_carta(carta)
  end
  return cartas
end

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

local function crear_bots()
  return {
    Bot:new("Bot 2", DINERO_INICIAL_BOT, "Fish"),
    Bot:new("Bot 3", DINERO_INICIAL_BOT, "Maniac"),
    Bot:new("Bot 4", DINERO_INICIAL_BOT, "Nit"),
  }
end

local function lerp(a, b, t)
  return a + (b - a) * t
end

local function mesa_layout(width, height)
  return {
    deck = { x = width * 0.73, y = height * 0.42, scale = 1.12 },
    community = { x = width / 2, y = height * 0.46, width = 435, scale = 1.18 },
    players = {
      { x = width / 2, y = height * 0.84, width = 205, scale = 1.62 },
      { x = width * 0.17, y = height * 0.53, width = 175, scale = 0.98, shear = -0.5 },
      { x = width / 2, y = height * 0.15, width = 165, scale = 0.74 },
      { x = width * 0.83, y = height * 0.53, width = 175, scale = 0.98, shear = 0.5 },
    },
  }
end

local function destino_carta(layout, index, total)
  local spacing = layout.width / total
  local local_x = spacing * (index - 0.5) - layout.width / 2
  return layout.x + local_x * layout.scale,
    layout.y + math.abs(local_x) * math.abs(layout.shear or 0) * 0.18
end

local function punto_en_rect(x, y, rect)
  return x >= rect.x - rect.w / 2 and x <= rect.x + rect.w / 2
    and y >= rect.y - rect.h / 2 and y <= rect.y + rect.h / 2
end

local function crear_multiply_shader()
  return love.graphics.newShader([[
    extern Image canvas_base;
    extern vec2 resolucion;
    vec4 effect(vec4 color, Image textura, vec2 uv, vec2 screen) {
      vec4 base = Texel(canvas_base, screen / resolucion);
      vec4 filtro = Texel(textura, uv) * color;
      return vec4(mix(base.rgb, base.rgb * filtro.rgb, filtro.a), base.a);
    }
  ]])
end

local function asegurar_canvas(estado, width, height)
  if not estado.canvas_a or estado.canvas_a:getWidth() ~= width or estado.canvas_a:getHeight() ~= height then
    estado.canvas_a = love.graphics.newCanvas(width, height)
    estado.canvas_b = love.graphics.newCanvas(width, height)
  end
end

local function copiar_canvas(origen, destino)
  love.graphics.setCanvas(destino)
  love.graphics.clear(0, 0, 0, 0)
  love.graphics.setBlendMode("replace")
  love.graphics.setShader()
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(origen, 0, 0)
end

local function aplicar_add(estado, imagen, x, y, escala)
  local origen = estado.current
  local destino = origen == estado.canvas_a and estado.canvas_b or estado.canvas_a
  copiar_canvas(origen, destino)
  love.graphics.setBlendMode("add")
  love.graphics.setColor(0.62, 0.52, 0.46, 0.72)
  love.graphics.draw(imagen, x, y, 0, escala, escala)
  love.graphics.setBlendMode("alpha")
  love.graphics.setCanvas()
  estado.current = destino
end

local function aplicar_multiply(estado, imagen, x, y, escala, width, height)
  local origen = estado.current
  local destino = origen == estado.canvas_a and estado.canvas_b or estado.canvas_a
  copiar_canvas(origen, destino)
  estado.multiply_shader:send("canvas_base", origen)
  estado.multiply_shader:send("resolucion", { width, height })
  love.graphics.setCanvas(destino)
  love.graphics.setBlendMode("replace")
  love.graphics.setShader(estado.multiply_shader)
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(imagen, x, y, 0, escala, escala)
  love.graphics.setShader()
  love.graphics.setBlendMode("alpha")
  love.graphics.setCanvas()
  estado.current = destino
end

local function layout_fondo(width, height)
  local fondo_ancho, fondo_alto = FONDO:getDimensions()
  local escala = math.max(width / fondo_ancho, height / fondo_alto)
  local x = (width - fondo_ancho * escala) / 2
  local y = (height - fondo_alto * escala) / 2
  return x, y, escala
end

function Poker:enter(context, machine)
  self.context, self.machine = context, machine
  self.fuente_ui = love.graphics.newFont(18)
  self.fuente_boton = love.graphics.newFont(21)
  self.cartas = Cards.new({ atlas_path = ATLAS })
  self.bots = crear_bots()
  self.game = PokerGame:new({
    { name = "Jugador 1", stack = DINERO_INICIAL_BOT },
    { name = self.bots[1].name, controller = self.bots[1] },
    { name = self.bots[2].name, controller = self.bots[2] },
    { name = self.bots[3].name, controller = self.bots[3] },
  }, {
    small_blind = 5,
    big_blind = 10,
    min_raise = APUESTA_MINIMA,
    auto_bots = false,
    evaluator = function(hole_cards, board_cards)
      return Analysis.evaluate(hole_cards, board_cards)
    end,
  })
  self.botones, self.particulas = {}, {}
  self.visual_pot = 0
  self:iniciar_mano()
end

function Poker:iniciar_mano()
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
  self.holdem_board = {}

  for indice, bot in ipairs(self.bots) do
    local mano = convertir_mano(self.jugadores[indice + 1])
    bot:receiveCards(mano[1], mano[2])
  end

  local hole_cards = {}
  for _, mano in ipairs(self.jugadores) do
    hole_cards[#hole_cards + 1] = convertir_mano(mano)
  end
  self.game:start_hand(hole_cards)
  self:programar_reparto_inicial()
end

function Poker:programar_reparto_inicial()
  local width, height = love.graphics.getDimensions()
  local layout = mesa_layout(width, height)
  self.baraja:set_position(layout.deck.x, layout.deck.y, layout.deck.scale)

  local orden = 0
  for carta_indice = 1, CARTAS_POR_JUGADOR do
    for jugador_indice, mano in ipairs(self.jugadores) do
      orden = orden + 1
      local asiento = layout.players[jugador_indice]
      local x, y = destino_carta(asiento, carta_indice, CARTAS_POR_JUGADOR)
      mano.cards[carta_indice]:deal_from(layout.deck.x, layout.deck.y, x, y, {
        delay = orden * DEAL_DELAY,
        duration = 0.46,
      })
    end
  end
  for indice, carta in ipairs(self.comunales.cards) do
    local x, y = destino_carta(layout.community, indice, CARTAS_COMUNALES)
    ocultar_carta(carta)
    orden = orden + 1
    carta:deal_from(layout.deck.x, layout.deck.y, x, y, {
      delay = orden * DEAL_DELAY,
      duration = 0.46,
    })
  end
  self.input_lock = orden * DEAL_DELAY + 0.34
end

function Poker:accion_jugador(action)
  if not self.game:is_human_turn() then
    return
  end

  local jugador = self.game.players[1]
  local amount_to_call = self.game:get_amount_to_call(jugador)
  local amount = 0

  if action == "call" then
    amount = math.min(amount_to_call, jugador.stack)
  elseif action == "allin" then
    action = jugador.stack > amount_to_call and "raise" or "call"
    amount = jugador.stack
  elseif action == "raise" then
    if jugador.stack <= amount_to_call then
      action = amount_to_call > 0 and "call" or "check"
      amount = math.min(amount_to_call, jugador.stack)
    else
      amount = math.min(self.game:get_raise_amount(jugador), jugador.stack)
    end
  end

  local ok = self.game:apply_action(1, {
    action = action,
    amount = amount,
  })
  if ok and self.game.status == "showdown" then
    self:terminar_mano()
  end
end

function Poker:terminar_mano()
  self.game:finish_hand()
  for indice, mano in ipairs(self.jugadores) do
    if self.game.players[indice].folded then
      preparar_mano(mano, 0)
    else
      preparar_mano(mano, CARTAS_POR_JUGADOR)
    end
  end
end

function Poker:avanzar_o_mostrar_resultado()
  if not self.game.can_advance then return end
  if self.comunales_reveladas < CARTAS_COMUNALES then
    self:revelar_siguiente()
  else
    self:terminar_mano()
  end
end

function Poker:actualizar_botones()
  local width, height = love.graphics.getDimensions()
  local definiciones = {}
  if self.input_lock > 0 then
    definiciones = {}
  elseif self.game:is_human_turn() then
    local por_pagar = self.game:get_amount_to_call(self.game.players[1])
    definiciones = {
      { label = "FOLD", action = function() self:accion_jugador("fold") end, color = { 0.70, 0.16, 0.18 } },
      { label = por_pagar > 0 and "CALL" or "CHECK", action = function()
          self:accion_jugador(por_pagar > 0 and "call" or "check")
        end, color = { 0.13, 0.46, 0.82 } },
      { label = "RAISE", action = function() self:accion_jugador("raise") end, color = { 0.82, 0.48, 0.12 } },
      { label = "ALL-IN", action = function()
          self:accion_jugador("allin")
        end, color = { 0.54, 0.19, 0.75 } },
    }
  elseif self.game.can_advance then
    definiciones = {
      { label = self.comunales_reveladas < CARTAS_COMUNALES and "NEXT" or "SHOWDOWN",
        action = function() self:avanzar_o_mostrar_resultado() end,
        color = { 0.13, 0.68, 0.43 } },
    }
  elseif self.game.status == "showdown" then
    definiciones = {
      { label = "NEW HAND", action = function() self:iniciar_mano() end, color = { 0.13, 0.68, 0.43 } },
    }
  end

  for index, definition in ipairs(definiciones) do
    local count, width_each = #definiciones, 150
    local gap = 16
    local start = width / 2 - ((width_each + gap) * count - gap) / 2 + width_each / 2
    local previous = self.botones[index] or { scale = 1, press = 0, flash = 0 }
    self.botones[index] = {
      x = start + (index - 1) * (width_each + gap), y = height * 0.94,
      w = width_each, h = 52, label = definition.label, action = definition.action,
      color = definition.color, scale = previous.scale or 1,
      press = previous.press or 0, flash = previous.flash or 0,
    }
  end
  for index = #definiciones + 1, #self.botones do self.botones[index] = nil end
end

function Poker:emitir_particulas(x, y, color)
  for _ = 1, 18 do
    local angulo = math.random() * math.pi * 2
    local velocidad = 70 + math.random() * 150
    self.particulas[#self.particulas + 1] = {
      x = x, y = y, vx = math.cos(angulo) * velocidad, vy = math.sin(angulo) * velocidad,
      life = 0.35 + math.random() * 0.25, max_life = 0.6, size = 2 + math.random() * 4,
      color = color,
    }
  end
end

function Poker:keypressed(key)
  if key == "escape" then
    self.machine:switch(nil)
  end
end

function Poker:mousepressed(x, y, button)
  if button ~= 1 or self.input_lock > 0 then return end
  for _, boton in ipairs(self.botones) do
    if punto_en_rect(x, y, boton) then
      boton.press, boton.flash = 0.13, 0.20
      self:emitir_particulas(x, y, boton.color)
      boton.action()
      return
    end
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

  local nuevas = siguiente - self.comunales_reveladas
  for indice = self.comunales_reveladas + 1, siguiente do
    mostrar_carta(self.comunales.cards[indice])
  end
  self.comunales_reveladas = siguiente

  self.holdem_board = {}
  for indice = 1, self.comunales_reveladas do
    self.holdem_board[#self.holdem_board + 1] = convertir_carta(self.comunales.cards[indice])
  end

  local fase = siguiente == 3 and "flop" or siguiente == 4 and "turn" or "river"
  self.game:advance_phase(self.holdem_board, fase)
  self.input_lock = (nuevas - 1) * DEAL_DELAY + 0.52
end

function Poker:update(dt)
  self.input_lock = math.max(0, (self.input_lock or 0) - dt)
  self.baraja:update(dt)
  for _, mano in ipairs(self.jugadores) do
    mano:update(dt)
  end
  self.comunales:update(dt)

  self.visual_pot = lerp(self.visual_pot, self.game.pot, math.min(1, dt * 12))
  self:actualizar_botones()
  local mouse_x, mouse_y = love.mouse.getPosition()
  for _, boton in ipairs(self.botones) do
    local hover = punto_en_rect(mouse_x, mouse_y, boton)
    boton.press = math.max(0, boton.press - dt)
    boton.flash = math.max(0, boton.flash - dt)
    local target = hover and 1.08 or 1
    boton.scale = lerp(boton.scale, target, math.min(1, dt * 16))
  end
  for index = #self.particulas, 1, -1 do
    local particula = self.particulas[index]
    particula.life = particula.life - dt
    particula.x, particula.y = particula.x + particula.vx * dt, particula.y + particula.vy * dt
    particula.vx, particula.vy = particula.vx * (1 - dt * 4), particula.vy * (1 - dt * 4)
    if particula.life <= 0 then table.remove(self.particulas, index) end
  end
end

local function dibujar_comunales(estado, x, y)
  estado.comunales:draw_at(x, y, 340, { scale = 0.94 })
end

local function dibujar_jugadores(estado, width, height)
  local layout = mesa_layout(width, height)
  for indice, asiento in ipairs(layout.players) do
    local player = estado.game.players[indice]
    -- Un halo silencioso dirige el ojo al turno sin llenar la mesa de texto.
    if estado.game.current_player_index == indice then
      love.graphics.setColor(0.18, 0.86, 1, 0.22 + math.sin(love.timer.getTime() * 5) * 0.07)
      love.graphics.ellipse("fill", asiento.x, asiento.y + 42, 98 * asiento.scale, 34 * asiento.scale)
    elseif player.payout and player.payout > 0 then
      love.graphics.setColor(0.22, 1, 0.48, 0.28 + math.sin(love.timer.getTime() * 4) * 0.08)
      love.graphics.ellipse("fill", asiento.x, asiento.y + 42, 106 * asiento.scale, 40 * asiento.scale)
    elseif player.folded then
      love.graphics.setColor(0, 0, 0, 0.30)
      love.graphics.ellipse("fill", asiento.x, asiento.y + 42, 84 * asiento.scale, 26 * asiento.scale)
    end
    love.graphics.setColor(1, 1, 1, player.folded and 0.35 or 1)
    estado.jugadores[indice]:draw_at(asiento.x, asiento.y, asiento.width, asiento)
  end
  love.graphics.setColor(1, 1, 1, 1)
end

local function dibujar_particulas(estado)
  for _, particula in ipairs(estado.particulas) do
    local alpha = math.max(0, particula.life / particula.max_life)
    love.graphics.setColor(particula.color[1], particula.color[2], particula.color[3], alpha)
    love.graphics.circle("fill", particula.x, particula.y, particula.size * alpha)
  end
end

local function dibujar_botones(estado, width, height)
  love.graphics.setFont(estado.fuente_boton)
  for _, boton in ipairs(estado.botones) do
    local mouse_x, mouse_y = love.mouse.getPosition()
    local hover = punto_en_rect(mouse_x, mouse_y, boton)
    local press = boton.press > 0 and 0.90 or 1
    local scale = boton.scale * press
    local width_scaled, height_scaled = boton.w * scale, boton.h * scale
    local flash = boton.flash / 0.20
    love.graphics.setColor(0, 0, 0, 0.33)
    love.graphics.rectangle("fill", boton.x - width_scaled / 2 + 3, boton.y - height_scaled / 2 + 5, width_scaled, height_scaled, 14, 14)
    love.graphics.setColor(
      math.min(1, boton.color[1] + flash * 0.45),
      math.min(1, boton.color[2] + flash * 0.45),
      math.min(1, boton.color[3] + flash * 0.45),
      1
    )
    love.graphics.rectangle("fill", boton.x - width_scaled / 2, boton.y - height_scaled / 2, width_scaled, height_scaled, 14, 14)
    if hover then
      love.graphics.setColor(1, 1, 1, 0.32)
      love.graphics.setLineWidth(2)
      love.graphics.rectangle("line", boton.x - width_scaled / 2 - 3, boton.y - height_scaled / 2 - 3, width_scaled + 6, height_scaled + 6, 16, 16)
    end
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(boton.label, boton.x - width_scaled / 2, boton.y - 12, width_scaled, "center")
  end
end

local function dibujar_ui(estado, width, height)
  local jugador = estado.game.players[1]
  love.graphics.setFont(estado.fuente_ui)
  love.graphics.setColor(1, 1, 1, 0.93)
  love.graphics.printf("POT  " .. math.floor(estado.visual_pot + 0.5), width * 0.41, height * 0.55, width * 0.18, "center")
  love.graphics.setColor(1, 1, 1, 0.72)
  love.graphics.printf("STACK  " .. jugador.stack, width * 0.41, height * 0.59, width * 0.18, "center")

  for index, player in ipairs(estado.game.players) do
    local seat = mesa_layout(width, height).players[index]
    local status = player.folded and "FOLDED" or player.all_in and "ALL-IN" or ""
    if status ~= "" then
      if player.folded then
        love.graphics.setColor(1, 0.35, 0.35, 0.9)
      else
        love.graphics.setColor(1, 0.78, 0.2, 0.95)
      end
      love.graphics.printf(status, seat.x - 60, seat.y - 72 * seat.scale, 120, "center")
    end
  end
  dibujar_botones(estado, width, height)
  dibujar_particulas(estado)
  love.graphics.setColor(1, 1, 1, 1)
end

local function dibujar_escena(estado, width, height)
  local layout = mesa_layout(width, height)

  estado.baraja:set_position(layout.deck.x, layout.deck.y, layout.deck.scale)
  estado.baraja:draw_pile()
  dibujar_comunales(estado, layout.community.x, layout.community.y)
  dibujar_jugadores(estado, width, height)
  dibujar_ui(estado, width, height)
end

function Poker:draw()
  local width, height = love.graphics.getDimensions()
  local x, y, escala = layout_fondo(width, height)

  love.graphics.push("all")
  love.graphics.draw(FONDO, x, y, 0, escala, escala)
  dibujar_escena(self, width, height)
  love.graphics.pop()
end

function Poker:leave()
  self.context, self.machine = nil, nil
  self.cartas, self.baraja, self.jugadores, self.comunales = nil, nil, nil, nil
  self.bots, self.holdem_board, self.game = nil, nil, nil
  self.comunales_reveladas, self.input_lock = nil, nil
end

return Poker
