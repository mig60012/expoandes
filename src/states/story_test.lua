local View = require("src/ui/story_dialogue")
local Data = require("src/data/dialogues/historia")

local Debug = {}

local entries = {
  { label = "Prologo", type = "opening" },
  { label = "Dia 1 · manana", type = "morning", day = 1 },
  { label = "Dia 2 · N1 = A", type = "morning", day = 2, N1 = "A" },
  { label = "Dia 2 · N1 = B", type = "morning", day = 2, N1 = "B" },
  { label = "Dia 2 · N1 = C", type = "morning", day = 2, N1 = "C" },
  { label = "Dia 3 · N2 = A", type = "morning", day = 3, N1 = "A", N2 = "A" },
  { label = "Dia 3 · N2 = B", type = "morning", day = 3, N1 = "B", N2 = "B" },
  { label = "Dia 3 · N2 = C", type = "morning", day = 3, N1 = "C", N2 = "C" },
  { label = "Dia 4 · N3 = A", type = "morning", day = 4, N3 = "A" },
  { label = "Dia 4 · N3 = B", type = "morning", day = 4, N3 = "B" },
  { label = "Dia 4 · N3 = C", type = "morning", day = 4, N3 = "C" },
  { label = "Dia 4 · N3 = D", type = "morning", day = 4, N3 = "D" },
  { label = "Dia 5 · manana", type = "morning", day = 5 },
  { label = "Final 1", type = "final", final = "final_1" },
  { label = "Final 2", type = "final", final = "final_2" },
  { label = "Final 3", type = "final", final = "final_3" },
  { label = "Final 4", type = "final", final = "final_4" },
}

local function has_story_test_flag()
  for _, value in ipairs(arg or {}) do
    if value == "--story-test" then return true end
  end
  return false
end

function Debug.enabled()
  return has_story_test_flag()
end

local function set_outcome(progress, key, value)
  if value then progress:set_outcome(key, value) end
end

function Debug:enter(context)
  self.context = context
  self.index = 1
  self.view = nil
  self:_reset_progress()
end

function Debug:_reset_progress()
  local progress = self.context.progress
  progress:reset()
  self.context.economy.money = 10
  self.context.time_of_day = 0
end

function Debug:_return_to_menu()
  self.view = nil
  self:_reset_progress()
end

function Debug:_launch(entry)
  self:_reset_progress()
  if entry.type == "opening" then
    self.context.state_machine:switch("animacion", Data.opening,
      function() self.context.state_machine:switch("story_test") end)
    return
  end

  if entry.type == "final" then
    local values = {
      final_1 = { debt = 0, points = 0 },
      final_2 = { debt = 60, points = 2 },
      final_3 = { debt = 60, points = 0 },
      final_4 = { debt = 100, points = 0 },
    }
    local preset = values[entry.final]
    self.context.progress:set_value("debt_percentage", preset.debt)
    self.context.progress:set_value("family_points", preset.points)
    self.context.state_machine:switch("finales")
    return
  end

  set_outcome(self.context.progress, "N1", entry.N1)
  set_outcome(self.context.progress, "N2", entry.N2)
  set_outcome(self.context.progress, "N3", entry.N3)
  self.view = View.new(self.context, Data.morning[entry.day],
    function() self:_return_to_menu() end)
end

function Debug:keypressed(key, _, isrepeat)
  if isrepeat then return end
  if self.view then
    if key == "escape" then self:_return_to_menu() else self.view:keypressed(key) end
    return
  end
  if key == "up" or key == "w" then
    self.index = math.max(1, self.index - 1)
  elseif key == "down" or key == "s" then
    self.index = math.min(#entries, self.index + 1)
  elseif key == "return" or key == "space" or key == "z" then
    self:_launch(entries[self.index])
  elseif key == "escape" then
    self.context.state_machine:switch("casa")
  end
end

function Debug:mousepressed(x, y, button)
  if self.view then
    if button == 1 then self.view:mousepressed(x, y, button) end
    return
  end
  if button ~= 1 then return end
  local _, h = love.graphics.getDimensions()
  local top, row = h * 0.17, 29
  local selected = math.floor((y - top + row * 0.5) / row) + 1
  if selected >= 1 and selected <= #entries then
    self.index = selected
    self:_launch(entries[self.index])
  end
end

function Debug:update(dt)
  if self.view then self.view:update(dt) end
end

function Debug:draw()
  local g = love.graphics
  local w, h = g.getDimensions()
  g.clear(0.035, 0.045, 0.07, 1)
  if self.view then self.view:draw(w, h); return end

  g.setColor(1, 1, 1, 1)
  g.setFont(love.graphics.newFont(28))
  g.printf("PRUEBAS DE HISTORIA", 40, h * 0.06, w - 80, "center")
  g.setFont(love.graphics.newFont(16))
  g.setColor(0.72, 0.78, 0.88, 1)
  g.printf("Arriba/Abajo o W/S · Enter para abrir · Esc para salir", 40, h * 0.12, w - 80, "center")

  local top, row = h * 0.17, 29
  for i, entry in ipairs(entries) do
    local y = top + (i - 1) * row
    g.setColor(i == self.index and { 0.25, 0.38, 0.55 } or { 0.10, 0.13, 0.20 })
    g.rectangle("fill", w * 0.18, y, w * 0.64, row - 3, 4, 4)
    g.setColor(1, 1, 1, 1)
    g.printf((i == self.index and "> " or "  ") .. entry.label, w * 0.20, y + 5, w * 0.60)
  end
end

function Debug:leave()
  self.view = nil
end

return Debug
