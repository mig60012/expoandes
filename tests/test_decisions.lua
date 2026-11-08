local Progress = require("src/systems/progress")
local Economy = require("src/systems/economy")
local Conditions = require("src/systems/decisions/conditions")
local Effects = require("src/systems/decisions/effects")

local function assert_error(value, message)
  assert(value == false, message or "Expected an error")
end

local context = {
  economy = Economy.new(10),
  progress = Progress.new({
    flags = { ready = true, finished = false },
    values = { points = 3 },
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

print("test_decisions: ok")
