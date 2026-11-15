local Dialogue = require("src/systems/dialogue")
local DayFlow = require("src/systems/day_flow")
local Progress = require("src/systems/progress")
local FinalEvaluation = require("src/systems/final_evaluation")

local function context()
  return {
    rules = {
      family_points_threshold = 2,
      work_debt_percentage = 20,
      mortgage_debt_percentage = 50,
      daughter_savings_debt_percentage = 60,
    },
    progress = Progress.new({
      flags = {},
      values = {
        family_points = 2,
        debt_percentage = 0,
        current_day = 4,
        casino_games_today = 3,
      },
      outcome_options = {
        N1 = { "A", "B", "C" },
        N2 = { "A", "B", "C" },
        N3 = { "A", "B", "C", "D" },
        N5 = { "A", "B", "C" },
      },
    }),
  }
end

local night_context = context()
local night = Dialogue.new("day_4_night.lua", night_context)
assert(night:advance())
assert(night:advance())
assert(night:advance())
assert(#night:get_choices() == 2)
assert(night:choose(1))
assert(night_context.progress:get_value("family_points") == 1)

local day5_context = context()
day5_context.progress:set_value("current_day", 5)
day5_context.progress:set_value("casino_games_today", 0)
local day5 = Dialogue.new("day_5.lua", day5_context)
assert(day5:advance())
assert(day5:advance())
assert(day5:advance())
assert(#day5:get_choices() == 2)

local flow = DayFlow.new(day5_context)
flow:start_day(5)
flow:mark_morning_complete()
local ok, outcome = flow:record_economic_decision("daughter_savings")
assert(ok and outcome == "B")
assert(day5_context.progress:get_value("debt_percentage") == 60)
assert(flow:finish_day())
assert(FinalEvaluation.evaluate(day5_context) == "final_2")

day5_context.progress:set_value("debt_percentage", 100)
assert(FinalEvaluation.evaluate(day5_context) == "final_4")
day5_context.progress:set_value("debt_percentage", 0)
assert(FinalEvaluation.evaluate(day5_context) == "final_1")

print("test_remaining_phases: ok")
