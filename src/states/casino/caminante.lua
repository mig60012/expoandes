local RUTA = (...):match("^(.*[%./])[^%.%/]+$") or ""
local Colision = require(RUTA .. "colision")

local Caminante = {}
Caminante.__index = Caminante

local PASO_MAXIMO = 1 / 30

local function estirar(poligono, factor)
  local estirado = {}
  for i = 1, #poligono, 2 do
    estirado[i], estirado[i + 1] = poligono[i], poligono[i + 1] * factor
  end
  return estirado
end

function Caminante.new(opciones)
  local caminante = setmetatable({
    x = opciones.x,
    y = opciones.y,
    velocidad = opciones.velocidad,
    radio = opciones.radio,
    estiramiento = opciones.estiramiento,
    poligonos = {},
  }, Caminante)
  for i, poligono in ipairs(opciones.poligonos) do
    caminante.poligonos[i] = estirar(poligono, opciones.estiramiento)
  end
  return caminante
end

function Caminante:mover(dx, dy, dt)
  if dx == 0 and dy == 0 then
    return
  end
  local paso = self.velocidad * math.min(dt, PASO_MAXIMO) / math.sqrt(dx * dx + dy * dy)
  local x, y = Colision.mover(self.x, self.y * self.estiramiento, dx * paso, dy * paso, self.radio, self.poligonos)
  self.x, self.y = x, y / self.estiramiento
end

function Caminante:mas_cercano(objetos, alcance)
  local elegido, mejor = nil, alcance
  for _, objeto in ipairs(objetos) do
    local distancia = Colision.distancia(self.x, self.y * self.estiramiento, objeto.choque, self.estiramiento)
    if distancia <= mejor then
      elegido, mejor = objeto, distancia
    end
  end
  return elegido
end

function Caminante:detras_de(objeto)
  local linea = objeto.linea
  return self.y < linea.y + linea.pendiente * (self.x - linea.x)
end

return Caminante
