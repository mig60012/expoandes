local Dialogue = require("src/systems/dialogue")
local Progress = require("src/systems/progress")
local Economy = require("src/systems/economy")

local context = {
  economy = Economy.new(),
  progress = Progress.new({
    flags = {},
    values = { family_points = 0 },
    outcome_options = {},
  }),
}

local dialogue = Dialogue.new("day_1.lua", context)
local choices = assert(dialogue:get_choices())
assert(#choices == 2)
assert(dialogue:choose(1))
assert(context.progress:get_value("family_points") == 1)
assert(dialogue:advance())
assert(not dialogue:is_finished())
assert(not dialogue:advance())
assert(dialogue:is_finished())

local return_dialogue = Dialogue.new("day_1_return.lua", context)
local return_choices = assert(return_dialogue:get_choices())
assert(return_choices[1].choice.action == "work")
assert(return_choices[2].choice.action == "family")
assert(return_dialogue:choose(2))
assert(return_dialogue:is_finished())

print("test_day1_dialogue: ok")
