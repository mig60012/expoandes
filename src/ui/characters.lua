-- Modelos provisionales compartidos por retratos y paseo por la calle.
local Characters = {}
local colors = {
  Protagonista = { 0.22, 0.47, 0.68 }, Esposa = { 0.64, 0.32, 0.47 },
  Hija = { 0.45, 0.62, 0.36 }, Vagabundo = { 0.58, 0.43, 0.28 },
  ["Gota a gota"] = { 0.43, 0.31, 0.52 },
}
local portrait_paths = {
  Protagonista = "assets/personajes/protagonista.png",
  Esposa = "assets/personajes/esposa.png",
  Hija = "assets/personajes/hija.png",
  Vagabundo = "assets/personajes/vagabundo.png",
}
local portrait_cache = {}

local height_rules = {
  Protagonista = { screen = 0.70, available = 1.00 },
  Esposa = { screen = 0.58, available = 0.88 },
  Hija = { screen = 0.54, available = 0.82 },
  Vagabundo = { screen = 0.62, available = 0.90 },
}

local function model_bounds(name, bounds)
  local rule = height_rules[name] or { screen = 0.62, available = 0.90 }
  local screen_h = bounds.screen_h or (bounds.y + bounds.h)
  local height = math.min(screen_h * rule.screen, bounds.h * rule.available)
  return { x = bounds.x, y = bounds.y + bounds.h - height, w = bounds.w, h = height }
end
Characters.model_bounds = model_bounds

local function portrait(name)
  if portrait_cache[name] ~= nil then return portrait_cache[name] or nil end
  local path = portrait_paths[name]
  if not path then portrait_cache[name] = false; return nil end
  local ok, image = pcall(love.graphics.newImage, path)
  portrait_cache[name] = ok and image or false
  return portrait_cache[name] or nil
end

local function draw_asset(name, bounds, speaking, font)
  local g, image = love.graphics, portrait(name)
  if not image then return false end
  local x, y, w, h = bounds.x, bounds.y, bounds.w, bounds.h
  -- La altura narrativa manda; el ancho conserva la proporcion original y
  -- puede ocupar el espacio transparente entre ambos personajes.
  local scale = h / image:getHeight()
  local draw_w, draw_h = image:getWidth() * scale, image:getHeight() * scale
  g.setColor(1, 1, 1, speaking and 1 or 0.58)
  -- El ultimo pixel visible queda apoyado directamente sobre el dialogo.
  g.draw(image, x + (w - draw_w) / 2, y + h - draw_h, 0, scale, scale)
  return true
end

function Characters.draw(name, bounds, speaking, font, use_asset)
  bounds = model_bounds(name, bounds)
  if use_asset and draw_asset(name, bounds, speaking, font) then return end
  local g = love.graphics
  local c = colors[name] or colors.Protagonista
  local x, y, w, h = bounds.x, bounds.y, bounds.w, bounds.h
  g.setColor(c[1], c[2], c[3], speaking and 1 or 0.55)
  local cx, radius = x + w / 2, math.min(w * 0.17, h * 0.13)
  local head_y = y + h * 0.20
  g.setColor(0.76, 0.65, 0.54, speaking and 1 or 0.65)
  g.circle("fill", cx, head_y, radius)
  g.setColor(c[1], c[2], c[3], speaking and 1 or 0.65)
  g.rectangle("fill", cx - w * 0.22, head_y + radius + 6, w * 0.44, h * 0.34, 10, 10)
  g.rectangle("fill", cx - w * 0.28, head_y + radius + 15, w * 0.10, h * 0.34, 8, 8)
  g.rectangle("fill", cx + w * 0.18, head_y + radius + 15, w * 0.10, h * 0.34, 8, 8)
  g.setColor(0.16, 0.18, 0.23, 1)
  g.rectangle("fill", cx - w * 0.19, y + h * 0.64, w * 0.16, h * 0.36)
  g.rectangle("fill", cx + w * 0.03, y + h * 0.64, w * 0.16, h * 0.36)
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
