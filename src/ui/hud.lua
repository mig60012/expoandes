local Hud = {}
local cached_font, cached_size
local hidden_states = { animacion = true, finales = true }

function Hud.visible(state_name)
  return not hidden_states[state_name]
end

local function short(value)
  return string.format("%.2f", value or 0):gsub("0+$", ""):gsub("%.$", "")
end

function Hud.layout(w, h, content)
  local margin = math.max(10, math.floor(math.min(w, h) * 0.018))
  local gap = math.max(6, math.floor(margin * 0.55))
  local height = content and content.height or math.max(38, math.floor(h * 0.055))
  local width = content and content.width or math.max(180, math.floor(w * 0.18))
  width = math.min(width, w - margin * 2)
  return {
    debt = { x = margin, y = margin, w = width, h = height },
    family = { x = margin, y = margin + height + gap, w = width, h = height },
  }
end

local function panel(rect, label, progress, color)
  local g = love.graphics
  g.setColor(0.035, 0.045, 0.065, 0.90)
  g.rectangle("fill", rect.x, rect.y, rect.w, rect.h, 8, 8)
  g.setColor(0.18, 0.20, 0.25, 1)
  g.rectangle("fill", rect.x + 10, rect.y + rect.h - 11, rect.w - 20, 5, 3, 3)
  g.setColor(color)
  g.rectangle("fill", rect.x + 10, rect.y + rect.h - 11, (rect.w - 20) * progress, 5, 3, 3)
  g.setColor(1, 1, 1, 1)
  g.printf(label, rect.x + 12, rect.y + 7, rect.w - 24, "left")
end

function Hud.draw(context, state_name)
  if not Hud.visible(state_name) or not context or not context.economy or not context.progress then return end
  local g = love.graphics
  local w, h = g.getDimensions()
  local size = math.max(13, math.floor(math.min(w / 70, h / 40)))
  if not cached_font or cached_size ~= size then
    cached_font, cached_size = g.newFont(size), size
  end
  local debt = (context.rules and context.rules.debt_total) or 125
  local family_goal = (context.rules and context.rules.family_points_threshold) or 5
  local money = context.economy:get_money()
  local points = context.progress:get_value("family_points") or 0
  local debt_label = "Deuda: " .. short(money) .. " / " .. short(debt) .. " M"
  local family_label = "Familia: " .. short(points) .. " / " .. short(family_goal)
  local layout = Hud.layout(w, h, {
    width = math.ceil(math.max(cached_font:getWidth(debt_label), cached_font:getWidth(family_label)) + 24),
    height = cached_font:getHeight() + 22,
  })
  g.push("all")
  g.setFont(cached_font)
  panel(layout.debt, debt_label,
    math.max(0, math.min(1, money / math.max(1, debt))), { 0.72, 0.55, 0.24, 1 })
  panel(layout.family, family_label,
    math.max(0, math.min(1, points / math.max(1, family_goal))), { 0.66, 0.39, 0.49, 1 })
  g.pop()
end

return Hud
