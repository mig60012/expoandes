local Plano = require("src/states/casino/plano")
local Colision = require("src/states/casino/colision")
local Caminante = require("src/states/casino/caminante")

local RADIO = Plano.jugador.radio
local ESTIRAMIENTO = Plano.estiramiento
local TOLERANCIA = 1
local CELDA = 12
local DIRECCIONES = { { 1, 0 }, { 1, 1 }, { 0, 1 }, { -1, 1 }, { -1, 0 }, { -1, -1 }, { 0, -1 }, { 1, -1 } }

local poligonos, interactuables = { Plano.suelo }, {}
for _, objeto in ipairs(Plano.objetos) do
  poligonos[#poligonos + 1] = objeto.choque
  if objeto.interaccion then
    interactuables[#interactuables + 1] = objeto
  end
end

local function caminante(x, y)
  return Caminante.new({
    x = x,
    y = y,
    velocidad = Plano.jugador.velocidad,
    radio = RADIO,
    estiramiento = ESTIRAMIENTO,
    poligonos = poligonos,
  })
end

local function holgura(x, y)
  local minimo = math.huge
  for _, poligono in ipairs(poligonos) do
    minimo = math.min(minimo, Colision.distancia(x, y * ESTIRAMIENTO, poligono, ESTIRAMIENTO))
  end
  return minimo
end

local function revisar(x, y, que)
  assert(Colision.dentro(x, y, Plano.suelo), que .. ": salio del piso en " .. x .. "," .. y)
  for _, objeto in ipairs(Plano.objetos) do
    assert(not Colision.dentro(x, y, objeto.choque), que .. ": se metio en " .. objeto.nombre)
  end
  assert(holgura(x, y) >= RADIO - TOLERANCIA, que .. ": se pego de mas en " .. x .. "," .. y)
end

local function clave(x, y)
  return math.floor(x / CELDA) .. ":" .. math.floor(y * ESTIRAMIENTO / CELDA)
end

local sonda = caminante(Plano.inicio.x, Plano.inicio.y)
local visitado = { [clave(Plano.inicio.x, Plano.inicio.y)] = true }
local cola = { { x = Plano.inicio.x, y = Plano.inicio.y } }
local cabeza = 1
while cabeza <= #cola do
  local punto = cola[cabeza]
  cabeza = cabeza + 1
  revisar(punto.x, punto.y, "inundacion")
  for _, direccion in ipairs(DIRECCIONES) do
    sonda.x, sonda.y = punto.x, punto.y
    local c = sonda
    c:mover(direccion[1], direccion[2], 1 / 30)
    local k = clave(c.x, c.y)
    if not visitado[k] then
      visitado[k] = true
      cola[#cola + 1] = { x = c.x, y = c.y }
    end
  end
end
assert(#cola > 5000, "el salon se puede recorrer")

local en_puerta, elegibles = 0, {}
for _, punto in ipairs(cola) do
  if Colision.dentro(punto.x, punto.y, Plano.puerta.zona) then
    en_puerta = en_puerta + 1
  end
  sonda.x, sonda.y = punto.x, punto.y
  local elegido = sonda:mas_cercano(interactuables, Plano.jugador.alcance)
  if elegido then
    elegibles[elegido.interaccion] = (elegibles[elegido.interaccion] or 0) + 1
  end
end
assert(en_puerta > 10, "se puede llegar a la puerta")
for _, objeto in ipairs(interactuables) do
  assert((elegibles[objeto.interaccion] or 0) > 5, "se puede interactuar con " .. objeto.interaccion)
end

local function cubierto(x, y)
  local cx, cy = math.floor(x / CELDA), math.floor(y * ESTIRAMIENTO / CELDA)
  for i = -2, 2 do
    for j = -2, 2 do
      if visitado[(cx + i) .. ":" .. (cy + j)] then
        return true
      end
    end
  end
  return false
end

for x = 24, Plano.ancho - 24, 16 do
  for y = 400, Plano.alto - 12, 8 do
    local libre = Colision.dentro(x, y, Plano.suelo) and holgura(x, y) >= RADIO + 6
    for _, objeto in ipairs(Plano.objetos) do
      libre = libre and not Colision.dentro(x, y, objeto.choque)
    end
    if libre then
      assert(cubierto(x, y), "hay piso libre que no se alcanza en " .. x .. "," .. y)
    end
  end
end

local function linea_vertical(x, poligono)
  local minimo, maximo = math.huge, -math.huge
  local j = #poligono - 1
  for i = 1, #poligono, 2 do
    local ax, ay, bx, by = poligono[j], poligono[j + 1], poligono[i], poligono[i + 1]
    if (ax <= x) ~= (bx <= x) then
      local y = ay + (by - ay) * (x - ax) / (bx - ax)
      minimo, maximo = math.min(minimo, y), math.max(maximo, y)
    end
    j = i
  end
  return minimo, maximo
end

for _, punto in ipairs(cola) do
  sonda.x, sonda.y = punto.x, punto.y
  for _, objeto in ipairs(interactuables) do
    local arriba, abajo = linea_vertical(punto.x, objeto.choque)
    if arriba ~= math.huge then
      if punto.y < arriba then
        assert(sonda:detras_de(objeto), "por encima de " .. objeto.nombre .. " queda detras")
      elseif punto.y > abajo then
        assert(not sonda:detras_de(objeto), "por debajo de " .. objeto.nombre .. " queda delante")
      end
    end
  end
end

local semilla = 20261109
local function azar(n)
  semilla = (semilla * 1103515245 + 12345) % 2147483648
  return semilla % n + 1
end

local PASOS_DE_TIEMPO = { 1 / 240, 1 / 60, 1 / 30, 0.25, 2 }
local c = caminante(Plano.inicio.x, Plano.inicio.y)
local direccion, restantes = DIRECCIONES[1], 0
for _ = 1, 30000 do
  if restantes == 0 then
    direccion, restantes = DIRECCIONES[azar(#DIRECCIONES)], azar(120)
  end
  c:mover(direccion[1], direccion[2], PASOS_DE_TIEMPO[azar(#PASOS_DE_TIEMPO)])
  restantes = restantes - 1
  revisar(c.x, c.y, "caminata al azar")
end

for i = 1, #cola, math.max(1, math.floor(#cola / 60)) do
  for _, sentido in ipairs(DIRECCIONES) do
    local empuje = caminante(cola[i].x, cola[i].y)
    for _ = 1, 30 do
      empuje:mover(sentido[1], sentido[2], 1 / 30)
      revisar(empuje.x, empuje.y, "empuje sostenido")
    end
  end
end

print("test_recorrido: ok")
