local Plano = require("src/states/casino/plano")
local Colision = require("src/states/casino/colision")

local function vertices_dentro(poligono, contenedor)
  for i = 1, #poligono, 2 do
    if not Colision.dentro(poligono[i], poligono[i + 1], contenedor) then
      return false
    end
  end
  return true
end

local inicio = Plano.inicio
assert(Colision.dentro(inicio.x, inicio.y, Plano.suelo), "el inicio esta en el piso")
assert(not Colision.dentro(inicio.x, inicio.y, Plano.puerta.zona), "el inicio esta fuera de la puerta")
assert(vertices_dentro(Plano.puerta.zona, Plano.suelo), "la zona de la puerta esta en el piso")

local poligonos = { Plano.suelo }
local interacciones = {}
local total = 0
for _, objeto in ipairs(Plano.objetos) do
  if objeto.choque then
    assert(vertices_dentro(objeto.choque, Plano.suelo), objeto.nombre .. " esta dentro del piso")
    poligonos[#poligonos + 1] = objeto.choque
  end
  if objeto.interaccion then
    interacciones[objeto.interaccion] = true
    total = total + 1
  end
end

assert(total == 4, "solo hay cuatro cosas con las que interactuar")
assert(interacciones.dueno and interacciones.blackjack and interacciones.poker and interacciones.ruleta)

local x, y = Colision.mover(inicio.x, inicio.y, 0, 0, 28, poligonos)
assert(x == inicio.x and y == inicio.y, "el inicio no choca con nada")

print("test_plano: ok")
