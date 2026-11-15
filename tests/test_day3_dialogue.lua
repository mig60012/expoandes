local Dialogue = require("src/systems/dialogue")
local Progress = require("src/systems/progress")
local Economy = require("src/systems/economy")

local function make_context(n1, n2)
  local progress = Progress.new({
    flags = {},
    values = { family_points = 0 },
    outcome_options = {
      N1 = { "A", "B", "C" },
      N2 = { "A", "B", "C" },
    },
  })
  progress:set_outcome("N1", n1)
  progress:set_outcome("N2", n2)
  return {
    economy = Economy.new(),
    progress = progress,
  }
end

local family_context = make_context("A", "A")
local family_dialogue = Dialogue.new("day_3.lua", family_context)
assert(family_dialogue:current_line():match("desayuno"))
assert(family_dialogue:advance())
local family_choices = assert(family_dialogue:get_choices())
assert(#family_choices == 2)
assert(family_dialogue:choose(1))
assert(family_context.progress:get_value("family_points") == 1)

local confrontation_context = make_context("B", "C")
local confrontation = Dialogue.new("day_3.lua", confrontation_context)
assert(confrontation:current_line():match("cansando"))
assert(confrontation:advance())
local confrontation_choices = assert(confrontation:get_choices())
assert(#confrontation_choices == 2)
assert(confrontation:choose(1))
assert(confrontation_context.progress:get_value("family_points") == -1)

local one_absence_context = make_context("A", "B")
local one_absence = Dialogue.new("day_3.lua", one_absence_context)
assert(one_absence:current_line():match("Sé que solo fue ayer"))

print("test_day3_dialogue: ok")
