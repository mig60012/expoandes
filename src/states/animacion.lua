local animacion = {}
local View = require("src/ui/story_dialogue")
local Data = require("src/data/dialogues/historia")
local Audio = require("src/systems/audio")

function animacion:enter(context, source, on_finished)
  self.context = context
  Audio.iniciar_bucle("menu_music")
  love.mouse.setVisible(true)
  love.mouse.setGrabbed(false)
  self.view = View.new(context, source or Data.opening, function()
    if on_finished then on_finished()
    else context.state_machine:switch("casa") end
  end, { black = true })
end

function animacion:draw()
  love.graphics.clear(0, 0, 0, 1)
  self.view:draw()
end

function animacion:keypressed(...) self.view:keypressed(...) end
function animacion:mousepressed(...) self.view:mousepressed(...) end
function animacion:leave()
  Audio.detener_canal("musica")
  self.view = nil
end

return animacion
