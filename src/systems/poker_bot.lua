-- Lógica pura de decisión para un bot de Texas Hold'em.
-- Este módulo no conoce el estado del juego, el rendering ni LÖVE.

-- La librería puede estar instalada como dependencia Lua o incluida en
-- `lib/holdem`. En ambos casos se conserva su API pública original.
local function cargar_analysis()
  local ok, analysis = pcall(require, "holdem.analysis")
  if ok then
    return analysis
  end

  package.path = "lib/?.lua;" .. package.path
  return require("holdem.analysis")
end

local Analysis = cargar_analysis()

local Bot = {}
Bot.__index = Bot

-- W_Playable controla cuánto debe gustarle una mano para jugarla pre-flop.
-- W_Aggro controla la frecuencia con la que convierte una mano jugable en raise.
-- W_Bluff controla los raises con manos débiles después del flop.
-- W_Risk controla cuánto se desvía de la decisión basada en pot odds.
local PERSONALITIES = {
  Fish = {
    W_Playable = 0.30,
    W_Aggro = 0.15,
    W_Bluff = 0.08,
    W_Risk = 0.95,
  },
  Maniac = {
    W_Playable = 0.35,
    W_Aggro = 0.95,
    W_Bluff = 0.85,
    W_Risk = 0.90,
  },
  Nit = {
    W_Playable = 0.82,
    W_Aggro = 0.30,
    W_Bluff = 0.00,
    W_Risk = 0.10,
  },
}

local VALID_PHASES = {
  preflop = true,
  flop = true,
  turn = true,
  river = true,
}

local function limitar(valor, minimo, maximo)
  return math.max(minimo, math.min(valor, maximo))
end

local function numero_no_negativo(valor)
  return math.max(0, tonumber(valor) or 0)
end

local function copiar_personalidad(personalidad)
  local preset = PERSONALITIES[personalidad]
  assert(preset, "Unknown poker bot personality: " .. tostring(personalidad))

  return {
    W_Playable = preset.W_Playable,
    W_Aggro = preset.W_Aggro,
    W_Bluff = preset.W_Bluff,
    W_Risk = preset.W_Risk,
  }
end

function Bot:new(name, money, personality)
  local bot = setmetatable({
    name = name or "Bot",
    money = numero_no_negativo(money),
    hole_cards = {},
    personality = personality or "Fish",
  }, self)

  bot:setPersonality(bot.personality)
  return bot
end

function Bot:setPersonality(personality)
  local pesos = copiar_personalidad(personality)
  self.personality = personality
  self.W_Playable = pesos.W_Playable
  self.W_Aggro = pesos.W_Aggro
  self.W_Bluff = pesos.W_Bluff
  self.W_Risk = pesos.W_Risk
  return self
end

function Bot:receiveCards(card1, card2)
  self.hole_cards = { card1, card2 }
  return self
end

-- Consume dinero y construye siempre el formato de respuesta requerido.
-- `amount` representa dinero adicional apostado en esta decisión, no el total
-- acumulado del bot en la ronda.
function Bot:_action(action, amount)
  local apuesta = limitar(numero_no_negativo(amount), 0, self.money)
  self.money = self.money - apuesta
  return { action = action, amount = apuesta }
end

function Bot:_check_or_fold(amount_to_call)
  if amount_to_call == 0 then
    return self:_action("check", 0)
  end
  return self:_action("fold", 0)
end

function Bot:_call(amount_to_call)
  if amount_to_call == 0 then
    return self:_action("check", 0)
  end
  if self.money == 0 then
    return self:_action("fold", 0)
  end
  -- En Hold'em, si el bot tiene menos que la apuesta puede pagar all-in.
  return self:_action("call", amount_to_call)
end

function Bot:_raise(amount_to_call, min_raise)
  local incremento = math.max(1, min_raise)
  local cantidad = amount_to_call + incremento

  -- Si no puede superar la apuesta actual, la única acción legal es call.
  if self.money <= amount_to_call then
    return self:_call(amount_to_call)
  end

  return self:_action("raise", cantidad)
end

function Bot:_evaluate(phase, board_cards)
  -- holdem devuelve (rank, percentile). Para la estrategia usamos el
  -- percentil: 0.0 es una mano muy débil y 1.0 una mano excelente.
  local _, fuerza = Analysis.evaluate(self.hole_cards, board_cards)
  assert(type(fuerza) == "number", "holdem.analysis.evaluate must return a percentile")
  return limitar(fuerza, 0, 1)
end

-- Pot odds simplificadas: coste del call dividido por el bote final después
-- de pagar. Si no hay coste, la decisión no necesita comparar odds.
local function pot_odds(current_pot, amount_to_call)
  if amount_to_call == 0 then
    return 0
  end
  return amount_to_call / (current_pot + amount_to_call)
end

function Bot:_decide_preflop(strength, amount_to_call, min_raise)
  -- La mano es jugable. El árbol decide entre subir y pagar.
  if strength >= self.W_Playable then
    if math.random() < self.W_Aggro then
      return self:_raise(amount_to_call, min_raise)
    end
    return self:_call(amount_to_call)
  end

  -- Fish y Maniac pueden continuar con manos marginales. El Nit casi nunca
  -- entra en este camino porque su W_Playable es deliberadamente alto.
  if math.random() < self.W_Bluff then
    return self:_raise(amount_to_call, min_raise)
  end
  if amount_to_call > 0 and math.random() < self.W_Risk * 0.5 then
    return self:_call(amount_to_call)
  end
  return self:_check_or_fold(amount_to_call)
end

function Bot:_decide_postflop(strength, current_pot, amount_to_call, min_raise)
  -- Mano débil: farol ocasional; si no, no paga una apuesta.
  if strength < 0.35 then
    if math.random() < self.W_Bluff then
      return self:_raise(amount_to_call, min_raise)
    end
    return self:_check_or_fold(amount_to_call)
  end

  -- Mano media o proyecto: compara pot odds y añade la tolerancia al riesgo
  -- de la personalidad. W_Risk no sustituye las odds; solo permite pagar
  -- algunas situaciones marginales.
  if strength < 0.70 then
    local odds = pot_odds(current_pot, amount_to_call)
    local acepta_riesgo = strength >= odds or math.random() < self.W_Risk * 0.5
    if acepta_riesgo then
      return self:_call(amount_to_call)
    end
    return self:_check_or_fold(amount_to_call)
  end

  -- Mano fuerte: apuesta por valor si es agresivo; de lo contrario hace
  -- slowplay pagando o pasando cuando no hay apuesta previa.
  if math.random() < self.W_Aggro then
    return self:_raise(amount_to_call, min_raise)
  end
  return self:_call(amount_to_call)
end

function Bot:decideAction(phase, board_cards, current_pot, amount_to_call, min_raise)
  assert(VALID_PHASES[phase], "Unknown poker phase: " .. tostring(phase))

  local board = board_cards or {}
  local pot = numero_no_negativo(current_pot)
  local call = numero_no_negativo(amount_to_call)
  local raise = numero_no_negativo(min_raise)
  local strength = self:_evaluate(phase, board)

  if phase == "preflop" then
    return self:_decide_preflop(strength, call, raise)
  end
  return self:_decide_postflop(strength, pot, call, raise)
end

return Bot
