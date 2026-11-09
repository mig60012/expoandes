local Colision = {}

local function punto_cercano(px, py, ax, ay, bx, by)
  local abx, aby = bx - ax, by - ay
  local largo = abx * abx + aby * aby
  local t = largo > 0 and ((px - ax) * abx + (py - ay) * aby) / largo or 0
  t = math.max(0, math.min(1, t))
  return ax + abx * t, ay + aby * t
end

local function empujar(x, y, radio, poligono)
  local j = #poligono - 1
  for i = 1, #poligono, 2 do
    local cx, cy = punto_cercano(x, y, poligono[j], poligono[j + 1], poligono[i], poligono[i + 1])
    local dx, dy = x - cx, y - cy
    local distancia = math.sqrt(dx * dx + dy * dy)
    if distancia > 0 and distancia < radio then
      x, y = cx + dx / distancia * radio, cy + dy / distancia * radio
    end
    j = i
  end
  return x, y
end

function Colision.mover(x, y, dx, dy, radio, poligonos)
  local pasos = math.max(1, math.ceil(math.max(math.abs(dx), math.abs(dy)) / (radio / 2)))
  for _ = 1, pasos do
    x, y = x + dx / pasos, y + dy / pasos
    for _, poligono in ipairs(poligonos) do
      x, y = empujar(x, y, radio, poligono)
    end
  end
  return x, y
end

function Colision.dentro(x, y, poligono)
  local dentro = false
  local j = #poligono - 1
  for i = 1, #poligono, 2 do
    local xi, yi, xj, yj = poligono[i], poligono[i + 1], poligono[j], poligono[j + 1]
    if (yi > y) ~= (yj > y) and x < (xj - xi) * (y - yi) / (yj - yi) + xi then
      dentro = not dentro
    end
    j = i
  end
  return dentro
end

function Colision.cercano(x, y, objetos, alcance)
  local elegido, mejor = nil, alcance
  for _, objeto in ipairs(objetos) do
    local distancia = math.sqrt((objeto.x - x) ^ 2 + (objeto.y - y) ^ 2)
    if distancia <= mejor then
      elegido, mejor = objeto, distancia
    end
  end
  return elegido
end

return Colision
