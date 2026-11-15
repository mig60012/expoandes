-- Modelos provisionales compartidos por retratos y paseo por la calle.
local Characters = {}
local colors = {
  Protagonista = { 0.22, 0.47, 0.68 }, Esposa = { 0.64, 0.32, 0.47 },
  Hija = { 0.45, 0.62, 0.36 }, Vagabundo = { 0.58, 0.43, 0.28 },
  ["Gota a gota"] = { 0.43, 0.31, 0.52 },
}

function Characters.draw(name, bounds, speaking, font)
  local g = love.graphics
  local c = colors[name] or colors.Protagonista
  local x, y, w, h = bounds.x, bounds.y, bounds.w, bounds.h
  g.setColor(0.035, 0.045, 0.065, 0.88)
  g.rectangle("fill", x, y, w, h, 12, 12)
  g.setColor(c[1], c[2], c[3], speaking and 1 or 0.55)
  g.setLineWidth(speaking and 3 or 1)
  g.rectangle("line", x, y, w, h, 12, 12)
  local cx, radius = x + w / 2, math.min(w * 0.17, h * 0.13)
  local head_y = y + h * 0.24
  g.setColor(0.76, 0.65, 0.54, speaking and 1 or 0.65)
  g.circle("fill", cx, head_y, radius)
  g.setColor(c[1], c[2], c[3], speaking and 1 or 0.65)
  g.rectangle("fill", cx - w * 0.22, head_y + radius + 6, w * 0.44, h * 0.31, 10, 10)
  g.rectangle("fill", cx - w * 0.28, head_y + radius + 15, w * 0.10, h * 0.30, 8, 8)
  g.rectangle("fill", cx + w * 0.18, head_y + radius + 15, w * 0.10, h * 0.30, 8, 8)
  g.setColor(0.16, 0.18, 0.23, 1)
  g.rectangle("fill", cx - w * 0.19, y + h * 0.63, w * 0.16, h * 0.20)
  g.rectangle("fill", cx + w * 0.03, y + h * 0.63, w * 0.16, h * 0.20)
  g.setFont(font)
  g.setColor(1, 1, 1, 1)
  g.printf(name, x + 6, y + h - font:getHeight() - 14, w - 12, "center")
end

function Characters.has_car(context)
  return context and context.progress and not context.progress:get_flag("car_sold") or false
end

function Characters.travel_speed(context, height)
  return height / 4 * (Characters.has_car(context) and 2 or 1)
end

function Characters.world(x, y, height, car, facing)
  local g = love.graphics
  if car then
    g.push("all")
    g.translate(x + (facing == -1 and height * 1.85 or 0), y)
    g.scale(facing == -1 and -height or height, height)
    -- Perfil de sedan: maletero, techo elevado, parabrisas inclinado y capo.
    g.setColor(0.04, 0.06, 0.08, 0.25)
    g.ellipse("fill", 0.94, 0.96, 0.90, 0.08)
    g.setColor(0.10, 0.28, 0.45, 1)
    g.polygon("fill", 0.02,0.49, 0.36,0.43, 0.56,0.13, 1.12,0.13,
      1.40,0.43, 1.77,0.49, 1.85,0.65, 1.79,0.82, 0.07,0.82, 0.00,0.68)
    g.setColor(0.24, 0.51, 0.72, 1)
    g.polygon("fill", 0.05,0.52, 0.39,0.48, 1.39,0.48, 1.75,0.54,
      1.79,0.70, 0.05,0.70)
    g.setColor(0.63, 0.81, 0.89, 1)
    g.polygon("fill", 0.45,0.42, 0.62,0.20, 0.86,0.20, 0.86,0.42)
    g.polygon("fill", 0.92,0.20, 1.09,0.20, 1.30,0.42, 0.92,0.42)
    g.setColor(0.13, 0.21, 0.27, 1)
    g.setLineWidth(0.012)
    g.line(0.88,0.46, 0.88,0.71)
    g.line(1.35,0.47, 1.35,0.70)
    g.setColor(0.85, 0.86, 0.82, 1)
    g.rectangle("fill", 0.94,0.51, 0.11,0.025)
    g.rectangle("fill", 1.70,0.59, 0.12,0.08)
    g.setColor(0.85, 0.18, 0.15, 1)
    g.rectangle("fill", 0.02,0.56, 0.10,0.08)
    for _, wheel in ipairs({0.38, 1.47}) do
      g.setColor(0.045, 0.055, 0.065, 1)
      g.circle("fill", wheel, 0.80, 0.18)
      g.setColor(0.60, 0.65, 0.69, 1)
      g.circle("fill", wheel, 0.80, 0.10)
      g.setColor(0.24, 0.29, 0.33, 1)
      g.circle("fill", wheel, 0.80, 0.035)
    end
    g.pop()
  else
    g.setColor(0.76, 0.65, 0.54, 1)
    g.circle("fill", x + height * 0.22, y + height * 0.15, height * 0.14)
    g.setColor(0.22, 0.47, 0.68, 1)
    g.rectangle("fill", x, y + height * 0.30, height * 0.44, height * 0.45)
    g.setColor(0.16, 0.18, 0.23, 1)
    g.rectangle("fill", x, y + height * 0.75, height * 0.16, height * 0.25)
    g.rectangle("fill", x + height * 0.28, y + height * 0.75, height * 0.16, height * 0.25)
  end
end

return Characters
