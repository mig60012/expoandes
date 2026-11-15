local Progress = require("src/systems/progress")
local Economy = require("src/systems/economy")
local Conditions = require("src/systems/decisions/conditions")
local Effects = require("src/systems/decisions/effects")
local StoryOutcomes = require("src/systems/story_outcomes")

local function assert_error(value, message)
  assert(value == false, message or "Expected an error")
end

local context = {
  economy = Economy.new(10),
  progress = Progress.new({
    flags = { ready = true, finished = false },
    values = { points = 3 },
    outcome_options = {
      N1 = { "A", "B", "C" },
      N2 = { "A", "B", "C" },
      N3 = { "A", "B", "C", "D" },
      N5 = { "A", "B", "C" },
    },
  }),
}

assert(Conditions.evaluate({ type = "flag", key = "ready", value = true }, context))
assert(not Conditions.evaluate({ type = "flag", key = "finished", value = true }, context))
assert(Conditions.evaluate({ type = "value", key = "points", operator = ">=", value = 3 }, context))
assert(Conditions.evaluate({
  type = "all",
  conditions = {
    { type = "flag", key = "ready", value = true },
    { type = "value", key = "points", operator = ">", value = 2 },
  },
}, context))
assert(Conditions.evaluate({
  type = "any",
  conditions = {
    { type = "flag", key = "finished", value = true },
    { type = "value", key = "points", operator = "==", value = 3 },
  },
}, context))

local missing, missing_error = Conditions.evaluate({ type = "flag", key = "missing", value = true }, context)
assert_error(missing, missing_error)
assert(not context.progress:get_flag("finished"))

local applied, effect_error = Effects.apply_all({
  { type = "set_flag", key = "finished", value = true },
  { type = "add_value", key = "points", amount = 2 },
  { type = "spend_money", amount = 4 },
}, context)
assert(applied, effect_error)
assert(context.progress:get_flag("finished"))
assert(context.progress:get_value("points") == 5)
assert(context.economy:get_money() == 6)

local spent, spend_error = Effects.apply_all({ { type = "spend_money", amount = 100 } }, context)
assert_error(spent, spend_error)
assert(context.economy:get_money() == 6)

assert(context.progress:has_outcome("N1"))
assert(context.progress:get_outcome("N1") == nil)
context.progress:set_outcome("N1", "A")
assert(context.progress:get_outcome("N1") == "A")
assert(not pcall(function() context.progress:set_outcome("N1", "D") end))
assert(not pcall(function() context.progress:get_outcome("N4") end))

local outcome_condition = Conditions.evaluate({
  type = "outcome",
  key = "N1",
  value = "A",
}, context)
assert(outcome_condition)

local outcome_applied, outcome_error = Effects.apply({
  type = "set_outcome",
  key = "N1",
  value = "B",
}, context)
assert(outcome_applied, outcome_error)
assert(context.progress:get_outcome("N1") == "B")

local invalid_outcome, invalid_outcome_error = Effects.apply({
  type = "set_outcome",
  key = "N1",
  value = "D",
}, context)
assert(not invalid_outcome)
assert(invalid_outcome_error)
assert(context.progress:get_outcome("N1") == "B")

local n1_family, n1_family_result = StoryOutcomes.resolve_n1(context, {
  games = 3,
  spent_time_with_family = true,
})
assert(n1_family, n1_family_result)
assert(n1_family_result == "A")
assert(context.progress:get_outcome("N1") == "A")

local n1_work, n1_work_result = StoryOutcomes.resolve_n1(context, {
  games = 3,
  worked = true,
})
assert(n1_work, n1_work_result)
assert(n1_work_result == "B")
assert(context.progress:get_outcome("N1") == "B")

local n1_casino, n1_casino_result = StoryOutcomes.resolve_n1(context, {
  games = 6,
})
assert(n1_casino, n1_casino_result)
assert(n1_casino_result == "C")
assert(context.progress:get_outcome("N1") == "C")

local invalid_games, invalid_games_error = StoryOutcomes.resolve_n1(context, {
  games = 4,
})
assert(not invalid_games)
assert(invalid_games_error)
assert(context.progress:get_outcome("N1") == "C")

local invalid_activity, invalid_activity_error = StoryOutcomes.resolve_n1(context, {
  games = 3,
  worked = true,
  spent_time_with_family = true,
})
assert(not invalid_activity)
assert(invalid_activity_error)
assert(context.progress:get_outcome("N1") == "C")

local n2_family, n2_family_result = StoryOutcomes.resolve_n2(context, {
  games = 3,
  spent_time_with_family = true,
})
assert(n2_family, n2_family_result)
assert(n2_family_result == "A")
assert(context.progress:get_outcome("N2") == "A")

local n2_work, n2_work_result = StoryOutcomes.resolve_n2(context, {
  games = 3,
  worked = true,
})
assert(n2_work, n2_work_result)
assert(n2_work_result == "B")
assert(context.progress:get_outcome("N2") == "B")

local n2_casino, n2_casino_result = StoryOutcomes.resolve_n2(context, {
  games = 6,
})
assert(n2_casino, n2_casino_result)
assert(n2_casino_result == "C")
assert(context.progress:get_outcome("N2") == "C")

local n3_sold_known, n3_sold_known_result = StoryOutcomes.resolve_n3(context, {
  games = 3,
  car_sold = true,
  wife_knows_about_car = true,
})
assert(n3_sold_known, n3_sold_known_result)
assert(n3_sold_known_result == "A")
assert(context.progress:get_outcome("N3") == "A")

local n3_kept_after_three, n3_kept_after_three_result = StoryOutcomes.resolve_n3(context, {
  games = 3,
  car_sold = false,
})
assert(n3_kept_after_three, n3_kept_after_three_result)
assert(n3_kept_after_three_result == "B")
assert(context.progress:get_outcome("N3") == "B")

local n3_sold_unknown, n3_sold_unknown_result = StoryOutcomes.resolve_n3(context, {
  games = 6,
  car_sold = true,
  wife_knows_about_car = false,
})
assert(n3_sold_unknown, n3_sold_unknown_result)
assert(n3_sold_unknown_result == "C")
assert(context.progress:get_outcome("N3") == "C")

local n3_kept_after_six, n3_kept_after_six_result = StoryOutcomes.resolve_n3(context, {
  games = 6,
  car_sold = false,
})
assert(n3_kept_after_six, n3_kept_after_six_result)
assert(n3_kept_after_six_result == "D")
assert(context.progress:get_outcome("N3") == "D")

local invalid_n3, invalid_n3_error = StoryOutcomes.resolve_n3(context, {
  games = 3,
  car_sold = true,
  wife_knows_about_car = false,
})
assert(not invalid_n3)
assert(invalid_n3_error)
assert(context.progress:get_outcome("N3") == "D")

local n5_mortgage, n5_mortgage_result = StoryOutcomes.resolve_n5(context, "mortgage")
assert(n5_mortgage, n5_mortgage_result)
assert(n5_mortgage_result == "A")
assert(context.progress:get_outcome("N5") == "A")

local n5_savings, n5_savings_result = StoryOutcomes.resolve_n5(context, "daughter_savings")
assert(n5_savings, n5_savings_result)
assert(n5_savings_result == "B")
assert(context.progress:get_outcome("N5") == "B")

local n5_none, n5_none_result = StoryOutcomes.resolve_n5(context, "none")
assert(n5_none, n5_none_result)
assert(n5_none_result == "C")
assert(context.progress:get_outcome("N5") == "C")

local invalid_n5, invalid_n5_error = StoryOutcomes.resolve_n5(context, "sell_business")
assert(not invalid_n5)
assert(invalid_n5_error)
assert(context.progress:get_outcome("N5") == "C")

context.progress:reset()
assert(context.progress:get_flag("finished") == false)
assert(context.progress:get_value("points") == 3)
assert(context.progress:get_outcome("N1") == nil)

print("test_decisions: ok")
