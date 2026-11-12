local Encuadre = {}

local function limitar(objetivo, medio, total)
  return math.max(medio, math.min(total - medio, objetivo))
end

function Encuadre.zoom(ventana_ancho, ventana_alto, vista_ancho, vista_alto)
  return math.max(ventana_ancho / vista_ancho, ventana_alto / vista_alto)
end

function Encuadre.centro(x, y, ventana_ancho, ventana_alto, zoom, mundo_ancho, mundo_alto)
  return limitar(x, ventana_ancho / zoom / 2, mundo_ancho), limitar(y, ventana_alto / zoom / 2, mundo_alto)
end

function Encuadre.suavizar(actual, objetivo, dt, rigidez)
  return actual + (objetivo - actual) * (1 - math.exp(-rigidez * dt))
end

return Encuadre
