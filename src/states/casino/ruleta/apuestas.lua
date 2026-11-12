local RUTA = (...):match('^(.*[%./])[^%.%/]+$') or ''
local Rueda = require(RUTA .. "rueda")

local Apuestas = {}

local lista = {}
local function agregar(nombre, paga, descripcion, cubre)
  lista[#lista + 1] = { nombre = nombre, paga = paga, descripcion = descripcion, cubre = cubre }
end

agregar("Rojo", 1, "gana con cualquier número rojo", function(n) return Rueda.color(n) == "rojo" end)
agregar("Negro", 1, "gana con cualquier número negro", function(n) return Rueda.color(n) == "negro" end)
agregar("Par", 1, "gana con cualquier número par (el 0 no cuenta)", function(n) return n > 0 and n % 2 == 0 end)
agregar("Impar", 1, "gana con cualquier número impar", function(n) return n % 2 == 1 end)
agregar("Del 1 al 18", 1, "gana con los números del 1 al 18", function(n) return n >= 1 and n <= 18 end)
agregar("Del 19 al 36", 1, "gana con los números del 19 al 36", function(n) return n >= 19 end)
for d = 1, 3 do
  local desde, hasta = d * 12 - 11, d * 12
  agregar("Docena del " .. desde .. " al " .. hasta, 2, "gana con los números del " .. desde .. " al " .. hasta, function(n) return n >= desde and n <= hasta end)
end
for c = 1, 3 do
  agregar("Columna " .. c, 2, "gana con la columna " .. c .. ": " .. c .. ", " .. (c + 3) .. ", " .. (c + 6) .. "... hasta el " .. (c + 33), function(n) return n > 0 and (n - c) % 3 == 0 end)
end
for numero = 0, 36 do
  agregar("Número " .. numero, 35, "gana solo con el " .. numero, function(n) return n == numero end)
end
Apuestas.lista = lista

local function total(jugadas)
  local suma = 0
  for _, jugada in ipairs(jugadas) do
    suma = suma + jugada.monto
  end
  return suma
end

function Apuestas.pago(jugadas, numero)
  local suma = 0
  for _, jugada in ipairs(jugadas) do
    if jugada.apuesta.cubre(numero) then
      suma = suma + jugada.monto * (jugada.apuesta.paga + 1)
    end
  end
  return suma
end

function Apuestas.girar(jugadas, aleatorio, limite)
  local numero = Rueda.orden[aleatorio(#Rueda.orden)]
  local apostado = total(jugadas)
  if limite and apostado > limite then
    local perdedores = {}
    for _, n in ipairs(Rueda.orden) do
      if Apuestas.pago(jugadas, n) < apostado then
        perdedores[#perdedores + 1] = n
      end
    end
    if #perdedores > 0 then
      numero = perdedores[aleatorio(#perdedores)]
    end
  end
  return numero
end

return Apuestas
