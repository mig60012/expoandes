local Dialogue = require("src/systems/dialogue")
local Progress = require("src/systems/progress")
local Economy = require("src/systems/economy")

local function make_context(n1)
  return {
    economy = Economy.new(),
    progress = Progress.new({
      flags = {},
      values = { family_points = 0 },
      outcome_options = {
        N1 = { "A", "B", "C" },
      },
    }),
  }
end

local family_context = make_context("A")
family_context.progress:set_outcome("N1", "A")
local family_dialogue = Dialogue.new("day_2.lua", family_context)
assert(family_dialogue:current_speaker() == "Esposa")
assert(family_dialogue:advance())
assert(family_dialogue:advance())
local family_choices = assert(family_dialogue:get_choices())
assert(#family_choices == 2)
assert(family_dialogue:choose(1))
assert(family_context.progress:get_value("family_points") == 1)

local absence_context = make_context("B")
absence_context.progress:set_outcome("N1", "B")
local absence_dialogue = Dialogue.new("day_2.lua", absence_context)
assert(absence_dialogue:current_speaker() == "Esposa")
assert(absence_dialogue:advance())
assert(absence_dialogue:advance())
assert(absence_dialogue:current_line() == "Ya se está volviendo costumbre.")

print("test_day2_dialogue: ok")
