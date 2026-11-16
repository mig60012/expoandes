local FinalEvaluation = require("src/systems/final_evaluation")
local FinalData = require("src/data/dialogues/finals")
local Script = require("src/data/dialogues/historia")
local View = require("src/ui/story_dialogue")
local Mando = require("src/systems/mando")
local Audio = require("src/systems/audio")

local Finales = {}

function Finales:enter(context)
  self.context = context
  Audio.detener_todo()
  self.id = FinalEvaluation.evaluate(context)
  self.data = FinalData[self.id]
  self.font = love.graphics.newFont(28)
  self.small_font = love.graphics.newFont(18)
  self.done = false
  love.mouse.setVisible(true)
  love.mouse.setGrabbed(false)
  if self.id == "final_4" then
    -- La elección del epílogo no altera las reglas ni las probabilidades de
    -- las mesas normales. El resultado se narra después de elegir la mesa.
    local choices = {}
    for _, game in ipairs({ "Ruleta", "Blackjack", "Póker" }) do
      choices[#choices + 1] = { text = "Una última apuesta: " .. game, action = game, next = "perdida",
      }
    end
    self.view = View.new(context, { start = "apuesta", nodes = {
      apuesta = { speaker = "Protagonista", text = "La deuda ya está pagada. Podría irme, pero todavía pienso que puedo ganar un poco más.", choices = choices },
      perdida = { speaker = "Narrador", text = "La última apuesta termina en derrota. He vuelto a perder lo que había conseguido.", ending = true },
    } }, function(view, choice)
      self.last_game = choice and choice.action
      self:start_ending()
    end, { black = true })
  else self:start_ending() end
end

function Finales:start_ending()
  self.view = View.new(self.context, Script.endings[self.id], function() self.done = true end, { black = true })
end

function Finales:update(_dt)
end

function Finales:keypressed(key, scancode, isrepeat)
  if self.done and key == "r" and not isrepeat then require("src/game").load()
  elseif not self.done then self.view:keypressed(key, scancode, isrepeat) end
end

function Finales:mousepressed(...) if not self.done then self.view:mousepressed(...) end end

function Finales:draw()
  local w, h = love.graphics.getDimensions()
  love.graphics.clear(0, 0, 0, 1)
  if not self.done then self.view:draw(w, h); return end
  love.graphics.setColor(1, 1, 1)
  love.graphics.setFont(self.font)
  love.graphics.printf(self.data.title, 40, h * 0.28, w - 80, "center")
  love.graphics.setFont(self.small_font)
  love.graphics.printf(self.data.text, 100, h * 0.46, w - 200, "center")
  love.graphics.printf(Mando.boton("reiniciar") .. " · Nueva partida", 40, h * 0.78, w - 80, "center")
end

return Finales
