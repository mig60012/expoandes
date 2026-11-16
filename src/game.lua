-- En este modulo se tiene todo el contexto del juego, es decir, las decisiones tomadas por el jugador, la cantidad de dinero que tenga etc.

local StateMachine = require("src/state_machine")
local Mando = require("src/systems/mando")
local Economy = require("src/systems/economy")
local Progress = require("src/systems/progress")
local DayFlow = require("src/systems/day_flow")
local Story = require("src/story")
local StoryTest = require("src/states/story_test")

local Game = {}

function Game.usa_cursor()
  local estado = StateMachine.current
  if not estado then return false end
  local propio = estado.usa_cursor
  if type(propio) == "function" then return propio(estado) == true end
  if propio ~= nil then return propio == true end
  return estado.mousepressed ~= nil and estado.keypressed == nil
end

function Game.load()
  Mando.iniciar({
    tecla = function(tecla) StateMachine:keypressed(tecla, tecla, false) end,
    soltar_tecla = function(tecla) StateMachine:keyreleased(tecla, tecla) end,
    clic = function(x, y, boton) StateMachine:mousepressed(x, y, boton, false, 1) end,
    soltar_clic = function(x, y, boton) StateMachine:mousereleased(x, y, boton, false, 1) end,
  })
  Game.context = {
    -- Capital inicial suficiente para acceder a las mesas sin usar atajos de
    -- desarrollo; las ganancias y pérdidas siguen siendo las del casino.
    economy = Economy.new(10),
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
        current_day = 1,
      },
      outcome_options = {
        N1 = { "A", "B", "C" },
        N2 = { "A", "B", "C" },
        N3 = { "A", "B", "C", "D" },
        N5 = { "A", "B", "C" },
      },
    }),
    time_of_day = 0, -- 0 = mañana, 1 = tarde, 2 = noche
    rules = {
      -- Valores narrativos configurables: el guion no fija estas cantidades.
      family_points_threshold = 2,
      work_debt_percentage = 20,
      mortgage_debt_percentage = 80,
      daughter_savings_debt_percentage = 40,
      car_debt_percentage = 20,
      work_income = 5,
    },
    state_machine = StateMachine,
    story_test = StoryTest.enabled(),
  }
  Game.context.day_flow = DayFlow.new(Game.context)
  Game.context.day_flow:start_day(1)
  Game.context.story = Story.new(Game.context)

  StateMachine.load(Game.context)
end

function Game.update(dt)
  Mando.actualizar(dt, Game.usa_cursor())
  StateMachine:update(dt)
end

function Game.draw()
  StateMachine:draw()
end

function Game.keypressed(key, scancode, isrepeat)
  Mando.usar_teclado()
  StateMachine:keypressed(key, scancode, isrepeat)
end

function Game.keyreleased(key, scancode)
  StateMachine:keyreleased(key, scancode)
end

function Game.mousepressed(x, y, button, istouch, presses)
  Mando.usar_teclado()
  StateMachine:mousepressed(x, y, button, istouch, presses)
end

function Game.mousemoved(x, y, dx, dy, istouch)
  StateMachine:mousemoved(x, y, dx, dy, istouch)
end

function Game.mousereleased(x, y, button, istouch, presses)
  StateMachine:mousereleased(x, y, button, istouch, presses)
end

function Game.gamepadpressed(joystick, button)
  Mando.presionar(joystick, button, Game.usa_cursor())
end

function Game.gamepadreleased(joystick, button)
  Mando.soltar(joystick, button)
end

return Game
