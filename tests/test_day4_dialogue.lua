local Dialogue = require("src/systems/dialogue")
local Progress = require("src/systems/progress")
local Economy = require("src/systems/economy")

local function make_context(n3)
  local progress = Progress.new({
    flags = {},
    values = {},
    outcome_options = {
      N3 = { "A", "B", "C", "D" },
    },
  })
  progress:set_outcome("N3", n3)
  return {
    economy = Economy.new(),
    progress = progress,
  }
end

local known = Dialogue.new("day_4.lua", make_context("A"))
assert(known:current_line():match("No estoy de acuerdo"))

local unknown = Dialogue.new("day_4.lua", make_context("C"))
assert(unknown:current_line():match("He decidido vender"))

local kept = Dialogue.new("day_4.lua", make_context("B"))
assert(kept:current_line():match("Voy al mercado"))

local kept_d = Dialogue.new("day_4.lua", make_context("D"))
assert(kept_d:current_line():match("Voy al mercado"))

print("test_day4_dialogue: ok")
