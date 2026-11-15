local Trabajo = {}
local View = require("src/ui/story_dialogue")
local Data = require("src/data/dialogues/historia")

local DURACION = 5

function Trabajo:enter(context)
	self.context = context
	self.view = nil
	if context.story then
		self.view = View.new(context, Data.work, function() context.story:work_complete() end, { black = true })
		return
	end
	self.tiempo = 0
	self.fuente = love.graphics.newFont(32)
	self.fuente_chica = love.graphics.newFont(18)
end

function Trabajo:update(dt)
	if self.view then return end
	self.tiempo = self.tiempo + dt
	if self.tiempo >= DURACION then
		local day_flow = self.context.day_flow
		if day_flow and day_flow:is_active() then
			day_flow:record_work()
			if self.context.progress:get_value("casino_games_today") == 3 then
				local finished = day_flow:finish_day()
				if finished then
					day_flow:advance_after_finished_day()
					self.context.time_of_day = 0
				end
			end
		end
		self.context.state_machine:switch("casa")
	end
end

function Trabajo:draw()
	if self.view then
		love.graphics.clear(0, 0, 0, 1)
		self.view:draw()
		return
	end
	local ancho, alto = love.graphics.getDimensions()

	-- Esqueleto de la futura pantalla o sprite de trabajo.
	love.graphics.setColor(0.08, 0.08, 0.1)
	love.graphics.rectangle("fill", 0, 0, ancho, alto)

	love.graphics.setColor(0.2, 0.2, 0.25)
	love.graphics.rectangle("line", 24, 24, ancho - 48, alto - 48)

	love.graphics.setColor(1, 1, 1)
	love.graphics.setFont(self.fuente)
	love.graphics.printf("Se fue al trabajo", 0, alto / 2 - 24, ancho, "center")

	love.graphics.setColor(0.55, 0.55, 0.6)
	love.graphics.setFont(self.fuente_chica)
	love.graphics.printf("Aqui aparecera el proximo sprite", 0, alto / 2 + 28, ancho, "center")
end

function Trabajo:keypressed(...) if self.view then self.view:keypressed(...) end end
function Trabajo:mousepressed(...) if self.view then self.view:mousepressed(...) end end
function Trabajo:leave() self.view = nil end

return Trabajo
