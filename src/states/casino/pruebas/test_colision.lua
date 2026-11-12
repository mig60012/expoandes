local Colision = require("src/states/casino/colision")

local function cerca(a, b)
  return math.abs(a - b) < 0.01
end

local sala = { 0, 0, 200, 0, 200, 200, 0, 200 }
local caja = { 80, 80, 120, 80, 120, 120, 80, 120 }
local rampa = { 0, 0, 100, 0, 200, 200, 0, 200 }
local muro = { 100, 0, 102, 0, 102, 200, 100, 200 }

local x, y = Colision.mover(50, 50, 10, 0, 10, { sala })
assert(cerca(x, 60) and cerca(y, 50), "sin obstaculos se mueve completo")

x, y = Colision.mover(150, 50, 500, 0, 10, { sala })
assert(cerca(x, 190) and cerca(y, 50), "la pared detiene el circulo a un radio")

x, y = Colision.mover(40, 100, 100, 0, 10, { sala, caja })
assert(cerca(x, 70) and cerca(y, 100), "la caja detiene el circulo a un radio")

x, y = Colision.mover(60, 100, 200, 0, 10, { rampa })
assert(x > 60 and y > 100, "se desliza por la pared diagonal")
assert(Colision.dentro(x, y, rampa), "sigue dentro del piso despues de deslizarse")

x, y = Colision.mover(50, 100, 300, 0, 10, { sala, muro })
assert(cerca(x, 90), "un paso largo no atraviesa un muro delgado")

local piso_abierto = { 0, 0, 400, 0, 400, 400, 0, 400 }
local cuna_a, cuna_b = { 200, 100, 300, 100, 300, 130, 200, 130 }, { 200, 170, 300, 170, 300, 200, 200, 200 }
x, y = Colision.mover(100, 150, 400, 0, 25, { piso_abierto, cuna_a, cuna_b })
assert(x <= 200 and x > 100, "un hueco mas angosto que el circulo no deja pasar")

local rincon = { 0, 0, 300, 0, 150, 90 }
x, y = Colision.mover(150, 30, 0, 300, 12, { rincon })
local borde_izquierdo = math.abs(90 * x - 150 * y) / math.sqrt(90 * 90 + 150 * 150)
local borde_derecho = math.abs(90 * (300 - x) - 150 * y) / math.sqrt(90 * 90 + 150 * 150)
assert(borde_izquierdo >= 11.5 and borde_derecho >= 11.5, "en un rincon respeta las dos paredes a la vez")

assert(Colision.dentro(100, 100, sala))
assert(not Colision.dentro(300, 100, sala))
assert(Colision.dentro(50, 20, rampa))
assert(not Colision.dentro(150, 20, rampa))

local columna = {}
for i = 0, 15 do
  local angulo = i / 16 * math.pi * 2
  columna[#columna + 1] = 500 + math.cos(angulo) * 42
  columna[#columna + 1] = 500 + math.sin(angulo) * 42
end
for desfase = -50, 50, 7 do
  if math.abs(desfase) > 6 then
    x, y = 500 - 120, 500 + desfase
    for _ = 1, 300 do
      x, y = Colision.mover(x, y, 3.6, 0, 26, { columna })
    end
    assert(x > 560, "rodea una columna en vez de trabarse, desfase " .. desfase)
  end
end

assert(cerca(Colision.distancia(300, 100, sala), 100), "mide hasta el borde mas cercano")
assert(cerca(Colision.distancia(100, 300, sala, 2), 100 * 2 - 100), "mide con el piso estirado")

print("test_colision: ok")
