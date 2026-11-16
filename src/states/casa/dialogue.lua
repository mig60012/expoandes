local Dialogue = require("src/systems/dialogue")
local Mando = require("src/systems/mando")

local DialogueView = {}
DialogueView.__index = DialogueView

function DialogueView.new(context, filename, on_finished)
  return setmetatable({
    dialogue = Dialogue.new(filename, context),
    selected = 1,
    on_finished = on_finished,
    active = true,
    last_choice = nil,
  }, DialogueView)
end

function DialogueView:_finish_if_needed()
  if self.dialogue:is_finished() then
    self.active = false
    if self.on_finished then self.on_finished(self, self.last_choice) end
  end
end

function DialogueView:update(_dt)
end

function DialogueView:keypressed(key)
  if not self.active then return end
  local choices = self.dialogue:get_choices() or {}
  if key == "up" or key == "w" then
    self.selected = math.max(1, self.selected - 1)
  elseif key == "down" or key == "s" then
    self.selected = math.min(math.max(1, #choices), self.selected + 1)
  elseif key == "return" or key == "space" then
    if #choices > 0 then
      self.last_choice = choices[self.selected].choice
      self.dialogue:choose(self.selected)
      self.selected = 1
    else
      self.dialogue:advance()
    end
    self:_finish_if_needed()
  end
end

function DialogueView:mousepressed(x, y, button)
  if not self.active or button ~= 1 then return end
  local choices = self.dialogue:get_choices() or {}
  if #choices == 0 then
    self.dialogue:advance()
    self:_finish_if_needed()
    return
  end

  local box_x, box_y, box_w = 290, 180, 700
  for index in ipairs(choices) do
    local option_y = box_y + 190 + (index - 1) * 48
    if x >= box_x + 24 and x <= box_x + box_w - 24
        and y >= option_y and y <= option_y + 38 then
      self.dialogue:choose(index)
      self.last_choice = choices[index].choice
      self.selected = 1
      self:_finish_if_needed()
      return
    end
  end
end

function DialogueView:draw()
  if not self.active then return end

  local box_x, box_y, box_w, box_h = 290, 180, 700, 360
  love.graphics.setColor(0, 0, 0, 0.65)
  love.graphics.rectangle("fill", 0, 0, 1280, 720)
  love.graphics.setColor(0.15, 0.15, 0.2)
  love.graphics.rectangle("fill", box_x, box_y, box_w, box_h, 10, 10)
  love.graphics.setColor(1, 1, 1)
  love.graphics.rectangle("line", box_x, box_y, box_w, box_h, 10, 10)

  love.graphics.print(self.dialogue:current_speaker() or "", box_x + 24, box_y + 20)
  love.graphics.printf(self.dialogue:current_line() or "", box_x + 24, box_y + 70, box_w - 48)

  local choices = self.dialogue:get_choices() or {}
  for index, entry in ipairs(choices) do
    local option_y = box_y + 190 + (index - 1) * 48
    local selected = index == self.selected
    love.graphics.setColor(selected and { 0.35, 0.35, 0.55 } or { 0.22, 0.22, 0.32 })
    love.graphics.rectangle("fill", box_x + 24, option_y, box_w - 48, 38, 6, 6)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print((selected and "> " or "  ") .. entry.choice.text, box_x + 38, option_y + 8)
  end

  love.graphics.setColor(0.7, 0.7, 0.7)
  love.graphics.print(Mando.boton("aceptar") .. " · " .. (#choices > 0 and "Elegir" or "Continuar"),
    box_x + 24, box_y + box_h - 32)
  love.graphics.setColor(1, 1, 1)
end

return DialogueView
