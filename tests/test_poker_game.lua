local PokerGame = require("src/systems/poker_game")

local bot = {
  money = 100,
  decideAction = function(self, _, _, _, amount_to_call)
    if amount_to_call > 0 then
      return { action = "call", amount = math.min(amount_to_call, self.money) }
    end
    return { action = "check", amount = 0 }
  end,
}

local game = PokerGame:new({
  { name = "Jugador", stack = 100 },
  { name = "Bot", controller = bot },
}, {
  small_blind = 5,
  big_blind = 10,
  min_raise = 10,
  evaluator = function()
    return 1, 0.5
  end,
})

game:start_hand({ {}, {} })
assert(game.pot == 10, "la ciega grande debe crear el bote inicial")
local ok = game:apply_action(1, { action = "check", amount = 0 })
assert(not ok, "no se puede hacer check frente a una apuesta")
ok = game:apply_action(1, { action = "call", amount = 10 })
assert(ok and game.can_advance, "la ronda debe cerrarse tras igualar")

game:advance_phase({}, "flop")
ok = game:apply_action(1, { action = "fold", amount = 0 })
assert(ok and game.status == "showdown", "el bot debe ganar cuando el jugador se retira")
assert(game.winners[1].name == "Bot", "el bot debe ser el ganador")
assert(bot.money > 0, "el ganador debe recibir el bote")

print("test_poker_game: ok")
