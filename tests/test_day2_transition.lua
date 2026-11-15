local Dialogue = require("src/systems/dialogue")
local Progress = require("src/systems/progress")
local Economy = require("src/systems/economy")

local function make_context(outcome)
  local progress = Progress.new({
    flags = {},
    values = {},
    outcome_options = {
      N1 = { "A", "B", "C" },
    },
  })
  progress:set_outcome("N1", outcome)
  return {
    economy = Economy.new(),
    progress = progress,
  }
end

local seen_context = make_context("A")
local seen_dialogue = Dialogue.new("day_2_transition.lua", seen_context)
assert(seen_dialogue:current_line() == "¿Otro día más para el casino? Esto se está volviendo un hábito.")
assert(seen_dialogue:advance())
assert(seen_dialogue:current_line() == "Por favor, no se meta.")

local unseen_context = make_context("C")
local unseen_dialogue = Dialogue.new("day_2_transition.lua", unseen_context)
assert(unseen_dialogue:current_line() == "Señor, no lo vi anoche. Tenga cuidado con esas noches de juego sin fin.")

print("test_day2_transition: ok")
