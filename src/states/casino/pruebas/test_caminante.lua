local Caminante = require("src/states/casino/caminante")

local function cerca(a, b)
  return math.abs(a - b) < 0.01
end

local sala = { 0, 0, 1000, 0, 1000, 1000, 0, 1000 }
local rombo = { 500, 0, 1000, 250, 500, 500, 0, 250 }

local function nuevo(x, y, poligono)
  return Caminante.new({ x = x, y = y, velocidad = 600, radio = 20, estiramiento = 2, poligonos = { poligono or sala } })
end

local function sostener(c, dx, dy, cuadros)
  for _ = 1, cuadros do
    c:mover(dx, dy, 1 / 60)
  end
end

local c = nuevo(500, 500)
c:mover(1, 0, 0.01)
assert(cerca(c.x, 506) and cerca(c.y, 500), "a los lados recorre toda su velocidad")

c = nuevo(500, 500)
c:mover(0, -1, 0.01)
assert(cerca(c.x, 500) and cerca(c.y, 497), "hacia arriba recorre la mitad en pantalla")

c = nuevo(500, 500)
c:mover(1, -1, 0.01)
local dx, dy = c.x - 500, c.y - 500
assert(cerca(dy / dx, -0.5), "la diagonal va paralela a las paredes")
assert(cerca(math.sqrt(dx * dx + (2 * dy) ^ 2), 6), "la diagonal no es mas rapida sobre el piso")

c = nuevo(500, 500)
c:mover(0, 0, 0.01)
assert(c.x == 500 and c.y == 500, "sin teclas no se mueve")

local lento, normal = nuevo(500, 500), nuevo(500, 500)
lento:mover(1, 0, 5)
normal:mover(1, 0, 1 / 30)
assert(cerca(lento.x, normal.x), "un cuadro lento no hace saltar al personaje")

c = nuevo(500, 500)
sostener(c, 1, 0, 500)
assert(cerca(c.x, 980), "a los lados el pie mide un radio")

c = nuevo(500, 500)
sostener(c, 0, 1, 500)
assert(cerca(c.y, 990), "en profundidad el pie mide medio radio")

c = nuevo(500, 100, rombo)
local inicio_y = c.y
sostener(c, 1, 1, 30)
assert(cerca((c.y - inicio_y) / (c.x - 500), 0.5), "camina paralelo a una pared diagonal sin rozarla")

c = nuevo(500, 250, rombo)
sostener(c, 1, -1, 400)
local distancia = math.abs(c.x * 0.5 - c.y + (0 - 500 * 0.5)) * 2 / math.sqrt(2)
assert(distancia >= 19.9 and distancia <= 20.1, "contra la pared se queda a un radio medido sobre el piso")

local cerca_mesa = { choque = { 200, 100, 300, 100, 300, 200, 200, 200 } }
local lejos_mesa = { choque = { 600, 100, 700, 100, 700, 200, 600, 200 } }
c = nuevo(150, 150)
assert(c:mas_cercano({ lejos_mesa, cerca_mesa }, 100) == cerca_mesa, "elige la mesa mas cercana a sus pies")
assert(c:mas_cercano({ lejos_mesa, cerca_mesa }, 30) == nil, "nada fuera del alcance")

local recta = { linea = { x = 150, y = 200, pendiente = -0.5 } }
assert(c:detras_de(recta), "por encima de la linea queda detras")
c = nuevo(150, 260)
assert(not c:detras_de(recta), "por debajo de la linea queda delante")
c = nuevo(250, 160)
assert(not c:detras_de(recta), "la linea inclinada cambia con la posicion")

print("test_caminante: ok")
