local Plano = require("src/states/casino/plano")
local Colision = require("src/states/casino/colision")

local RADIO = Plano.jugador.radio
local ESTIRAMIENTO = Plano.estiramiento
local CERRADO, ABIERTO = 40, 2 * RADIO + 10

local function vertices_dentro(poligono, contenedor)
  for i = 1, #poligono, 2 do
    if not Colision.dentro(poligono[i], poligono[i + 1], contenedor) then
      return false
    end
  end
  return true
end

local function algun_vertice_dentro(poligono, contenedor)
  for i = 1, #poligono, 2 do
    if Colision.dentro(poligono[i], poligono[i + 1], contenedor) then
      return true
    end
  end
  return false
end

local function vertices_a_bordes(a, b)
  local minimo = math.huge
  for i = 1, #a, 2 do
    minimo = math.min(minimo, Colision.distancia(a[i], a[i + 1] * ESTIRAMIENTO, b, ESTIRAMIENTO))
  end
  return minimo
end

local function separacion(a, b)
  return math.min(vertices_a_bordes(a, b), vertices_a_bordes(b, a))
end

assert(Plano.vista.ancho < Plano.ancho and Plano.vista.alto < Plano.alto, "la camara ve solo una parte del salon")

local izquierda, derecha, abajo = math.huge, -math.huge, -math.huge
for i = 1, #Plano.suelo, 2 do
  izquierda, derecha = math.min(izquierda, Plano.suelo[i]), math.max(derecha, Plano.suelo[i])
  abajo = math.max(abajo, Plano.suelo[i + 1])
end
assert(izquierda <= 40 and derecha >= Plano.ancho - 40 and abajo >= Plano.alto - 40, "el piso llega hasta donde llega la camara")

local inicio = Plano.inicio
assert(Colision.dentro(inicio.x, inicio.y, Plano.suelo), "el inicio esta en el piso")
assert(not Colision.dentro(inicio.x, inicio.y, Plano.puerta.zona), "el inicio esta fuera de la puerta")
assert(vertices_dentro(Plano.puerta.zona, Plano.suelo), "la zona de la puerta esta en el piso")

local interacciones, total, cuantos = {}, 0, {}
for _, objeto in ipairs(Plano.objetos) do
  assert(vertices_dentro(objeto.choque, Plano.suelo), objeto.nombre .. " esta dentro del piso")
  assert(Colision.dentro(objeto.x, objeto.y, objeto.choque), objeto.nombre .. " tiene su centro dentro")
  assert(not algun_vertice_dentro(objeto.choque, Plano.puerta.zona), objeto.nombre .. " no tapa la puerta")
  assert(not algun_vertice_dentro(Plano.puerta.zona, objeto.choque), objeto.nombre .. " no pisa la puerta")
  assert(not Colision.dentro(inicio.x, inicio.y, objeto.choque), objeto.nombre .. " no tapa el inicio")
  cuantos[objeto.nombre] = (cuantos[objeto.nombre] or 0) + 1
  if objeto.interaccion then
    interacciones[objeto.interaccion] = true
    total = total + 1
    assert(objeto.etiqueta, objeto.nombre .. " tiene etiqueta")
  end
end

assert(total == 3, "por ahora solo se interactua con las tres mesas")
assert(interacciones.blackjack and interacciones.poker and interacciones.ruleta)
assert(cuantos.tragamonedas == 4 and cuantos.columna == 4, "la decoracion es minima y solida")
assert(cuantos.dueno == 1 and cuantos.barra == 1 and cuantos.caja == 1, "estan los lugares principales")

local function sin_rendija(a, b, que)
  local d = separacion(a, b)
  assert(d <= CERRADO or d >= ABIERTO, que .. " deja una rendija que parece pasillo: " .. d)
end

for i, objeto in ipairs(Plano.objetos) do
  sin_rendija(objeto.choque, Plano.suelo, objeto.nombre .. " y la pared")
  for j = i + 1, #Plano.objetos do
    local otro = Plano.objetos[j]
    assert(separacion(objeto.choque, otro.choque) > 0, objeto.nombre .. " pisa a " .. otro.nombre)
    assert(not algun_vertice_dentro(objeto.choque, otro.choque), objeto.nombre .. " se mete en " .. otro.nombre)
    assert(not algun_vertice_dentro(otro.choque, objeto.choque), otro.nombre .. " se mete en " .. objeto.nombre)
    sin_rendija(objeto.choque, otro.choque, objeto.nombre .. " y " .. otro.nombre)
  end
end

print("test_plano: ok")
