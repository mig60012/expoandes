local Dialogue = require("src/systems/dialogue")
local DayFlow = require("src/systems/day_flow")
local Progress = require("src/systems/progress")
local Economy = require("src/systems/economy")

local context = {
  economy = Economy.new(),
  progress = Progress.new({
    flags = {},
    values = { current_day = 3, casino_games_today = 3 },
    outcome_options = {
      N1 = { "A", "B", "C" },
      N2 = { "A", "B", "C" },
      N3 = { "A", "B", "C", "D" },
      N5 = { "A", "B", "C" },
    },
  }),
}
context.progress:set_outcome("N1", "A")
context.progress:set_outcome("N2", "A")

local flow = DayFlow.new(context)
flow:start_day(3)
flow:record_games(3)

local dialogue = Dialogue.new("day_3_return.lua", context)
local choices = assert(dialogue:get_choices())
assert(choices[1].choice.action == "sell_known")
assert(choices[2].choice.action == "keep")

local recorded, result = flow:record_car_decision("sell_known")
assert(recorded, result)
assert(result == "A")
assert(context.progress:get_outcome("N3") == "A")

local invalid, invalid_error = flow:record_car_decision("sell_unknown")
assert(not invalid)
assert(invalid_error)

print("test_day3_return: ok")
