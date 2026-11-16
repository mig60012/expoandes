local Economy = require("src/systems/economy")
local Progress = require("src/systems/progress")
local DayFlow = require("src/systems/day_flow")
local FinalEvaluation = require("src/systems/final_evaluation")

local function context(money)
  return {
    economy = Economy.new(money or 0),
    rules = { debt_total = 125, family_points_threshold = 5, car_sale_value = 10,
      house_sale_value = 15, daughter_savings_value = 10 },
    progress = Progress.new({ flags = { car_sold = false },
      values = { family_points = 0, current_day = 1, casino_games_today = 0, debt_percentage = 0 },
      outcome_options = { N1={"A","B","C"}, N2={"A","B","C"}, N3={"A","B","C","D"}, N5={"A","B","C"} } }),
  }
end

for _, decision in ipairs({ "sell_known", "sell_unknown" }) do
  local c = context(0)
  local flow = DayFlow.new(c); flow:start_day(3)
  flow:record_games(decision == "sell_known" and 3 or 6)
  assert(flow:record_car_decision(decision))
  assert(c.economy:get_money() == 10 and c.progress:get_flag("car_sold"), "vender el carro acredita 10 M")
  assert(not flow:record_car_decision(decision) and c.economy:get_money() == 10, "la venta del carro no se acredita dos veces")
end
for decision, expected in pairs({ mortgage = 15, daughter_savings = 10, none = 0 }) do
  local c = context(0)
  local flow = DayFlow.new(c); flow:start_day(5)
  assert(flow:record_economic_decision(decision))
  assert(c.economy:get_money() == expected, decision .. " acredita el importe correcto")
  assert(not flow:record_economic_decision(decision) and c.economy:get_money() == expected,
    decision .. " no se acredita dos veces")
end

local c = context(62.5)
c.progress:set_value("family_points", 4)
assert(FinalEvaluation.debt_percentage(c) == 50 and FinalEvaluation.evaluate(c) == "final_3")
c.progress:set_value("family_points", 5)
assert(FinalEvaluation.evaluate(c) == "final_2")
c.economy.money = 125
assert(FinalEvaluation.debt_percentage(c) == 100 and FinalEvaluation.evaluate(c) == "final_4")

local original_love = love
love = { graphics = { newImage = function() return {} end } }
local Poker = assert(loadfile("src/states/casino/poker/poker.lua"))()
love = original_love
local poker_context = context(20)
poker_context.rules.poker_chips_per_million = 100
local poker = setmetatable({ context = poker_context, buyin_mode = true, buyin_min = 3, buyin_max = 20,
  buyin_value = 7, chips_per_million = 100, cashed_out = false, jugada_registrada = false,
  opciones = { al_jugar = function() end },
  crear_sesion = function(self, stack) self.game = { players = { { stack = stack } } } end,
}, { __index = Poker })
assert(poker:confirmar_compra())
assert(poker_context.economy:get_money() == 13 and poker.game.players[1].stack == 700,
  "la compra descuenta 7 M y entrega 700 fichas")
poker.game.players[1].stack = 950
poker.session_finished = true
poker:registrar_jugada_si_termino()
assert(poker.cashout_money == 9.5 and poker_context.economy:get_money() == 22.5,
  "al terminar la sesion, 950 fichas regresan como 9.5 M")
assert(poker:liquidar_fichas() == 0 and poker_context.economy:get_money() == 22.5,
  "el cobro de salida ocurre exactamente una vez")
print("economy: assets, 125 M debt, 5 family points and poker buy-in/cash-out: ok")
