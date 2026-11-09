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

assert(Colision.dentro(100, 100, sala))
assert(not Colision.dentro(300, 100, sala))
assert(Colision.dentro(50, 20, rampa))
assert(not Colision.dentro(150, 20, rampa))

local objetos = { { x = 10, y = 0 }, { x = 50, y = 0 } }
assert(Colision.cercano(0, 0, objetos, 30) == objetos[1], "elige el mas cercano")
assert(Colision.cercano(0, 0, objetos, 5) == nil, "nada fuera del alcance")
assert(Colision.cercano(45, 0, objetos, 30) == objetos[2])

print("test_colision: ok")
