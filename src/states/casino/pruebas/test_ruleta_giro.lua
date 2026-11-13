local Giro = require("src/states/casino/ruleta/giro")

local VUELTA = 2 * math.pi

for _, casilla in ipairs({ 1, 2, 19, 37 }) do
  local g = Giro.nuevo(casilla, 37, 1.5)
  local rueda, pelota, radio, salto = Giro.estado(g, g.duracion)
  local hueco = ((pelota - rueda) % VUELTA) / (VUELTA / 37) + 1
  assert(math.abs(hueco - casilla) < 1e-6, "la pelota termina en su casilla")
  assert(radio == 0.71 and salto == 0, "la pelota termina quieta dentro de la casilla")
end

local g = Giro.nuevo(5, 37, 0)
local rueda0, pelota0, radio0 = Giro.estado(g, 0)
local rueda1, pelota1 = Giro.estado(g, 0.1)
assert(rueda0 == 0 and radio0 == 1.1, "la pelota empieza en el borde de la rueda")
assert(rueda1 > rueda0 and pelota1 < pelota0, "la rueda y la pelota giran en sentidos contrarios")
assert(select(2, Giro.estado(g, -1)) == pelota0, "antes de empezar no cambia nada")
assert(math.abs(Giro.estado(g, g.duracion + 5) - g.vueltas_rueda * VUELTA) < 1e-9, "la rueda da sus vueltas y se detiene")

local cuadro = 1 / 60
local antes_r, antes_p, antes_radio = Giro.estado(g, 0)
for t = cuadro, g.duracion, cuadro do
  local r, p, radio = Giro.estado(g, t)
  assert(math.abs(p - antes_p) < math.rad(20), "la pelota no avanza mas de 20 grados por cuadro")
  assert(math.abs(radio - antes_radio) < 0.03, "la pelota baja sin saltos")
  if t > g.llegada * g.duracion + cuadro then
    assert(math.abs((p - r) - (antes_p - antes_r)) < 1e-9, "despues de caer la pelota gira con la rueda")
  end
  antes_r, antes_p, antes_radio = r, p, radio
end

print("test_ruleta_giro: ok")
