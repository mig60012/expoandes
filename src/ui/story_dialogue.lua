local Dialogue = require("src/systems/dialogue")
local Characters = require("src/ui/characters")
local View = {}
View.__index = View

function View.layout(w, h, choices, lines)
  local margin = w * 0.05
  local gap = math.max(8, math.min(14, h / 60))
  local font = math.max(12, math.floor(math.min(w / 64, h / 36)))
  local small = math.max(11, math.floor(math.min(w / 76, h / 44)))
  local row = math.max(26, math.min(38, small * 1.5 + 8))
  local header, text_height, hint = small * 1.2, (lines or 2) * font * 1.3, small * 1.2
  local options_height = choices > 0 and gap + choices * row + (choices - 1) * 5 or 0
  local panel_height = gap * 2 + header + gap * 0.5 + text_height + options_height + gap * 0.7 + hint
  local panel_y = h - gap - panel_height
  local portrait_y = h * 0.07
  local portrait_height = math.min(h * 0.52, panel_y - portrait_y - gap * 1.5)
  local text_y = panel_y + gap + header + gap * 0.5
  local result = {
    portraits = {
      { x = w * 0.08, y = portrait_y, w = w * 0.29, h = portrait_height },
      { x = w * 0.63, y = portrait_y, w = w * 0.29, h = portrait_height },
    },
    panel = { x = margin, y = panel_y, w = w - margin * 2, h = panel_height },
    choices = {}, text_width = w - margin * 2 - gap * 2,
    row = row, gap = gap, speaker_y = panel_y + gap, text_y = text_y,
    hint_y = panel_y + panel_height - gap - hint,
  }
  for i = 1, choices do
    result.choices[i] = { x = margin + gap, y = text_y + text_height + gap + (i - 1) * (row + 5),
      w = result.text_width, h = row }
  end
  return result
end

function View:_layout(choices)
  local _, breaks = self.pages[self.page]:gsub("\n", "")
  return View.layout(self.width, self.height, self.page == #self.pages and choices or 0, breaks + 1)
end

function View.new(context, source, on_finished, options)
  return setmetatable({ dialogue = source and Dialogue.new(source, context), active = source ~= nil,
    selected = 1, page = 1, on_finished = on_finished, black = options and options.black,
    last_choice = nil, partner = false }, View)
end

function View:is_active() return self.active end
function View:update(_dt) end

function View:_refresh(w, h)
  if not self.active then return end
  w, h = w or self.width, h or self.height
  if not w then w, h = love.graphics.getDimensions() end
  if self.width ~= w or self.height ~= h or not self.font then
    self.width, self.height = w, h
    self.font = love.graphics.newFont(math.max(12, math.floor(math.min(w / 64, h / 36))))
    self.small = love.graphics.newFont(math.max(11, math.floor(math.min(w / 76, h / 44))))
    self.cache_key = nil
  end
  local node = self.dialogue:current_node() or {}
  local key = tostring(self.dialogue.current_id or self.dialogue.current) .. ":" .. (self.dialogue:current_line() or "")
  if self.cache_key ~= key then
    self.cache_key = key
    self.page = 1
    if node.partner ~= nil then self.partner = node.partner end
    local speaker = self.dialogue:current_speaker()
    if speaker and speaker ~= "Protagonista" and speaker ~= "Narrador" then self.partner = speaker end
    if speaker == "Narrador" then self.partner = false end
    local width = self.black and w * 0.86 or View.layout(w, h, 0).text_width
    local _, lines = self.font:getWrap(self.dialogue:current_line() or "", width)
    if #lines == 0 then lines = { "" } end
    self.pages = {}
    for i = 1, #lines, 2 do self.pages[#self.pages + 1] = lines[i] .. (lines[i + 1] and "\n" .. lines[i + 1] or "") end
  end
end

function View:_finish()
  if self.active and self.dialogue:is_finished() then
    self.active = false
    if self.on_finished then self.on_finished(self, self.last_choice) end
  end
end

function View:_advance(choice)
  self:_refresh()
  if self.page < #self.pages then self.page = self.page + 1; return end
  local choices = self.dialogue:get_choices() or {}
  local ok, err
  if #choices > 0 then
    local entry = choices[choice or self.selected]
    if not entry then return end
    ok, err = self.dialogue:choose(choice or self.selected)
    if ok then self.last_choice = entry.choice; self.selected = 1 end
  else ok, err = self.dialogue:advance() end
  self.error = err
  self:_finish()
  if self.active then self:_refresh() end
end

function View:keypressed(key, _, isrepeat)
  if not self.active or isrepeat then return end
  self:_refresh()
  local choices = self.dialogue:get_choices() or {}
  if key == "up" or key == "w" then self.selected = math.max(1, self.selected - 1)
  elseif key == "down" or key == "s" then self.selected = math.min(math.max(1, #choices), self.selected + 1)
  elseif key == "return" or key == "space" or key == "z" then self:_advance() end
end

function View:mousepressed(x, y, button)
  if not self.active or button ~= 1 then return end
  self:_refresh()
  local choices = self.dialogue:get_choices() or {}
  if self.page < #self.pages or #choices == 0 then self:_advance(); return end
  local layout = self:_layout(#choices)
  for i, rect in ipairs(layout.choices) do
    if x >= rect.x and x <= rect.x + rect.w and y >= rect.y and y <= rect.y + rect.h then
      self:_advance(i)
      return
    end
  end
end

function View:draw(w, h)
  if not self.active then return end
  if not w then w, h = love.graphics.getDimensions() end
  self:_refresh(w, h)
  w, h = self.width, self.height
  local g, speaker = love.graphics, self.dialogue:current_speaker() or ""
  g.push("all")
  g.setColor(0, 0, 0, self.black and 1 or 0.48)
  g.rectangle("fill", 0, 0, w, h)
  local choices = self.dialogue:get_choices() or {}
  if self.black then
    g.setFont(self.small)
    g.setColor(0.75, 0.75, 0.80, 1)
    g.printf(speaker, w * 0.07, h * 0.34, w * 0.86, "center")
    g.setFont(self.font)
    g.setColor(1, 1, 1, 1)
    g.printf(self.pages[self.page], w * 0.07, h * 0.44, w * 0.86, "center")
    g.setFont(self.small)
    if self.page == #self.pages then
      local layout = self:_layout(#choices)
      for i, entry in ipairs(choices) do
        local rect = layout.choices[i]
        g.setColor(i == self.selected and { 0.22, 0.28, 0.37 } or { 0.09, 0.11, 0.15 })
        g.rectangle("fill", rect.x, rect.y, rect.w, rect.h, 4, 4)
        g.setColor(1, 1, 1, 1)
        g.printf(entry.choice.text, rect.x + 8, rect.y + 4, rect.w - 16, "center")
      end
    end
    g.setColor(0.8, 0.8, 0.85, 1)
    g.printf(#choices > 0 and "↑ / ↓ · Elegir    Enter / Espacio / Z · Confirmar" or "Enter / Espacio / Z · Continuar",
      0, h * (#choices > 0 and 0.96 or 0.87), w, "center")
  else
    local layout = self:_layout(#choices)
    Characters.draw("Protagonista", layout.portraits[1], speaker == "Protagonista", self.font)
    if self.partner then Characters.draw(self.partner, layout.portraits[2], speaker == self.partner, self.font) end
    local panel = layout.panel
    g.setColor(0.06, 0.075, 0.11, 0.98)
    g.rectangle("fill", panel.x, panel.y, panel.w, panel.h, 10, 10)
    g.setColor(0.68, 0.73, 0.82, 1)
    g.setLineWidth(2)
    g.rectangle("line", panel.x, panel.y, panel.w, panel.h, 10, 10)
    g.setFont(self.small)
    g.setColor(0.94, 0.78, 0.48, 1)
    g.print(speaker, panel.x + layout.gap, layout.speaker_y)
    g.setFont(self.font)
    g.setColor(1, 1, 1, 1)
    g.printf(self.pages[self.page], panel.x + layout.gap, layout.text_y, layout.text_width)
    if self.page == #self.pages then
      for i, entry in ipairs(choices) do
        local rect = layout.choices[i]
        g.setColor(i == self.selected and { 0.27, 0.36, 0.48 } or { 0.13, 0.17, 0.23 })
        g.rectangle("fill", rect.x, rect.y, rect.w, rect.h, 5, 5)
        g.setColor(1, 1, 1, 1)
        g.setFont(self.small)
        g.printf((i == self.selected and "> " or "") .. entry.choice.text, rect.x + 8, rect.y + 4, rect.w - 16)
      end
    end
    g.setFont(self.small)
    g.setColor(0.75, 0.79, 0.85, 1)
    local hint = #choices > 0 and self.page == #self.pages and "↑ / ↓ · Elegir    Enter / Espacio / Z · Confirmar"
      or "Enter / Espacio / Z · Continuar"
    g.printf(self.error or hint, panel.x + layout.gap, layout.hint_y, layout.text_width)
  end
  g.pop()
end

return View
