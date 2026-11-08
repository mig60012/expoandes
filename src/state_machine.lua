--[[
-- El state machine es el encargado de cambiar el gamestate
--]]

local state_machine = {
  states = {},
  current = nil,
  last = nil,
}

-- Aqui se cargan todos los States
function state_machine.load(context)
  state_machine.states = {
    casa = require("src/states/casa"),
    casino = require("src/states/casino"),
    transicion = require("src/states/transicion"),
    animacion = require("src/states/animacion"),
  }

  state_machine.context = context or {}
  state_machine.current_name = ""
  state_machine:switch("transicion")
end

function state_machine:switch(name, ...)
  local next_state = self.states[name]
  assert(next_state, "Unknown state: " .. tostring(name))

  if self.current and self.current.leave then
    self.last = self.current_name
    self.current:leave()
  end

  self.current = next_state
  self.current_name = name
  if self.current.enter then
    self.current:enter(self.context, ...)
  end
end

function state_machine:update(dt)
  if self.current and self.current.update then
    self.current:update(dt)
  end
end

function state_machine:draw()
  if self.current and self.current.draw then
    self.current:draw()
  end
end

function state_machine:keypressed(key, scancode, isrepeat)
  if self.current and self.current.keypressed then
    self.current:keypressed(key, scancode, isrepeat)
  end
end

function state_machine:keyreleased(key, scancode)
  if self.current and self.current.keyreleased then
    self.current:keyreleased(key, scancode)
  end
end

return state_machine
