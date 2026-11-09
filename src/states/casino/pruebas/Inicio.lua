local Inicio = {}

local RUTAS_FONDOS = {
	"assets/transicion/Inicio/fondo1inicio.jpg",
	"assets/transicion/Inicio/fondo2inicio.jpg",
	"assets/transicion/Inicio/fondo5inicio.png",
	"assets/transicion/Inicio/fondo6inicio.jpg",
}
local ultimo_fondo
local RUTA_FUENTE_TITULO = "assets/transicion/Inicio/RubikGlitch-Regular.ttf"
local RUTA_MUSICA = "assets/transicion/Inicio/Musica/Musica menu.mp3"
local DURACION_ANIMACION_TITULO = 0.8

function Inicio:enter(context)
	self.context = context
	self.fondo = nil
	self.musica = nil
	self.tiempo_titulo = 0
	self.fuente_titulo = love.graphics.newFont(RUTA_FUENTE_TITULO, 100)
	self.fuente_boton = love.graphics.newFont(26)
	self.hover_boton = false
	self.hover_titulo = false

	if love.filesystem.getInfo(RUTA_MUSICA) then
		self.musica = love.audio.newSource(RUTA_MUSICA, "stream")
		self.musica:setLooping(true)
		self.musica:play()
	end

	local fondos_disponibles = {}
	for _, ruta in ipairs(RUTAS_FONDOS) do
		if love.filesystem.getInfo(ruta) then
			table.insert(fondos_disponibles, ruta)
		end
	end

	if #fondos_disponibles > 0 then
		local indice = love.math.random(#fondos_disponibles)
		local ruta = fondos_disponibles[indice]
		if #fondos_disponibles > 1 and ruta == ultimo_fondo then
			indice = (indice % #fondos_disponibles) + 1
			ruta = fondos_disponibles[indice]
		end
		ultimo_fondo = ruta
		self.fondo = love.graphics.newImage(ruta)
	end
end

function Inicio:leave()
	if self.musica then
		self.musica:stop()
	end
end

function Inicio:update(dt)
	self.tiempo_titulo = math.min(self.tiempo_titulo + dt, DURACION_ANIMACION_TITULO)

	local ancho, alto = love.graphics.getDimensions()
	local boton_ancho, boton_alto = 280, 64
	local boton_x = (ancho - boton_ancho) / 2
	local boton_y = alto / 2 + 70
	local mouse_x, mouse_y = love.mouse.getPosition()
	local titulo_texto = "EASY TO FALL"
	local titulo_ancho = self.fuente_titulo:getWidth(titulo_texto)
	local titulo_alto = self.fuente_titulo:getHeight()
	local titulo_x = (ancho - titulo_ancho) / 2
	local titulo_y = alto / 2 - 75 - titulo_alto / 2

	self.hover_boton = mouse_x >= boton_x and mouse_x <= boton_x + boton_ancho
		and mouse_y >= boton_y and mouse_y <= boton_y + boton_alto
	self.hover_titulo = mouse_x >= titulo_x and mouse_x <= titulo_x + titulo_ancho
		and mouse_y >= titulo_y and mouse_y <= titulo_y + titulo_alto
end

function Inicio:draw()
	local ancho, alto = love.graphics.getDimensions()

	love.graphics.setColor(0.08, 0.06, 0.05)
	love.graphics.rectangle("fill", 0, 0, ancho, alto)

	if self.fondo then
		local escala = math.max(ancho / self.fondo:getWidth(), alto / self.fondo:getHeight())
		local fondo_ancho = self.fondo:getWidth() * escala
		local fondo_alto = self.fondo:getHeight() * escala
		love.graphics.setColor(1, 1, 1)
		love.graphics.draw(self.fondo, (ancho - fondo_ancho) / 2, (alto - fondo_alto) / 2, 0, escala, escala)
	end

	love.graphics.setColor(0, 0, 0, 0.35)
	love.graphics.rectangle("fill", 0, 0, ancho, alto)

	love.graphics.setColor(0, 0, 0)
	love.graphics.setFont(self.fuente_titulo)
	local progreso = self.tiempo_titulo / DURACION_ANIMACION_TITULO
	local escala_titulo = 0.1 + (0.9 * progreso)
	if self.hover_titulo then
		escala_titulo = escala_titulo * 0.88
	end
	local titulo_ancho = self.fuente_titulo:getWidth("EASY TO FALL")
	local titulo_alto = self.fuente_titulo:getHeight()
	love.graphics.push()
	love.graphics.translate(ancho / 2, alto / 2 - 75)
	love.graphics.scale(escala_titulo, escala_titulo)
	love.graphics.print("EASY TO FALL", -titulo_ancho / 2, -titulo_alto / 2)
	love.graphics.pop()

	local boton_ancho, boton_alto = 280, 64
	local boton_x = (ancho - boton_ancho) / 2
	local boton_y = alto / 2 + 70
	local escala_boton = self.hover_boton and 0.92 or 1
	local boton_dibujado_ancho = boton_ancho * escala_boton
	local boton_dibujado_alto = boton_alto * escala_boton
	local boton_dibujado_x = ancho / 2 - boton_dibujado_ancho / 2
	local boton_dibujado_y = boton_y + boton_alto / 2 - boton_dibujado_alto / 2
	love.graphics.setColor(0, 0, 0)
	love.graphics.rectangle("fill", boton_dibujado_x, boton_dibujado_y, boton_dibujado_ancho, boton_dibujado_alto, 8, 8)

	love.graphics.setColor(1, 1, 1)
	love.graphics.setFont(self.fuente_boton)
	local texto_boton = "INICIAR PARTIDA"
	local texto_ancho = self.fuente_boton:getWidth(texto_boton)
	local texto_alto = self.fuente_boton:getHeight()
	local escala_texto = math.min(
		1,
		(boton_ancho - 24) / texto_ancho,
		(boton_alto - 12) / texto_alto
	)
	love.graphics.push()
	love.graphics.translate(ancho / 2, boton_y + boton_alto / 2)
	love.graphics.scale(escala_texto * escala_boton, escala_texto * escala_boton)
	love.graphics.print(texto_boton, -texto_ancho / 2, -texto_alto / 2)
	love.graphics.pop()
end

function Inicio:mousepressed(x, y, button)
	if button ~= 1 then return end

	local ancho, alto = love.graphics.getDimensions()
	local boton_ancho, boton_alto = 280, 64
	local boton_x = (ancho - boton_ancho) / 2
	local boton_y = alto / 2 + 70

	if x >= boton_x and x <= boton_x + boton_ancho
		and y >= boton_y and y <= boton_y + boton_alto then
		self.context.state_machine:switch("casa")
	end
end

return Inicio
