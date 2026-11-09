local Trabajo = {}

local DURACION = 5
local RUTA_FUENTE = "assets/transicion/Inicio/Asset-Regular.ttf"

function Trabajo:enter(context)
	self.context = context
	self.tiempo = 0
	self.fuente = love.graphics.newFont(RUTA_FUENTE, 32)
	self.fuente_chica = love.graphics.newFont(RUTA_FUENTE, 18)
end

function Trabajo:update(dt)
	self.tiempo = self.tiempo + dt
	if self.tiempo >= DURACION then
		self.context.state_machine:switch("casa")
	end
end

function Trabajo:draw()
	local ancho, alto = love.graphics.getDimensions()

	-- Esqueleto de la futura pantalla o sprite de trabajo.
	love.graphics.setColor(0.08, 0.08, 0.1)
	love.graphics.rectangle("fill", 0, 0, ancho, alto)

	love.graphics.setColor(0.2, 0.2, 0.25)
	love.graphics.rectangle("line", 24, 24, ancho - 48, alto - 48)

	love.graphics.setColor(1, 1, 1)
	love.graphics.setFont(self.fuente)
	love.graphics.printf("Trabajando", 0, alto / 2 - 24, ancho, "center")

	love.graphics.setColor(0.55, 0.55, 0.6)
	love.graphics.setFont(self.fuente_chica)
	love.graphics.printf("Aqui aparecera el proximo sprite", 0, alto / 2 + 28, ancho, "center")
end

return Trabajo
