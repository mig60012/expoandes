local Game = require("src/game")


-- LOVE CALLBACKS
function love.load()
  Game.load()
end

function love.update(dt)
  Game.update(dt)
end

function love.draw()
  Game.draw()
end

function love.keypressed(key, scancode, isrepeat)
  Game.keypressed(key, scancode, isrepeat)
end

function love.keyreleased(key, scancode)
  Game.keyreleased(key, scancode)
end

function love.mousepressed(x, y, button, istouch, presses)
  Game.mousepressed(x, y, button, istouch, presses)
end

function love.mousemoved(x, y, dx, dy, istouch)
  Game.mousemoved(x, y, dx, dy, istouch)
end

function love.mousereleased(x, y, button, istouch, presses)
  Game.mousereleased(x, y, button, istouch, presses)
end
