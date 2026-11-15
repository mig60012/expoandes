local DayFlow = require("src/systems/day_flow")
local Economy = require("src/systems/economy")
local Progress = require("src/systems/progress")

local context = {
  economy = Economy.new(),
  progress = Progress.new({
    flags = {},
    values = { current_day = 1 },
    outcome_options = {
      N1 = { "A", "B", "C" },
      N2 = { "A", "B", "C" },
      N3 = { "A", "B", "C", "D" },
      N5 = { "A", "B", "C" },
    },
  }),
}

local flow = DayFlow.new(context)
flow:start_day(1)
flow:record_games(3)
local day_one, day_one_result = flow:record_return_home()
assert(day_one, day_one_result)
assert(day_one_result == "A")
assert(context.progress:get_outcome("N1") == "A")
assert(context.progress:get_value("current_day") == 1)

flow:start_next_day()
assert(flow:get_day() == 2)
assert(context.progress:get_value("casino_games_today") == 0)
flow:record_games(6)
local day_two, day_two_result = flow:finish_day()
assert(day_two, day_two_result)
assert(day_two_result == "C")
assert(context.progress:get_outcome("N2") == "C")

flow:start_day(5)
local economic, economic_result = flow:record_economic_decision("daughter_savings")
assert(economic, economic_result)
assert(context.progress:get_outcome("N5") == "B")
local day_five, day_five_result = flow:finish_day()
assert(day_five, day_five_result)
assert(day_five_result == nil)

print("test_day_flow: ok")
