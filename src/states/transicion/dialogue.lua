local Dialogue = require("src/systems/dialogue")

local DialogueView = {}
DialogueView.__index = DialogueView

function DialogueView.new(context, filename)
  return setmetatable({
    dialogue = Dialogue.new(filename, context),
    active = false,
    selected = 1,
    error = nil,
  }, DialogueView)
end

function DialogueView:start()
  self.active = true
  self.selected = 1
  self.error = nil
end

function DialogueView:is_active()
  return self.active
end

function DialogueView:update(_dt)
  -- La conversación avanza únicamente mediante una entrada del jugador.
end

function DialogueView:keypressed(key)
  if not self.active then
    if key == "space" or key == "return" then
      self:start()
    end
    return
  end

  if key == "up" or key == "w" then
    self.selected = math.max(1, self.selected - 1)
    return
  end

  if key == "down" or key == "s" then
    local choices = self.dialogue:get_choices() or {}
    self.selected = math.min(math.max(1, #choices), self.selected + 1)
    return
  end

  if key ~= "space" and key ~= "return" then
    return
  end

  local choices = self.dialogue:get_choices() or {}
  local advanced, err
  if #choices > 0 then
    advanced, err = self.dialogue:choose(self.selected)
    self.selected = 1
  else
    advanced, err = self.dialogue:advance()
  end

  self.error = err
  if self.dialogue:is_finished() then
    self.active = false
  end

  return advanced, err
end

function DialogueView:draw()
  if not self.active then
    return
  end

  local width, height = love.graphics.getDimensions()
  love.graphics.setColor(0, 0, 0, 1)
  love.graphics.rectangle("fill", 0, height - height / 3, width, height / 3)
  love.graphics.setColor(1, 1, 1, 1)

  local speaker = self.dialogue:current_speaker()
  local line = self.dialogue:current_line() or ""
  love.graphics.print(speaker or "", 20, height - height / 3 + 10)
  love.graphics.printf(line, 20, height - height / 3 + 35, width - 40)

  local choices = self.dialogue:get_choices()
  if choices then
    for index, entry in ipairs(choices) do
      local marker = index == self.selected and "> " or "  "
      love.graphics.print(marker .. entry.choice.text, 40, height - 85 + index * 22)
    end
  end

  if self.error then
    love.graphics.setColor(1, 0.3, 0.3, 1)
    love.graphics.print(self.error, 20, height - 20)
    love.graphics.setColor(1, 1, 1, 1)
  end
end

return DialogueView
