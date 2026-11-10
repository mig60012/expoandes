local Colision = {}

local REPETICIONES = 6

local function punto_cercano(px, py, ax, ay, bx, by)
  local abx, aby = bx - ax, by - ay
  local largo = abx * abx + aby * aby
  local t = largo > 0 and ((px - ax) * abx + (py - ay) * aby) / largo or 0
  t = math.max(0, math.min(1, t))
  return ax + abx * t, ay + aby * t
end

local function empujar(x, y, radio, poligono)
  local cercano_x, cercano_y, menor = nil, nil, radio
  local j = #poligono - 1
  for i = 1, #poligono, 2 do
    local cx, cy = punto_cercano(x, y, poligono[j], poligono[j + 1], poligono[i], poligono[i + 1])
    local distancia = math.sqrt((x - cx) ^ 2 + (y - cy) ^ 2)
    if distancia > 0 and distancia < menor then
      cercano_x, cercano_y, menor = cx, cy, distancia
    end
    j = i
  end
  if not cercano_x then
    return x, y
  end
  return cercano_x + (x - cercano_x) / menor * radio, cercano_y + (y - cercano_y) / menor * radio
end

function Colision.mover(x, y, dx, dy, radio, poligonos)
  local pasos = math.max(1, math.ceil(math.max(math.abs(dx), math.abs(dy)) / (radio / 2)))
  for _ = 1, pasos do
    x, y = x + dx / pasos, y + dy / pasos
    for _ = 1, REPETICIONES do
      for _, poligono in ipairs(poligonos) do
        x, y = empujar(x, y, radio, poligono)
      end
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

function Colision.distancia(x, y, poligono, estiramiento)
  local factor = estiramiento or 1
  local minimo = math.huge
  local j = #poligono - 1
  for i = 1, #poligono, 2 do
    local cx, cy = punto_cercano(x, y, poligono[j], poligono[j + 1] * factor, poligono[i], poligono[i + 1] * factor)
    minimo = math.min(minimo, math.sqrt((x - cx) ^ 2 + (y - cy) ^ 2))
    j = i
  end
  return minimo
end

return Colision
