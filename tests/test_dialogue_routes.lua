local Dialogue = require("src/systems/dialogue")
local Progress = require("src/systems/progress")

local function context(value)
  return {
    progress = Progress.new({ values = { points = value } }),
  }
end

local data = {
  start = "router",
  nodes = {
    router = {
      routes = {
        {
          condition = { type = "value", key = "points", operator = ">=", value = 5 },
          next = "good",
        },
        { next = "normal" },
      },
    },
    good = { text = "Good route", ending = true },
    normal = { text = "Normal route", ending = true },
  },
}

local high = Dialogue.new(data, context(5))
assert(high:current_line() == "Good route")

local low = Dialogue.new(data, context(2))
assert(low:current_line() == "Normal route")

local invalid = {
  start = "start",
  nodes = {
    start = { next = "missing" },
  },
}
local ok = pcall(function() Dialogue.new(invalid, context(0)) end)
assert(not ok, "Invalid dialogue references must fail during loading")

print("test_dialogue_routes: ok")
