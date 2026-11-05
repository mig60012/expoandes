local Player = {}
Player.__index = Player

function Player.new(x, y)
  return setmetatable({ x = x, y = y, speed = 100, size = 20 }, Player)
end

function Player:update(dt)
  local dx, dy = 0, 0

  if love.keyboard.isDown("a", "left") then dx = dx - 1 end
  if love.keyboard.isDown("d", "right") then dx = dx + 1 end
  if love.keyboard.isDown("w", "up") then dy = dy - 1 end
  if love.keyboard.isDown("s", "down") then dy = dy + 1 end

  self.x = self.x + dx * self.speed * dt
  self.y = self.y + dy * self.speed * dt
end

function Player:draw()
  love.graphics.rectangle("line", self.x - self.size / 2, self.y - self.size / 2,
    self.size, self.size)
end

return Player
