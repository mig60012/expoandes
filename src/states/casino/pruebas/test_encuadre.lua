local Encuadre = require("src/states/casino/encuadre")

local MUNDO_ANCHO, MUNDO_ALTO = 2400, 1350
local VISTA_ANCHO, VISTA_ALTO = 1536, 864
local VENTANAS = { { 1920, 1080 }, { 1280, 720 }, { 800, 600 }, { 2560, 1080 }, { 1366, 768 }, { 1080, 1920 }, { 3840, 2160 } }

for _, ventana in ipairs(VENTANAS) do
  local ancho, alto = ventana[1], ventana[2]
  local zoom = Encuadre.zoom(ancho, alto, VISTA_ANCHO, VISTA_ALTO)
  assert(ancho / zoom <= VISTA_ANCHO + 0.001 and alto / zoom <= VISTA_ALTO + 0.001, "la vista nunca es mas grande que la prevista")
  assert(ancho / zoom >= VISTA_ANCHO - 0.001 or alto / zoom >= VISTA_ALTO - 0.001, "la vista llena la ventana en un sentido")
  for x = -300, MUNDO_ANCHO + 300, 100 do
    for y = -300, MUNDO_ALTO + 300, 100 do
      local cx, cy = Encuadre.centro(x, y, ancho, alto, zoom, MUNDO_ANCHO, MUNDO_ALTO)
      local medio_x, medio_y = ancho / zoom / 2, alto / zoom / 2
      assert(cx - medio_x >= -0.001 and cx + medio_x <= MUNDO_ANCHO + 0.001, "no se ve fuera del mundo a los lados")
      assert(cy - medio_y >= -0.001 and cy + medio_y <= MUNDO_ALTO + 0.001, "no se ve fuera del mundo arriba o abajo")
    end
  end
end

local zoom = Encuadre.zoom(1920, 1080, VISTA_ANCHO, VISTA_ALTO)
local cx, cy = Encuadre.centro(1200, 700, 1920, 1080, zoom, MUNDO_ANCHO, MUNDO_ALTO)
assert(cx == 1200 and cy == 700, "en el centro del mundo sigue al objetivo")

local actual = 0
for _ = 1, 240 do
  local siguiente = Encuadre.suavizar(actual, 100, 1 / 60, 7)
  assert(siguiente >= actual and siguiente <= 100, "se acerca sin pasarse")
  actual = siguiente
end
assert(math.abs(actual - 100) < 0.1, "termina alcanzando el objetivo")

print("test_encuadre: ok")
