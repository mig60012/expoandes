local ScreenTransition = {}
ScreenTransition.__index = ScreenTransition

local function clamp(value, minimum, maximum)
  return math.max(minimum, math.min(maximum, value))
end

local function smoothstep(value)
  return value * value * (3 - 2 * value)
end

function ScreenTransition.new(duration)
  return setmetatable({
    duration = duration or 1,
    phase = "idle",
    elapsed = 0,
  }, ScreenTransition)
end

function ScreenTransition:start()
  if self:is_active() then return false end
  self.phase = "out"
  self.elapsed = 0
  return true
end

function ScreenTransition:is_active()
  return self.phase ~= "idle"
end

function ScreenTransition:update(dt, at_black)
  if not self:is_active() then return end

  local half = self.duration / 2
  local remaining = math.max(0, dt or 0)

  if self.phase == "out" then
    local available = half - self.elapsed
    local consumed = math.min(remaining, available)
    self.elapsed = self.elapsed + consumed
    remaining = remaining - consumed

    if self.elapsed >= half then
      self.phase = "in"
      self.elapsed = 0
      if at_black then at_black() end
    end
  end

  if self.phase == "in" then
    self.elapsed = self.elapsed + remaining
    if self.elapsed >= half then
      self.phase = "idle"
      self.elapsed = 0
    end
  end
end

function ScreenTransition:alpha()
  if self.phase == "idle" then return 0 end

  local half = self.duration / 2
  local progress = clamp(self.elapsed / half, 0, 1)
  if self.phase == "out" then
    return smoothstep(progress)
  end
  return 1 - smoothstep(progress)
end

function ScreenTransition:draw()
  local alpha = self:alpha()
  if alpha <= 0 then return end

  local width, height = love.graphics.getDimensions()
  love.graphics.push("all")
  love.graphics.setBlendMode("alpha")
  love.graphics.setColor(0, 0, 0, alpha)
  love.graphics.rectangle("fill", 0, 0, width, height)
  love.graphics.pop()
end

return ScreenTransition
