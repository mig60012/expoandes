-- Máquina de estados anidada del casino.
-- El estado global sigue siendo `casino`; esta máquina solo controla si el
-- jugador está recorriendo el salón o jugando en una mesa.
local StateMachine = {}
StateMachine.__index = StateMachine

function StateMachine.new(states)
  return setmetatable({
    states = states or {},
    current = nil,
    current_name = nil,
    context = nil,
  }, StateMachine)
end

function StateMachine:enter(context)
  self.context = context
end

function StateMachine:switch(name, ...)
  if name == nil then
    self:leave()
    return
  end

  local next_state = self.states[name]
  assert(next_state, "Unknown casino substate: " .. tostring(name))

  self:leave()
  self.current, self.current_name = next_state, name
  if self.current.enter then
    self.current:enter(self.context, self, ...)
  end
end

function StateMachine:leave()
  if self.current and self.current.leave then
    self.current:leave()
  end
  self.current, self.current_name = nil, nil
end

function StateMachine:update(dt)
  if self.current and self.current.update then
    self.current:update(dt)
  end
end

function StateMachine:draw()
  if self.current and self.current.draw then
    self.current:draw()
  end
end

function StateMachine:keypressed(key, scancode, isrepeat)
  if self.current and self.current.keypressed then
    self.current:keypressed(key, scancode, isrepeat)
  end
end

function StateMachine:keyreleased(key, scancode)
  if self.current and self.current.keyreleased then
    self.current:keyreleased(key, scancode)
  end
end

function StateMachine:mousepressed(x, y, button, istouch, presses)
  if self.current and self.current.mousepressed then
    self.current:mousepressed(x, y, button, istouch, presses)
  end
end

return StateMachine
