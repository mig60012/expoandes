local Poker = {}

local Cards = require("lib/cards")
local Bot = require("src/systems/poker_bot")
local PokerGame = require("src/systems/poker_game")
local HoldemCard = require("holdem.card")
local Analysis = require("holdem.analysis")
local Audio = require("src/systems/audio")
local Mando = require("src/systems/mando")

local ATLAS = "assets/casino/poker/cards_atlas.png"
local LIGHT = love.graphics.newImage("assets/casino/poker/light_poker.png")
local FONDO = love.graphics.newImage("assets/casino/poker/fondo_poker_2.png")
local MESA = love.graphics.newImage("assets/casino/poker/Juegos.png")
local FILTRO_ADD_PRIMERO = love.graphics.newImage("assets/casino/filtro_add_primero.png")
local FILTRO_MULTIPLY = love.graphics.newImage("assets/casino/filtro_multiply_mitad.png")
local FILTRO_ADD_ULTIMO = love.graphics.newImage("assets/casino/filtro_add_ultimo.png")
local CLASIFICACION = love.graphics.newImage("assets/casino/poker/clasificacion_poker.png")

local CARTAS_POR_JUGADOR = 2
local CARTAS_COMUNALES = 5
local DINERO_INICIAL_BOT = 1000
local APUESTA_MINIMA = 10
local DEAL_DELAY = 0.085
local FICHAS_POR_MILLON = 100
local COLORES_FICHAS = {
  { base = { 0.82, 0.12, 0.15 }, detalle = { 1, 0.76, 0.72 } },
  { base = { 0.10, 0.58, 0.25 }, detalle = { 0.72, 1, 0.77 } },
  { base = { 0.94, 0.70, 0.08 }, detalle = { 1, 0.96, 0.68 } },
  { base = { 0.12, 0.12, 0.15 }, detalle = { 0.78, 0.78, 0.82 } },
  { base = { 0.53, 0.22, 0.75 }, detalle = { 0.91, 0.77, 1 } },
}
-- Cada vez que te sientas en la mesa tienes derecho a jugar este numero de manos.
-- Al terminar la ultima se te pide levantarte y la sesion cuenta como UNA jugada
-- del dia en el casino.
local MANOS_POR_SESION = 3

local SUIT_BY_NAME = {
  spades = 1,
  hearts = 2,
  diamonds = 3,
  clubs = 4,
}

-- lib/cards.lua llama a card.sound:setPitch/stop/play justo cuando una carta
-- gira y se ve de canto (la mitad de la animacion). Este objeto cumple esa
-- interfaz y reproduce el sonido de volteo con el sistema de audio del juego.
local SONIDO_VOLTEO = {
  setPitch = function() end,
  stop = function() end,
  play = function() Audio.reproducir("card_flip") end,
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
    Bot:new("Bot 4", DINERO_INICIAL_BOT, "Fish"),
  }
end

local function lerp(a, b, t)
  return a + (b - a) * t
end

local function mesa_layout(width, height)
  return {
    -- La mesa grande de main deja que las cartas sean protagonistas. Las
    -- estadísticas y el botón de manos viven fuera de esta zona.
    deck = { x = width * 0.73, y = height * 0.42, scale = 1.30 },
    community = { x = width / 2, y = height * 0.46, width = 510, scale = 1.42 },
    players = {
      { x = width / 2,    y = height * 0.8,  width = 230, scale = 1.92 },
      { x = width * 0.13, y = height * 0.53, width = 195, scale = 1.20, shear = -0.5 },
      { x = width / 2,    y = height * 0.2,  width = 180, scale = 0.90 },
      { x = width * 0.87, y = height * 0.53, width = 195, scale = 1.20, shear = 0.5 },
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

function Poker:enter(context, machine, opciones)
  self.context, self.machine = context, machine
  self.opciones = opciones or {}
  math.randomseed(os.time() + math.floor(love.timer.getTime() * 1000000))
  math.random()
  math.random()
  math.random()
  self.jugada_registrada = false
  self.fuente_ui = love.graphics.newFont("assets/AntonSC-Regular.ttf", 20)
  self.fuente_boton = love.graphics.newFont("assets/AntonSC-Regular.ttf", 22)
  self.multiply_shader = crear_multiply_shader()
  self.botones, self.particulas = {}, {}
  self.buyin_min = self.opciones.minimo or 3
  self.buyin_max = math.floor(context.economy:get_money())
  self.buyin_value = math.max(self.buyin_min, math.min(self.buyin_max, self.buyin_min))
  self.buyin_mode, self.dragging_buyin = true, false
  self.buyin_spent, self.cashed_out, self.cashout_money = nil, false, nil
  self.buyin_error = nil
  self.chips_per_million = (context.rules and context.rules.poker_chips_per_million) or FICHAS_POR_MILLON
  self.input_lock = 0
  self.mostrar_clasificacion = false
  self:actualizar_botones()
end

function Poker:crear_sesion(stack)
  self.cartas = Cards.new({ atlas_path = ATLAS })
  self.bots = crear_bots()
  self.game = PokerGame:new({
    { name = "Jugador 1",       stack = stack },
    { name = self.bots[1].name, controller = self.bots[1] },
    { name = self.bots[2].name, controller = self.bots[2] },
    { name = self.bots[3].name, controller = self.bots[3] },
  }, {
    small_blind = 5,
    big_blind = 10,
    min_raise = APUESTA_MINIMA,
    dealer_index = 1,
    max_hands = MANOS_POR_SESION,
    auto_bots = false,
    evaluator = function(hole_cards, board_cards)
      return Analysis.evaluate(hole_cards, board_cards)
    end,
  })
  self.table_chips, self.pot_chips, self.folded_visuals = {}, {}, {}
  self.visual_pot = 0
  self.raise_value, self.raise_min, self.raise_max = nil, nil, nil
  self.dragging_raise, self.raise_mode, self.session_finished = false, false, false
  self.out_of_chips, self.returning_to_casino = false, false
  self.bankrupt_notice, self.bankrupt_notice_time = false, 0
  self.mostrar_clasificacion = false
  self:iniciar_mano()
end

function Poker:confirmar_compra()
  if not self.buyin_mode then return false end
  local amount = math.max(self.buyin_min, math.min(self.buyin_max, self.buyin_value))
  if not self.context.economy:spend_money(amount) then
    self.buyin_error = "No tienes suficiente dinero para esa compra."
    return false
  end
  self.buyin_value, self.buyin_spent = amount, amount
  self.buyin_error = nil
  self.buyin_mode, self.dragging_buyin = false, false
  self:crear_sesion(amount * self.chips_per_million)
  return true
end

function Poker:liquidar_fichas()
  if self.cashed_out or not self.buyin_spent then return 0 end
  self.cashed_out = true
  local chips = self.game and self.game.players[1].stack or 0
  local money = chips / self.chips_per_million
  self.context.economy:add_money(money)
  Audio.reproducir("coins")
  self.cashout_money = money
  return money
end

function Poker:iniciar_mano()
  Audio.reproducir("card_shuffle")
  if self.game.hand_number > 0 then self.game:rotate_dealer() end
  self.baraja = self.cartas:create_deck()
  for _, carta in ipairs(self.baraja.cards_list) do
    carta.sound = SONIDO_VOLTEO
  end
  self.baraja:shuffle(5)
  self.baraja:exite(0.55)
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
  self.comunales_reveladas, self.comunales_visibles = 0, 3
  self.holdem_board = {}
  self.bot_wait, self.bot_index, self.action_fx = nil, nil, nil
  self.table_chips, self.pot_chips, self.folded_visuals = {}, {}, {}
  self.round_chips_collected, self.collecting_chips = false, false
  self.showdown_time = nil

  for indice, bot in ipairs(self.bots) do
    if indice == 1 then
      bot:setPersonality(math.random() < 0.5 and "Fish" or "Maniac")
    end
    local mano = convertir_mano(self.jugadores[indice + 1])
    bot:receiveCards(mano[1], mano[2])
  end

  local hole_cards = {}
  for _, mano in ipairs(self.jugadores) do
    hole_cards[#hole_cards + 1] = convertir_mano(mano)
  end
  self.game:start_hand(hole_cards)
  self.raise_value = nil
  self.raise_mode, self.dragging_raise = false, false
  self:crear_fichas_apuesta(self.game.small_blind_index, self.game.players[self.game.small_blind_index].round_bet)
  self:crear_fichas_apuesta(self.game.big_blind_index, self.game.players[self.game.big_blind_index].round_bet)
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
  for indice = 1, 3 do
    local carta = self.comunales.cards[indice]
    local x, y = destino_carta(layout.community, indice, CARTAS_COMUNALES)
    ocultar_carta(carta)
    orden = orden + 1
    carta:deal_from(layout.deck.x, layout.deck.y, x, y, {
      delay = orden * DEAL_DELAY,
      duration = 0.46,
      on_arrive = function() Audio.reproducir("card_flip") end,
    })
  end
  self.input_lock = orden * DEAL_DELAY + 0.34
end

function Poker:indice_jugador(player)
  for indice, candidato in ipairs(self.game.players) do
    if candidato == player then return indice end
  end
end

function Poker:crear_fichas_apuesta(indice, amount)
  if amount <= 0 then return end
  local width, height = love.graphics.getDimensions()
  local seat = mesa_layout(width, height).players[indice]
  -- Las ciegas se colocan alrededor del asiento, nunca encima de las cartas.
  local anchor_x, anchor_y = seat.x, seat.y + 92 * seat.scale
  if indice == 2 then anchor_x, anchor_y = seat.x + 112 * seat.scale, seat.y + 8 end
  if indice == 4 then anchor_x, anchor_y = seat.x - 112 * seat.scale, seat.y + 8 end
  if indice == 3 then anchor_x, anchor_y = seat.x, seat.y - 66 * seat.scale end
  local cantidad = math.min(8, math.max(1, math.ceil(amount / APUESTA_MINIMA)))
  -- Cada pila nueva representa fichas que llegan a la mesa (incluidas las ciegas).
  Audio.reproducir("chip_place")
  for numero = 1, cantidad do
    self.table_chips[#self.table_chips + 1] = {
      owner = indice,
      x = anchor_x + (numero - (cantidad + 1) / 2) * 14,
      y = anchor_y - numero * 3,
      rotation = (math.random() - 0.5) * 0.24,
      value = amount / cantidad,
      color_index = (#self.table_chips % #COLORES_FICHAS) + 1,
      state = "table",
    }
  end
end

function Poker:deslizar_fold(indice)
  local width, height = love.graphics.getDimensions()
  local seat = mesa_layout(width, height).players[indice]
  local direction = seat.x < width / 2 and -1 or 1
  if indice == 3 then direction = 0 end
  for carta_indice, carta in ipairs(self.jugadores[indice].cards) do
    local from_x, from_y = destino_carta(seat, carta_indice, CARTAS_POR_JUGADOR)
    local to_x = seat.x + direction * width * 0.24 + (carta_indice - 1) * 18
    local to_y = seat.y - height * 0.12 + carta_indice * 10
    carta:deal_from(from_x, from_y, to_x, to_y, { duration = 1.25, rotation = direction * 0.32 })
    self.folded_visuals[#self.folded_visuals + 1] = { card = carta, x = to_x, y = to_y, scale = seat.scale * 0.72 }
  end
end

function Poker:registrar_accion(player, action)
  local indice = self:indice_jugador(player)
  if not indice or not action then return end
  self:crear_fichas_apuesta(indice, action.amount or 0)
  -- El sonido de fichas se reproduce en crear_fichas_apuesta().
  if action.action == "fold" then self:deslizar_fold(indice) end
end

function Poker:mover_fichas_al_pozo()
  if self.round_chips_collected then return end
  self.round_chips_collected, self.collecting_chips = true, true
  if #self.table_chips > 0 then Audio.reproducir("chip_place") end
  local width, height = love.graphics.getDimensions()
  for indice, ficha in ipairs(self.table_chips) do
    ficha.state, ficha.time, ficha.duration = "moving", 0, 0.56 + (indice % 3) * 0.08
    ficha.from_x, ficha.from_y = ficha.x, ficha.y
    ficha.to_x = width / 2 + (math.random() - 0.5) * 36
    ficha.to_y = height * 0.60 + (math.random() - 0.5) * 14
  end
end

function Poker:accion_jugador(action)
  if not self.game:is_human_turn() then
    return
  end

  local jugador = self.game.players[1]
  local amount_to_call = self.game:get_amount_to_call(jugador)
  local amount = 0

  if action == "raise" and self.game.raise_used then return end

  if action == "call" then
    amount = math.min(amount_to_call, jugador.stack)
  elseif action == "allin" then
    action = (not self.game.raise_used and jugador.stack > amount_to_call) and "raise" or "call"
    amount = action == "raise" and jugador.stack or math.min(amount_to_call, jugador.stack)
  elseif action == "raise" then
    if self.game.raise_used then
      action = amount_to_call > 0 and "call" or "check"
      amount = math.min(amount_to_call, jugador.stack)
    elseif jugador.stack <= amount_to_call then
      action = amount_to_call > 0 and "call" or "check"
      amount = math.min(amount_to_call, jugador.stack)
    else
      local minimo = self.game:get_raise_amount(jugador)
      amount = math.max(minimo, math.min(self.raise_value or minimo, jugador.stack))
    end
  end

  local ok = self.game:apply_action(1, {
    action = action,
    amount = amount,
  })
  self.raise_value = nil
  self.raise_mode, self.dragging_raise = false, false
  if ok then self:registrar_accion(jugador, jugador.last_action) end
  if ok and self.game.status == "showdown" then
    self:terminar_mano()
  end
end

function Poker:terminar_mano()
  self:mover_fichas_al_pozo()
  self.game:finish_hand()
  local se_revelan_cartas = false
  for indice, mano in ipairs(self.jugadores) do
    if self.game.players[indice].folded then
      preparar_mano(mano, 0)
    else
      -- Las cartas de los rivales pasan de boca abajo a boca arriba.
      if indice > 1 and not mano.cards[1].visible then se_revelan_cartas = true end
      preparar_mano(mano, CARTAS_POR_JUGADOR)
    end
  end
  if se_revelan_cartas then Audio.reproducir("card_flip") end
  self.showdown_time = 0
  self.out_of_chips = self.game.players[1].stack <= 0
  self.session_finished = self.out_of_chips or self.game.hand_number >= MANOS_POR_SESION
  self.returning_to_casino = self.out_of_chips
  self:registrar_jugada_si_termino()
end

-- Terminar las manos de la sesion cuenta como una jugada del dia (igual que cada
-- giro en la ruleta). Se avisa al casino una sola vez por sesion, en cuanto acaba
-- la ultima mano, aunque despues el jugador salga con Esc en vez de con LEAVE.
function Poker:registrar_jugada_si_termino()
  if not self.session_finished or self.jugada_registrada then return end
  self.jugada_registrada = true
  self:liquidar_fichas()
  if self.opciones.al_jugar then self.opciones.al_jugar(0) end
end

function Poker:listo_para_salir()
  return self.session_finished and not self.collecting_chips and not self.bankrupt_notice
end

function Poker:salir()
  if self.bankrupt_notice then
    self.machine:switch(nil)
    return true
  end
  if not self.jugada_registrada or not self:listo_para_salir() then return false end
  self.machine:switch(nil)
  return true
end

function Poker:preparar_turno_bot()
  local player = self.game:get_current_player()
  if self.input_lock > 0 or self.bot_wait or self.game.status ~= "betting" then
    return
  end
  if player and player.controller then
    self.bot_wait = 1 + math.random() * 2
    self.bot_index = self.game.current_player_index
  end
end

function Poker:ejecutar_turno_bot()
  self.bot_wait, self.bot_index, self.action_fx = nil, nil, nil
  local player = self.game:get_current_player()
  if not player or not player.controller then return end

  self.game:act_current_bot()
  local action = player.last_action
  if action then
    self:registrar_accion(player, action)
    if action.action ~= "fold" then
      self.action_fx = {
        player = player,
        action = action.action,
        amount = action.amount,
        time = 0,
        duration = 0.72,
      }
    end
    self.input_lock = 0.42
  end
  if self.game.status == "showdown" then
    self:terminar_mano()
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
  if self.buyin_mode then
    definiciones = {
      { label = "CANCELAR", action = function() self.machine:switch(nil) end, color = { 0.22, 0.20, 0.20 } },
      { label = "CANJEAR", action = function() self:confirmar_compra() end, color = { 0.47, 0.32, 0.14 } },
    }
  elseif self.bankrupt_notice then
    definiciones = {}
  elseif self.input_lock > 0 then
    definiciones = {}
  elseif self.game:is_human_turn() and self.raise_mode then
    definiciones = {
      { label = "CANCELAR", action = function() self.raise_mode = false end, color = { 0.22, 0.20, 0.20 } },
      { label = "APOSTAR", action = function() self:accion_jugador("raise") end, color = { 0.47, 0.32, 0.14 } },
    }
  elseif self.game:is_human_turn() then
    local por_pagar = self.game:get_amount_to_call(self.game.players[1])
    local jugador = self.game.players[1]
    local call_amount = math.min(por_pagar, jugador.stack)
    local short_all_in = por_pagar > jugador.stack
    local minimo_raise = por_pagar + self.game.min_raise
    local puede_raise = not self.game.raise_used and jugador.stack >= minimo_raise
    self.raise_min, self.raise_max = minimo_raise, jugador.stack
    if puede_raise then
      self.raise_value = math.max(minimo_raise, math.min(self.raise_value or minimo_raise, jugador.stack))
    else
      self.raise_value = nil
    end
    definiciones = {
      { label = "FOLD", action = function() self:accion_jugador("fold") end, color = { 0.34, 0.10, 0.12 } },
      {
        label = por_pagar > 0 and ((short_all_in and "CALL ALL-IN  " or "CALL  ") .. call_amount) or "CHECK",
        action = function() self:accion_jugador(por_pagar > 0 and "call" or "check") end,
        color = { 0.19, 0.29, 0.34 },
      },
    }
    if puede_raise then
      definiciones[#definiciones + 1] = {
        label = "RAISE  " .. (self.raise_value or minimo_raise),
        action = function()
          self.raise_value = minimo_raise
          self.raise_mode = true
        end,
        color = { 0.47, 0.32, 0.14 },
      }
      definiciones[#definiciones + 1] = {
        label = "ALL-IN  " .. jugador.stack,
        action = function() self:accion_jugador("allin") end,
        color = { 0.28, 0.15, 0.32 },
      }
    end
  elseif self.game.can_advance and not self.collecting_chips then
    definiciones = {
      {
        label = self.comunales_reveladas < CARTAS_COMUNALES and "SIGUIENTE" or "MOSTRAR",
        action = function() self:avanzar_o_mostrar_resultado() end,
        color = { 0.22, 0.35, 0.28 },
      },
    }
  elseif self.game.status == "showdown" and not self.collecting_chips and not self.session_finished then
    definiciones = {
      { label = "OTRA RONDA", action = function() self:iniciar_mano() end, color = { 0.10, 0.58, 0.28 } },
    }
  elseif self.game.status == "showdown" and not self.collecting_chips and self.session_finished then
    definiciones = {
      { label = "LEAVE", action = function() self:salir() end, color = { 0.30, 0.12, 0.14 } },
    }
  end

  for index, definition in ipairs(definiciones) do
    local count, width_each = #definiciones, 150
    local gap = 16
    local start = width / 2 - ((width_each + gap) * count - gap) / 2 + width_each / 2
    local previous = self.botones[index] or { scale = 1, press = 0, flash = 0 }
    self.botones[index] = {
      x = start + (index - 1) * (width_each + gap),
      y = height * 0.94,
      w = width_each,
      h = 52,
      label = definition.label,
      action = definition.action,
      color = definition.color,
      scale = previous.scale or 1,
      press = previous.press or 0,
      flash = previous.flash or 0,
    }
  end
  for index = #definiciones + 1, #self.botones do self.botones[index] = nil end
end

function Poker:emitir_particulas(x, y, color)
  -- Polvo y ceniza: respuesta táctil sin el confeti propio de una interfaz feliz.
  for _ = 1, 10 do
    local angulo = math.pi + (math.random() - 0.5) * 1.3
    local velocidad = 22 + math.random() * 58
    self.particulas[#self.particulas + 1] = {
      x = x,
      y = y,
      vx = math.cos(angulo) * velocidad,
      vy = math.sin(angulo) * velocidad,
      life = 0.45 + math.random() * 0.35,
      max_life = 0.8,
      size = 1 + math.random() * 2,
      color = color,
    }
  end
end

function Poker:actualizar_slider_desde_mouse(x)
  local slider = self.slider
  if not slider then return end
  local progreso = math.max(0, math.min(1, (x - (slider.x - slider.w / 2)) / slider.w))
  if self.buyin_mode then
    local valor = self.buyin_min + (self.buyin_max - self.buyin_min) * progreso
    self.buyin_value = math.floor(valor + 0.5)
    self.buyin_error = nil
    return
  end
  if not self.raise_min or not self.raise_max or self.raise_max < self.raise_min then return end
  local valor = self.raise_min + (self.raise_max - self.raise_min) * progreso
  self.raise_value = math.floor(valor / 5 + 0.5) * 5
  self.raise_value = math.max(self.raise_min, math.min(self.raise_max, self.raise_value))
end

function Poker:keypressed(key)
  if key ~= "escape" then return end
  if self.buyin_mode then
    self.machine:switch(nil)
  elseif self.mostrar_clasificacion then
    self.mostrar_clasificacion = false
  else
    self:salir()
  end
end

function Poker:mousepressed(x, y, button)
  if button ~= 1 then return end
  if not self.buyin_mode then
    local width = love.graphics.getWidth()
    local ranking = { x = width / 2 - 110, y = 18, w = 220, h = 42 }
    if x >= ranking.x and x <= ranking.x + ranking.w
        and y >= ranking.y and y <= ranking.y + ranking.h then
      self.mostrar_clasificacion = not self.mostrar_clasificacion
      return
    end
    if self.mostrar_clasificacion then return end
  end
  if self.input_lock > 0 then return end
  if self.slider and punto_en_rect(x, y, self.slider) and (self.buyin_mode or self.raise_min) then
    if self.buyin_mode then self.dragging_buyin = true else self.dragging_raise = true end
    self:actualizar_slider_desde_mouse(x)
    return
  end
  for _, boton in ipairs(self.botones) do
    if punto_en_rect(x, y, boton) then
      boton.press, boton.flash = 0.13, 0.20
      self:emitir_particulas(x, y, boton.color)
      boton.action()
      return
    end
  end
end

function Poker:mousemoved(x, y)
  if self.dragging_raise or self.dragging_buyin then self:actualizar_slider_desde_mouse(x) end
end

function Poker:mousereleased(_, _, button)
  if button == 1 then self.dragging_raise, self.dragging_buyin = false, false end
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
  self.comunales_visibles = siguiente
  if siguiente == 3 then
    for indice = 1, siguiente do
      mostrar_carta(self.comunales.cards[indice])
    end
  else
    local width, height = love.graphics.getDimensions()
    local layout = mesa_layout(width, height)
    local indice = siguiente
    local carta = self.comunales.cards[indice]
    local destino_x, destino_y = destino_carta(layout.community, indice, CARTAS_COMUNALES)
    carta:deal_from(layout.deck.x, layout.deck.y, destino_x, destino_y, {
      duration = 0.46,
      on_arrive = function(carta_repartida)
        mostrar_carta(carta_repartida)
        Audio.reproducir("card_flip")
      end,
    })
  end
  self.comunales_reveladas = siguiente

  self.holdem_board = {}
  for indice = 1, self.comunales_reveladas do
    self.holdem_board[#self.holdem_board + 1] = convertir_carta(self.comunales.cards[indice])
  end

  local fase = siguiente == 3 and "flop" or siguiente == 4 and "turn" or "river"
  self.game:advance_phase(self.holdem_board, fase)
  self.round_chips_collected, self.collecting_chips = false, false
  self.input_lock = nuevas > 1 and (nuevas - 1) * DEAL_DELAY + 0.75 or 0.62
end

function Poker:update(dt)
  if self.buyin_mode then
    self:actualizar_botones()
    local mouse_x, mouse_y = love.mouse.getPosition()
    for _, boton in ipairs(self.botones) do
      local hover = punto_en_rect(mouse_x, mouse_y, boton)
      boton.press = math.max(0, boton.press - dt)
      boton.flash = math.max(0, boton.flash - dt)
      boton.scale = lerp(boton.scale, hover and 1.08 or 1, math.min(1, dt * 16))
    end
    return
  end
  self.input_lock = math.max(0, (self.input_lock or 0) - dt)
  self:preparar_turno_bot()
  if self.bot_wait then
    self.bot_wait = self.bot_wait - dt
    if self.bot_wait <= 0 then self:ejecutar_turno_bot() end
  end
  self.baraja:update(dt)
  for _, mano in ipairs(self.jugadores) do mano:update(dt) end
  self.comunales:update(dt)

  if self.game.can_advance then self:mover_fichas_al_pozo() end
  local moving_chips = false
  for indice = #self.table_chips, 1, -1 do
    local ficha = self.table_chips[indice]
    if ficha.state == "moving" then
      moving_chips = true
      ficha.time = ficha.time + dt
      local t = math.min(1, ficha.time / ficha.duration)
      local eased = t < 0.5 and 4 * t * t * t or 1 - (-2 * t + 2) ^ 3 / 2
      ficha.x = lerp(ficha.from_x, ficha.to_x, eased)
      ficha.y = lerp(ficha.from_y, ficha.to_y, eased) - math.sin(t * math.pi) * 12
      if t >= 1 then
        ficha.state = "pot"
        self.pot_chips[#self.pot_chips + 1] = ficha
        table.remove(self.table_chips, indice)
      end
    end
  end
  if self.collecting_chips and not moving_chips then self.collecting_chips = false end

  self.visual_pot = lerp(self.visual_pot, self.game.pot, math.min(1, dt * 12))
  if self.action_fx then
    self.action_fx.time = self.action_fx.time + dt
    if self.action_fx.time >= self.action_fx.duration then self.action_fx = nil end
  end
  if self.showdown_time then self.showdown_time = self.showdown_time + dt end
  self:actualizar_botones()
  local mouse_x, mouse_y = love.mouse.getPosition()
  for _, boton in ipairs(self.botones) do
    local hover = punto_en_rect(mouse_x, mouse_y, boton)
    boton.press = math.max(0, boton.press - dt)
    boton.flash = math.max(0, boton.flash - dt)
    boton.scale = lerp(boton.scale, hover and 1.08 or 1, math.min(1, dt * 16))
  end
  for index = #self.particulas, 1, -1 do
    local particula = self.particulas[index]
    particula.life = particula.life - dt
    particula.x, particula.y = particula.x + particula.vx * dt, particula.y + particula.vy * dt
    particula.vx, particula.vy = particula.vx * (1 - dt * 2), particula.vy + 9 * dt
    if particula.life <= 0 then table.remove(self.particulas, index) end
  end
  if self.returning_to_casino and not self.collecting_chips then
    self.returning_to_casino = false
    self.bankrupt_notice, self.bankrupt_notice_time = true, 0
  end
  if self.bankrupt_notice then
    self.bankrupt_notice_time = self.bankrupt_notice_time + dt
    if self.bankrupt_notice_time >= 2.5 then
      self:salir()
      return
    end
  end
end

local function dibujar_comunales(estado, layout)
  for indice = 1, estado.comunales_visibles do
    local x, y = destino_carta(layout.community, indice, CARTAS_COMUNALES)
    estado.comunales.cards[indice]:draw_at(x, y, { scale = layout.community.scale, shadow = false })
  end
end

local function dibujar_ficha(ficha, pot)
  local colores = COLORES_FICHAS[ficha.color_index or 1]
  love.graphics.setColor(0, 0, 0, 0.5)
  love.graphics.ellipse("fill", ficha.x + 2, ficha.y + 4, 13, 6)
  love.graphics.setColor(colores.base[1], colores.base[2], colores.base[3], pot and 1 or 0.96)
  love.graphics.ellipse("fill", ficha.x, ficha.y, 13, 5.5)
  love.graphics.setColor(colores.detalle[1], colores.detalle[2], colores.detalle[3], 0.95)
  love.graphics.setLineWidth(2)
  love.graphics.ellipse("line", ficha.x, ficha.y, 9, 3.4)
  love.graphics.ellipse("fill", ficha.x, ficha.y, 3.2, 1.5)
end

local function dibujar_fichas_mesa(estado)
  for _, ficha in ipairs(estado.table_chips) do dibujar_ficha(ficha, false) end
  for _, ficha in ipairs(estado.pot_chips) do dibujar_ficha(ficha, true) end
end

local function dibujar_cruz_retirado(seat)
  love.graphics.setColor(0.38, 0.08, 0.09, 0.72)
  love.graphics.setLineWidth(5)
  love.graphics.line(seat.x - 38 * seat.scale, seat.y - 34 * seat.scale,
    seat.x + 38 * seat.scale, seat.y + 34 * seat.scale)
  love.graphics.line(seat.x + 38 * seat.scale, seat.y - 34 * seat.scale,
    seat.x - 38 * seat.scale, seat.y + 34 * seat.scale)
end

local function dibujar_marcador_posicion(game, indice, seat)
  local x, y = seat.x - 58 * seat.scale, seat.y + 42 * seat.scale
  if game.dealer_index == indice then
    love.graphics.setColor(0.56, 0.47, 0.31, 0.95)
    love.graphics.circle("fill", x, y, 13 * seat.scale)
    love.graphics.setColor(0.10, 0.08, 0.07, 0.9)
    love.graphics.setLineWidth(2)
    love.graphics.circle("line", x, y, 9 * seat.scale)
  elseif game.small_blind_index == indice then
    love.graphics.setColor(0.24, 0.29, 0.30, 0.95)
    love.graphics.circle("fill", x, y, 10 * seat.scale)
  elseif game.big_blind_index == indice then
    love.graphics.setColor(0.36, 0.22, 0.18, 0.95)
    love.graphics.circle("fill", x, y, 12 * seat.scale)
  end
end

local function dibujar_accion_volando(estado, width, height, layout)
  local fx = estado.action_fx
  if not fx then return end
  local indice
  for i, player in ipairs(estado.game.players) do
    if player == fx.player then
      indice = i
      break
    end
  end
  local seat = indice and layout.players[indice]
  if not seat then return end
  local t = math.min(1, fx.time / fx.duration)
  local eased = 1 - (1 - t) ^ 3
  local x = lerp(seat.x, width / 2, eased)
  local y = lerp(seat.y + 48, height * 0.54, eased) - math.sin(t * math.pi) * 35
  local color = fx.action == "raise" and { 0.58, 0.39, 0.17, 0.95 }
      or { 0.34, 0.37, 0.39, 0.9 }
  love.graphics.setColor(color)
  love.graphics.ellipse("fill", x, y, 15, 6)
  love.graphics.setColor(0.04, 0.04, 0.04, 0.7)
  love.graphics.ellipse("line", x, y, 11, 4)
end

local function dibujar_jugadores(estado, width, height)
  local layout = mesa_layout(width, height)
  for indice, asiento in ipairs(layout.players) do
    local player = estado.game.players[indice]
    if estado.game.current_player_index == indice then
      love.graphics.setColor(0.25, 0.48, 0.52, 0.18 + math.sin(love.timer.getTime() * 5) * 0.05)
      love.graphics.ellipse("fill", asiento.x, asiento.y + 42, 98 * asiento.scale, 34 * asiento.scale)
    elseif player.payout and player.payout > 0 then
      love.graphics.setColor(0.35, 0.48, 0.29, 0.24 + math.sin(love.timer.getTime() * 4) * 0.06)
      love.graphics.ellipse("fill", asiento.x, asiento.y + 42, 106 * asiento.scale, 40 * asiento.scale)
    elseif player.folded then
      love.graphics.setColor(0, 0, 0, 0.42)
      love.graphics.ellipse("fill", asiento.x, asiento.y + 42, 84 * asiento.scale, 26 * asiento.scale)
    end
    if not player.folded then
      love.graphics.setColor(1, 1, 1, 1)
      estado.jugadores[indice]:draw_at(asiento.x, asiento.y, asiento.width, asiento)
    end
    if player.folded then dibujar_cruz_retirado(asiento) end
    dibujar_marcador_posicion(estado.game, indice, asiento)
  end
  for _, visual in ipairs(estado.folded_visuals) do
    visual.card:draw_at(visual.x, visual.y, { scale = visual.scale, rotation = 0.36 })
  end
  dibujar_fichas_mesa(estado)
  dibujar_accion_volando(estado, width, height, layout)
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
    love.graphics.rectangle("fill", boton.x - width_scaled / 2 + 3, boton.y - height_scaled / 2 + 5, width_scaled,
      height_scaled, 14, 14)
    love.graphics.setColor(
      math.min(1, boton.color[1] + flash * 0.45),
      math.min(1, boton.color[2] + flash * 0.45),
      math.min(1, boton.color[3] + flash * 0.45),
      1
    )
    love.graphics.rectangle("fill", boton.x - width_scaled / 2, boton.y - height_scaled / 2, width_scaled, height_scaled,
      14, 14)
    if hover then
      love.graphics.setColor(1, 1, 1, 0.32)
      love.graphics.setLineWidth(2)
      love.graphics.rectangle("line", boton.x - width_scaled / 2 - 3, boton.y - height_scaled / 2 - 3, width_scaled + 6,
        height_scaled + 6, 16, 16)
    end
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(boton.label, boton.x - width_scaled / 2, boton.y - 12, width_scaled, "center")
  end
end

local function dibujar_ui(estado, width, height)
  local jugador = estado.game.players[1]
  love.graphics.setFont(estado.fuente_ui)
  love.graphics.setColor(1, 1, 1, 0.93)
  local panel = { x = 20, y = 88, w = 210, h = 112 }
  love.graphics.setColor(1, 1, 1, 0.95)
  love.graphics.printf("ESTADÍSTICAS DE LA PARTIDA", panel.x - 35,
    18 + (42 - estado.fuente_ui:getHeight()) / 2, panel.w + 70, "center")
  love.graphics.setColor(0.02, 0.025, 0.04, 0.62)
  love.graphics.rectangle("fill", panel.x, panel.y, panel.w, panel.h, 10, 10)
  love.graphics.setColor(1, 1, 1, 0.93)
  love.graphics.printf("BOTE  " .. math.floor(estado.visual_pot + 0.5), panel.x + 12, panel.y + 8, panel.w - 24,
    "center")
  love.graphics.setColor(1, 1, 1, 0.78)
  love.graphics.printf("FICHAS  " .. jugador.stack, panel.x + 12, panel.y + 32, panel.w - 24, "center")
  love.graphics.printf("APUESTA  " .. estado.game.current_bet, panel.x + 12, panel.y + 56, panel.w - 24, "center")
  love.graphics.printf("IGUALAR  " .. estado.game:get_amount_to_call(jugador), panel.x + 12, panel.y + 80, panel.w - 24,
    "center")

  if estado.input_lock <= 0 and estado.raise_mode and estado.game:is_human_turn()
      and estado.raise_min and estado.raise_max and estado.raise_max >= estado.raise_min then
    estado.slider = { x = width / 2, y = height * 0.84, w = 360, h = 40 }
    local slider = estado.slider
    local valor = estado.raise_value or estado.raise_min
    local progreso = (valor - estado.raise_min) / math.max(1, estado.raise_max - estado.raise_min)
    love.graphics.setFont(estado.fuente_ui)
    love.graphics.setColor(1, 1, 1, 0.96)
    love.graphics.printf("APUESTA: " .. math.floor(valor + 0.5), slider.x - slider.w / 2, slider.y - 38, slider.w,
      "center")
    love.graphics.setColor(0.03, 0.03, 0.03, 0.82)
    love.graphics.rectangle("fill", slider.x - slider.w / 2, slider.y - 3, slider.w, 6, 3, 3)
    love.graphics.setColor(0.40, 0.28, 0.16, 0.8)
    love.graphics.rectangle("fill", slider.x - slider.w / 2, slider.y - 3, slider.w * progreso, 6, 3, 3)
    love.graphics.setColor(0.65, 0.55, 0.38, 1)
    love.graphics.ellipse("fill", slider.x - slider.w / 2 + slider.w * progreso, slider.y, 10, 10)
  else
    estado.slider = nil
  end

  dibujar_botones(estado, width, height)
  dibujar_particulas(estado)
  love.graphics.setColor(1, 1, 1, 1)
end

local function dibujar_compra(estado, width, height)
  love.graphics.setColor(0, 0, 0, 0.78)
  love.graphics.rectangle("fill", 0, 0, width, height)
  love.graphics.setFont(estado.fuente_boton)
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.printf("CANJEAR DINERO POR FICHAS", 0, height * 0.28, width, "center")
  love.graphics.setFont(estado.fuente_ui)
  love.graphics.printf(estado.buyin_value .. " M  =  " .. estado.buyin_value * estado.chips_per_million .. " FICHAS",
    0, height * 0.38, width, "center")
  love.graphics.setColor(1, 1, 1, 0.78)
  love.graphics.printf("Saldo disponible: " .. estado.context.economy:get_money() .. " M", 0, height * 0.44, width,
    "center")
  estado.slider = { x = width / 2, y = height * 0.55, w = math.min(520, width * 0.55), h = 30 }
  local progress = (estado.buyin_value - estado.buyin_min) / math.max(1, estado.buyin_max - estado.buyin_min)
  love.graphics.setColor(0.03, 0.03, 0.03, 0.9)
  love.graphics.rectangle("fill", estado.slider.x - estado.slider.w / 2, estado.slider.y - 4, estado.slider.w, 8, 4, 4)
  love.graphics.setColor(0.40, 0.28, 0.16, 0.95)
  love.graphics.rectangle("fill", estado.slider.x - estado.slider.w / 2, estado.slider.y - 4,
    estado.slider.w * progress, 8, 4, 4)
  love.graphics.setColor(0.72, 0.60, 0.40, 1)
  love.graphics.circle("fill", estado.slider.x - estado.slider.w / 2 + estado.slider.w * progress, estado.slider.y, 12)
  if estado.buyin_error then
    love.graphics.setColor(1, 0.45, 0.40, 1)
    love.graphics.printf(estado.buyin_error, 0, height * 0.62, width, "center")
  end
  dibujar_botones(estado, width, height)
end

local function dibujar_showdown(estado, width, height, layout)
  if estado.game.status ~= "showdown" then return end
  local tiempo = math.min(1, (estado.showdown_time or 0) / 0.9)
  love.graphics.setColor(0, 0, 0, 0.72 * tiempo)
  love.graphics.rectangle("fill", 0, 0, width, height)

  -- Los focos no usan texto: el ojo sigue la única zona que permanece viva.
  love.graphics.setBlendMode("add")
  for indice, player in ipairs(estado.game.players) do
    if player.payout and player.payout > 0 then
      local seat = layout.players[indice]
      love.graphics.setColor(0.48, 0.40, 0.25, 0.12 + tiempo * 0.16)
      love.graphics.ellipse("fill", seat.x, seat.y, 150 * seat.scale, 125 * seat.scale)
      love.graphics.setColor(0.38, 0.32, 0.20, 0.10 + tiempo * 0.14)
      love.graphics.ellipse("fill", layout.community.x, layout.community.y, 280, 110)
      estado.jugadores[indice]:draw_at(seat.x, seat.y, seat.width,
        { scale = seat.scale, shear = seat.shear, shadow = false })
    end
  end
  love.graphics.setBlendMode("alpha")
  dibujar_comunales(estado, layout)
end

local function dibujar_escena(estado, width, height)
  local layout = mesa_layout(width, height)

  estado.baraja:set_position(layout.deck.x, layout.deck.y, layout.deck.scale)
  estado.baraja:draw_pile()
  dibujar_comunales(estado, layout)
  dibujar_jugadores(estado, width, height)
  dibujar_ui(estado, width, height)
  dibujar_showdown(estado, width, height, layout)
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
  love.graphics.draw(MESA, x, y, 0, escala, escala)
  if self.buyin_mode then dibujar_compra(self, width, height) else dibujar_escena(self, width, height) end
  love.graphics.setCanvas()
  self.current = self.canvas_a

  aplicar_add(self, LIGHT, x, y, escala)
  aplicar_add(self, FILTRO_ADD_PRIMERO,
    x + (love.math.noise(love.timer.getTime() / 3) - 0.5) * 28, y, escala)
  aplicar_multiply(self, FILTRO_MULTIPLY, x, y, escala, width, height)
  aplicar_add(self, FILTRO_ADD_ULTIMO,
    x, y + (love.math.noise(love.timer.getTime() / 3 + 80) - 1) * 18, escala)

  love.graphics.setCanvas()
  love.graphics.setShader()
  love.graphics.setBlendMode("alpha")
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(self.current, 0, 0)
  love.graphics.setFont(self.fuente_ui)
  love.graphics.setColor(1, 1, 1, 1)
  if self.buyin_mode then
    love.graphics.printf("Elige la cantidad de dinero que quieres canjear", 0, 12, width, "center")
  else
    local boton = { x = width / 2 - 110, y = 18, w = 220, h = 42 }
    local aviso = self.jugada_registrada and (Mando.boton("volver") .. " - Volver al casino")
      or "Juega 3 manos para salir"
    love.graphics.printf(aviso, width * 0.58, boton.y + (boton.h - self.fuente_ui:getHeight()) / 2,
      width * 0.40, "right")
    if self.bankrupt_notice then
      love.graphics.setColor(0, 0, 0, 0.82)
      love.graphics.rectangle("fill", width * 0.20, height * 0.40, width * 0.60, height * 0.18, 16, 16)
      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.setFont(self.fuente_boton)
      love.graphics.printf("TE QUEDASTE SIN FICHAS", width * 0.22, height * 0.44, width * 0.56, "center")
      love.graphics.setFont(self.fuente_ui)
      love.graphics.printf("Volviendo al casino...", width * 0.22, height * 0.51, width * 0.56, "center")
    end
    if self.mostrar_clasificacion then
      love.graphics.setColor(0, 0, 0, 0.78)
      love.graphics.rectangle("fill", 0, 0, width, height)
      local imagen_width, imagen_height = CLASIFICACION:getDimensions()
      local escala_imagen = math.min(width * 0.78 / imagen_width, height * 0.88 / imagen_height)
      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.draw(CLASIFICACION, (width - imagen_width * escala_imagen) / 2,
        (height - imagen_height * escala_imagen) / 2, 0, escala_imagen, escala_imagen)
    end
    if self.game.status == "showdown" and not self.collecting_chips and not self.session_finished
        and not self.mostrar_clasificacion then
      local siguiente = self.botones[1] or { x = width / 2, y = height * 0.94, w = 150, h = 52, press = 0 }
      local scale = (siguiente.press or 0) > 0 and 0.90 or 1
      local w, h = siguiente.w * scale, siguiente.h * scale
      local cx, cy = siguiente.x, siguiente.y
      local hover = punto_en_rect(love.mouse.getX(), love.mouse.getY(), siguiente)
      love.graphics.setColor(0, 0, 0, 0.32)
      love.graphics.rectangle("fill", cx - w / 2 + 3, cy - h / 2 + 5, w, h, 14, 14)
      love.graphics.setColor(0.08, 0.62, 0.27, 1)
      love.graphics.rectangle("fill", cx - w / 2, cy - h / 2, w, h, 14, 14)
      if hover then
        love.graphics.setColor(0.42, 0.95, 0.55, 0.9)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", cx - w / 2 - 3, cy - h / 2 - 3, w + 6, h + 6, 16, 16)
      end
      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.setFont(self.fuente_boton)
      love.graphics.printf("OTRA RONDA", cx - w / 2, cy - self.fuente_boton:getHeight() / 2, w, "center")
    end
    love.graphics.setColor(0, 0, 0, 0.38)
    love.graphics.rectangle("fill", boton.x + 3, boton.y + 4, boton.w, boton.h, 12, 12)
    love.graphics.setColor(0.42, 0.29, 0.12, 1)
    love.graphics.rectangle("fill", boton.x, boton.y, boton.w, boton.h, 12, 12)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(self.fuente_boton)
    local titulo = self.mostrar_clasificacion and "CERRAR MANOS DE POKER" or "MANOS DE POKER"
    love.graphics.printf(titulo, boton.x, boton.y + (boton.h - self.fuente_boton:getHeight()) / 2,
      boton.w, "center")
  end
  love.graphics.pop()
end

function Poker:leave()
  self:liquidar_fichas()
  self.context, self.machine, self.opciones = nil, nil, nil
  self.cartas, self.baraja, self.jugadores, self.comunales = nil, nil, nil, nil
  self.bots, self.holdem_board, self.game = nil, nil, nil
  self.comunales_reveladas, self.comunales_visibles, self.input_lock = nil, nil, nil
  self.bot_wait, self.bot_index = nil, nil
  self.out_of_chips, self.returning_to_casino = nil, nil
  self.bankrupt_notice, self.bankrupt_notice_time = nil, nil
  self.canvas_a, self.canvas_b, self.current, self.multiply_shader = nil, nil, nil, nil
  self.fuente_ui, self.fuente_boton = nil, nil
  self.buyin_mode, self.dragging_buyin, self.buyin_spent, self.cashed_out, self.cashout_money = nil, nil, nil, nil, nil
  self.buyin_error, self.mostrar_clasificacion = nil, nil
end

return Poker
