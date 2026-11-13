-- En este modulo se tiene todo el contexto del juego, es decir, las decisiones tomadas por el jugador, la cantidad de dinero que tenga etc.

local StateMachine = require("src/state_machine")
local Economy = require("src/systems/economy")
local Progress = require("src/systems/progress")

local Game = {}

function Game.load()
  Game.context = {
    economy = Economy.new(),
    progress = Progress.new({
      flags = {
        car_sold = false,
        house_mortgaged = false,
        wife_knows_about_bets = false,
        daughter_savings_used = false,
        homeless_man_saw_player = false,
      },
      values = {
        family_points = 0,
        debt_percentage = 0,
        casino_games_today = 0,
        casino_wins = 0,
      },
    }),
    time_of_day = 2, -- 0 = mañana, 1 = tarde, 2 = noche (por ahora)
    state_machine = StateMachine,
  }

  StateMachine.load(Game.context)
end

function Game.update(dt)
  StateMachine:update(dt)
end

function Game.draw()
  StateMachine:draw()
end

function Game.keypressed(key, scancode, isrepeat)
  StateMachine:keypressed(key, scancode, isrepeat)
end

function Game.keyreleased(key, scancode)
  StateMachine:keyreleased(key, scancode)
end

function Game.mousepressed(x, y, button, istouch, presses)
  StateMachine:mousepressed(x, y, button, istouch, presses)
end

function Game.mousemoved(x, y, dx, dy, istouch)
  StateMachine:mousemoved(x, y, dx, dy, istouch)
end

function Game.mousereleased(x, y, button, istouch, presses)
  StateMachine:mousereleased(x, y, button, istouch, presses)
end

return Game
