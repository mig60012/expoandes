--[[
-- El state machine es el encargado de cambiar el gamestate
--]]

local ScreenTransition = require("src/ui/screen_transition")
local unpack_args = table.unpack or unpack

local state_machine = {
  states = {},
  current = nil,
  last = nil,
  transition = nil,
  pending_switch = nil,
}

-- Aqui se cargan todos los States
function state_machine.load(context)
  state_machine.states = {
    casa = require("src/states/casa"),
    trabajo = require("src/states/trabajo"),
    casino = require("src/states/casino"),
    transicion = require("src/states/transicion"),
    animacion = require("src/states/animacion"),
    finales = require("src/states/finales"),
    story_test = require("src/states/story_test"),
  }

  state_machine.context = context or {}
  state_machine.current_name = ""
  state_machine.transition = ScreenTransition.new(1)
  state_machine.pending_switch = nil
  local initial = state_machine.context.story_test and "story_test"
    or (state_machine.context.story and "animacion" or "casa")
  state_machine:switch_now(initial)
end

function state_machine:switch_now(name, ...)
  local next_state = self.states[name]
  assert(next_state, "Unknown state: " .. tostring(name))

  if self.current then
    self.last = self.current_name
    if self.current.leave then self.current:leave() end
  end

  self.current = next_state
  self.current_name = name
  if self.current.enter then
    self.current:enter(self.context, ...)
  end
end

function state_machine:switch(name, ...)
  local next_state = self.states[name]
  assert(next_state, "Unknown state: " .. tostring(name))

  -- Las máquinas usadas por pruebas aisladas no llaman a load(), por lo que
  -- conservan el cambio síncrono y no necesitan un contexto gráfico.
  if not self.transition or not self.current then
    return self:switch_now(name, ...)
  end
  if self.transition:is_active() then return false end

  self.pending_switch = {
    name = name,
    arguments = { ... },
  }
  self.transition:start()
  return true
end

function state_machine:commit_pending_switch()
  local pending = self.pending_switch
  self.pending_switch = nil
  if not pending then return end
  self:switch_now(pending.name, unpack_args(pending.arguments))
end

function state_machine:update(dt)
  if self.transition and self.transition:is_active() then
    self.transition:update(dt, function() self:commit_pending_switch() end)
    return
  end
  if self.current and self.current.update then
    self.current:update(dt)
  end
end

function state_machine:draw()
  if self.current and self.current.draw then
    self.current:draw()
  end
end

function state_machine:draw_transition()
  if self.transition then self.transition:draw() end
end

function state_machine:keypressed(key, scancode, isrepeat)
  if self.transition and self.transition:is_active() then return end
  if self.current and self.current.keypressed then
    self.current:keypressed(key, scancode, isrepeat)
  end
end

function state_machine:keyreleased(key, scancode)
  if self.transition and self.transition:is_active() then return end
  if self.current and self.current.keyreleased then
    self.current:keyreleased(key, scancode)
  end
end

function state_machine:mousepressed(x, y, button, istouch, presses)
  if self.transition and self.transition:is_active() then return end
  if self.current and self.current.mousepressed then
    self.current:mousepressed(x, y, button, istouch, presses)
  end
end

function state_machine:mousemoved(x, y, dx, dy, istouch)
  if self.transition and self.transition:is_active() then return end
  if self.current and self.current.mousemoved then
    self.current:mousemoved(x, y, dx, dy, istouch)
  end
end

function state_machine:mousereleased(x, y, button, istouch, presses)
  if self.transition and self.transition:is_active() then return end
  if self.current and self.current.mousereleased then
    self.current:mousereleased(x, y, button, istouch, presses)
  end
end

return state_machine
