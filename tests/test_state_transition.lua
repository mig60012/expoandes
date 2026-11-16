local ScreenTransition = require("src/ui/screen_transition")
local machine = assert(loadfile("src/state_machine.lua"))()

local entered, left, received = {}, {}, nil
local states = {
  casa = {
    enter = function() entered[#entered + 1] = "casa" end,
    leave = function() left[#left + 1] = "casa" end,
  },
  casino = {
    enter = function(_, _, argument)
      entered[#entered + 1] = "casino"
      received = argument
    end,
    leave = function() left[#left + 1] = "casino" end,
  },
}

machine.states = states
machine.context = {}
machine.transition = ScreenTransition.new(1)
machine.pending_switch = nil
machine:switch_now("casa")

assert(machine:switch("casino", "preserve"), "la transición debe comenzar")
assert(machine.current_name == "casa", "el estado anterior se conserva durante el fade-out")
machine:update(0.49)
assert(machine.current_name == "casa" and #left == 0,
  "todavía no cambia antes del punto negro")

machine:update(0.01)
assert(machine.current_name == "casino", "el estado cambia cuando la pantalla está negra")
assert(left[1] == "casa" and entered[2] == "casino", "se respeta el ciclo leave/enter")
assert(received == "preserve", "los argumentos llegan al nuevo estado")

machine:update(0.49)
assert(machine.transition:is_active(), "el fade-in todavía está activo")
machine:update(0.01)
assert(not machine.transition:is_active(), "la transición dura un segundo")

print("test_state_transition: ok")
