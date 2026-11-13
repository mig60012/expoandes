-- Gestor puro de una mano de Texas Hold'em.
-- No dibuja ni conoce LÖVE. Recibe jugadores y controladores (bots) y valida
-- todas las acciones antes de modificar el bote o el stack.
local PokerGame = {}
PokerGame.__index = PokerGame

local VALID_ACTIONS = {
  fold = true,
  check = true,
  call = true,
  raise = true,
}

local function no_negativo(value)
  return math.max(0, tonumber(value) or 0)
end

function PokerGame:new(players, options)
  options = options or {}
  return setmetatable({
    players = players or {},
    small_blind = no_negativo(options.small_blind or 0),
    big_blind = no_negativo(options.big_blind or 0),
    min_raise = no_negativo(options.min_raise or 10),
    base_raise = no_negativo(options.min_raise or 10),
    pot = 0,
    phase = "preflop",
    board = {},
    current_player_index = nil,
    current_bet = 0,
    status = "waiting",
    can_advance = false,
    last_error = nil,
    winners = {},
    payouts = {},
    evaluator = options.evaluator,
    -- La mesa visual puede desactivar esto para representar cada decisión de
    -- un bot antes de aplicarla. La lógica sin interfaz conserva el modo
    -- automático como comportamiento predeterminado.
    auto_bots = options.auto_bots ~= false,
  }, self)
end

function PokerGame:_stack(player)
  if player.controller then
    return no_negativo(player.controller.money)
  end
  return no_negativo(player.stack)
end

function PokerGame:_set_stack(player, value)
  value = no_negativo(value)
  if player.controller then
    player.controller.money = value
  else
    player.stack = value
  end
end

function PokerGame:_is_eligible(player)
  return not player.folded and not player.all_in
end

function PokerGame:_active_count()
  local count = 0
  for _, player in ipairs(self.players) do
    if not player.folded then
      count = count + 1
    end
  end
  return count
end

function PokerGame:_next_player(start)
  local count = #self.players
  for step = 1, count do
    local index = ((start + step - 1) % count) + 1
    local player = self.players[index]
    if self:_is_eligible(player) then
      return index
    end
  end
  return nil
end

function PokerGame:_all_acted_and_equalized()
  for _, player in ipairs(self.players) do
    if self:_is_eligible(player) then
      if not player.acted or player.round_bet ~= self.current_bet then
        return false
      end
    end
  end
  return true
end

function PokerGame:_update_round_status()
  if self:_active_count() <= 1 then
    self:finish_hand()
    return
  end

  if self:_all_acted_and_equalized() then
    self.status = "round_over"
    self.can_advance = true
    self.current_player_index = nil
  else
    self.status = "betting"
    self.can_advance = false
  end
end

function PokerGame:_run_bots()
  while self.status == "betting" do
    local player = self:get_current_player()
    if not player or not player.controller then
      return
    end
    self:act_current_bot()
  end
end

--- Apply exactly one AI action. Visual states call this after their own
--- anticipation animation; headless games can still use `_run_bots`.
function PokerGame:act_current_bot()
  local player = self:get_current_player()
  if not player or not player.controller then
    return false, "current player is not a bot"
  end
  local amount_to_call = self:get_amount_to_call(player)
  local decision = player.controller:decideAction(
    self.phase,
    self.board,
    self.pot,
    amount_to_call,
    self.min_raise
  )
  local ok, error_message = self:apply_action(player, decision, true)
  if not ok then
    self:apply_action(player, { action = "fold", amount = 0 }, true)
    player.last_error = error_message
  end
  return ok, decision, error_message
end

function PokerGame:start_hand(hole_cards)
  assert(#self.players > 1, "A poker hand needs at least two players")

  self.pot = 0
  self.phase = "preflop"
  self.board = {}
  self.current_bet = 0
  self.status = "betting"
  self.can_advance = false
  self.last_error = nil
  self.winners = {}
  self.payouts = {}

  for index, player in ipairs(self.players) do
    player.hole_cards = hole_cards and hole_cards[index] or {}
    player.round_bet = 0
    player.total_contribution = 0
    player.acted = false
    player.folded = false
    player.all_in = self:_stack(player) <= 0
    player.last_action = nil
    player.last_error = nil
    player.payout = 0
  end

  -- Ciegas simples para que cada mano tenga un bote inicial. El jugador 2
  -- pone la ciega pequeña y el jugador 3 la grande en este MVP.
  self.min_raise = self.base_raise
  if #self.players == 2 then
    self:_post_blind(self.players[2], self.big_blind)
  else
    self:_post_blind(self.players[2], self.small_blind)
    self:_post_blind(self.players[3], self.big_blind)
  end

  self.current_player_index = 1
  self:_skip_unavailable_player()
end

function PokerGame:_skip_unavailable_player()
  if self.status ~= "betting" then
    return
  end
  local player = self:get_current_player()
  if not player then
    self:_update_round_status()
    return
  end
  if not self:_is_eligible(player) then
    self.current_player_index = self:_next_player(self.current_player_index)
    self:_skip_unavailable_player()
    return
  end
  if player.controller and self.auto_bots then
    self:_run_bots()
  end
end

function PokerGame:_post_blind(player, amount)
  if not player or player.folded then
    return
  end
  local paid = math.min(amount, self:_stack(player))
  self:_set_stack(player, self:_stack(player) - paid)
  player.round_bet = paid
  player.total_contribution = paid
  self.pot = self.pot + paid
  if self:_stack(player) <= 0 then
    player.all_in = true
  end
  self.current_bet = math.max(self.current_bet, paid)
end

function PokerGame:get_current_player()
  if not self.current_player_index then
    return nil
  end
  return self.players[self.current_player_index]
end

function PokerGame:get_amount_to_call(player)
  player = player or self:get_current_player()
  if not player then
    return 0
  end
  return math.max(0, self.current_bet - player.round_bet)
end

function PokerGame:get_raise_amount(player)
  return self:get_amount_to_call(player) + self.min_raise
end

function PokerGame:is_human_turn()
  return self.status == "betting"
    and self.current_player_index == 1
    and self:get_current_player() ~= nil
end

function PokerGame:apply_action(player_or_index, decision, already_paid)
  local player = type(player_or_index) == "number"
    and self.players[player_or_index]
    or player_or_index
  if not player then
    return false, "unknown player"
  end
  if self.status ~= "betting" then
    return false, "betting round is not active"
  end
  if player ~= self:get_current_player() then
    return false, "it is not this player's turn"
  end
  if player.folded or player.all_in then
    return false, "player cannot act"
  end
  if type(decision) ~= "table" or not VALID_ACTIONS[decision.action] then
    return false, "invalid action"
  end

  local action = decision.action
  local amount_to_call = self:get_amount_to_call(player)
  local available = self:_stack(player)
  local amount = no_negativo(decision.amount)

  -- Bot:decideAction ya descuenta su propio dinero. El gestor solo actualiza
  -- sus contribuciones. Para el jugador humano, el gestor descuenta el stack.
  if already_paid then
    available = available + amount
  end

  if action == "check" and amount_to_call > 0 then
    return false, "cannot check while facing a bet"
  end
  if (action == "check" or action == "fold") and amount ~= 0 then
    return false, "this action cannot include a wager"
  end
  if action == "call" and amount > math.min(amount_to_call, available) then
    return false, "call exceeds available stack"
  end
  if action == "call" and amount_to_call == 0 then
    return false, "use check when there is nothing to call"
  end
  if action == "raise" then
    local minimum = amount_to_call + self.min_raise
    local all_in = amount == available and available > amount_to_call
    if amount < minimum and not all_in then
      return false, "raise is below the minimum"
    end
  end
  if amount > available then
    return false, "wager exceeds available stack"
  end

  if not already_paid then
    self:_set_stack(player, available - amount)
  end
  player.round_bet = player.round_bet + amount
  player.total_contribution = player.total_contribution + amount
  self.pot = self.pot + amount
  player.acted = true
  player.last_action = { action = action, amount = amount }

  if action == "fold" then
    player.folded = true
  elseif action == "raise" then
    local raise_size = player.round_bet - self.current_bet
    self.current_bet = player.round_bet
    self.min_raise = math.max(self.min_raise, raise_size)
  end

  if action ~= "fold" and self:_stack(player) <= 0 then
    player.all_in = true
  end

  self.current_player_index = self:_next_player(self.current_player_index)
  self:_update_round_status()
  if self.status == "betting" then
    self:_skip_unavailable_player()
  end
  return true
end

function PokerGame:advance_phase(board, phase)
  assert(self.can_advance, "the betting round is not complete")
  assert(phase == "flop" or phase == "turn" or phase == "river", "invalid next phase")

  self.board = board or {}
  self.phase = phase
  self.current_bet = 0
  self.min_raise = self.big_blind > 0 and self.big_blind or self.base_raise
  self.can_advance = false
  self.status = "betting"
  self.current_player_index = 1

  for _, player in ipairs(self.players) do
    player.round_bet = 0
    player.acted = false
  end
  self:_skip_unavailable_player()
end

-- Reparte el bote por capas de contribución. Esto permite que un jugador
-- all-in con menos fichas gane el bote principal sin cobrar apuestas a las
-- que nunca tuvo derecho a competir.
function PokerGame:finish_hand()
  if self.status == "showdown" or self.status == "hand_over" then
    return self.winners, self.payouts
  end

  local activos = {}
  for _, player in ipairs(self.players) do
    if not player.folded then
      activos[#activos + 1] = player
    end
  end

  if #activos == 1 then
    local winner = activos[1]
    self.payouts[winner] = self.pot
    if winner.controller then
      winner.controller.money = winner.controller.money + self.pot
    else
      winner.stack = winner.stack + self.pot
    end
    winner.payout = self.pot
    self.winners = { winner }
    self.status = "showdown"
    self.can_advance = false
    self.current_player_index = nil
    return self.winners, self.payouts
  end

  local puntuaciones = {}
  if #activos > 1 and self.evaluator then
    for _, player in ipairs(activos) do
      local rank, percentile = self.evaluator(player.hole_cards, self.board)
      puntuaciones[player] = { rank = rank, percentile = percentile }
    end
  end

  local niveles = {}
  for _, player in ipairs(self.players) do
    if player.total_contribution > 0 then
      niveles[player.total_contribution] = true
    end
  end
  local contribuciones = {}
  for nivel in pairs(niveles) do
    contribuciones[#contribuciones + 1] = nivel
  end
  table.sort(contribuciones)

  local anterior = 0
  for _, nivel in ipairs(contribuciones) do
    local participantes, elegibles = 0, {}
    for _, player in ipairs(self.players) do
      if player.total_contribution >= nivel then
        participantes = participantes + 1
        if not player.folded then
          elegibles[#elegibles + 1] = player
        end
      end
    end

    local bote = (nivel - anterior) * participantes
    if #elegibles > 0 and bote > 0 then
      local mejores = {}
      if #elegibles == 1 or not self.evaluator then
        mejores = { elegibles[1] }
      else
        local mejor_rank = math.huge
        for _, player in ipairs(elegibles) do
          local rank = puntuaciones[player].rank or math.huge
          if rank < mejor_rank then
            mejor_rank, mejores = rank, { player }
          elseif rank == mejor_rank then
            mejores[#mejores + 1] = player
          end
        end
      end

      local parte = math.floor(bote / #mejores)
      local sobrante = bote - parte * #mejores
      for indice, player in ipairs(mejores) do
        local premio = parte + (indice <= sobrante and 1 or 0)
        self.payouts[player] = (self.payouts[player] or 0) + premio
      end
    end
    anterior = nivel
  end

  -- Si no hubo apuestas, el ganador recibe cero pero la mano termina igual.
  for player, premio in pairs(self.payouts) do
    if player.controller then
      player.controller.money = player.controller.money + premio
    else
      player.stack = player.stack + premio
    end
    player.payout = premio
  end

  self.winners = {}
  for player, premio in pairs(self.payouts) do
    if premio > 0 then
      self.winners[#self.winners + 1] = player
    end
  end
  self.status = "showdown"
  self.can_advance = false
  self.current_player_index = nil
  return self.winners, self.payouts
end

return PokerGame
