local Dialogue = require("src/systems/dialogue")
local Progress = require("src/systems/progress")
local Economy = require("src/systems/economy")

local context = {
  economy = Economy.new(0),
  progress = Progress.new({ flags = { listened = false }, values = {} }),
}

local dialogue = Dialogue.new({
  start = "start",
  nodes = {
    start = {
      speaker = "Guide",
      text = "Listen?",
      choices = {
        {
          text = "Yes",
          next = "finish",
          effects = {
            { type = "set_flag", key = "listened", value = true },
          },
        },
        { text = "No", next = "finish" },
      },
    },
    finish = { text = "Finished", ending = true },
  },
}, context)

assert(dialogue:current_line() == "Listen?")
local choices = assert(dialogue:get_choices())
assert(#choices == 2)
assert(dialogue:choose(1))
assert(context.progress:get_flag("listened"))
assert(dialogue:current_line() == "Finished")
assert(not dialogue:is_finished())
assert(not dialogue:advance())
assert(dialogue:is_finished())

print("test_dialogue: ok")
