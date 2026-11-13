local Apuestas = require("src/states/casino/ruleta/apuestas")

local function buscar(nombre)
  for _, apuesta in ipairs(Apuestas.lista) do
    if apuesta.nombre == nombre then
      return apuesta
    end
  end
  error("no existe la apuesta " .. nombre)
end

local function cubiertos(apuesta)
  local numeros = {}
  for n = 0, 36 do
    if apuesta.cubre(n) then
      numeros[#numeros + 1] = n
    end
  end
  return table.concat(numeros, ",")
end

assert(#Apuestas.lista == 49, "hay 12 apuestas de afuera y 37 numeros")
assert(Apuestas.lista[1].nombre == "Rojo" and Apuestas.lista[49].nombre == "Número 36", "la lista va de Rojo al 36")
for _, apuesta in ipairs(Apuestas.lista) do
  local _, cuantos = cubiertos(apuesta):gsub("%d+", "")
  assert((apuesta.paga + 1) * cuantos == 36, "cada apuesta paga segun los numeros que cubre")
  assert(not apuesta.cubre(0) or apuesta.nombre == "Número 0", "el 0 solo gana con la apuesta al 0")
  assert(type(apuesta.descripcion) == "string" and apuesta.descripcion:find("^gana "), "cada apuesta explica con que gana")
end
assert(buscar("Rojo").descripcion == "gana con cualquier número rojo", "la explicacion del rojo")
assert(buscar("Docena del 13 al 24").descripcion == "gana con los números del 13 al 24", "la explicacion de una docena")
assert(buscar("Columna 1").descripcion == "gana con la columna 1: 1, 4, 7... hasta el 34", "la explicacion de una columna")
assert(buscar("Número 17").descripcion == "gana solo con el 17", "la explicacion de un numero")

assert(cubiertos(buscar("Columna 1")) == "1,4,7,10,13,16,19,22,25,28,31,34", "la columna 1")
assert(cubiertos(buscar("Columna 3")) == "3,6,9,12,15,18,21,24,27,30,33,36", "la columna 3")
assert(cubiertos(buscar("Docena del 13 al 24")) == "13,14,15,16,17,18,19,20,21,22,23,24", "la segunda docena")
assert(buscar("Par").cubre(36) and not buscar("Par").cubre(35), "par")
assert(buscar("Impar").cubre(35) and not buscar("Impar").cubre(36), "impar")
assert(buscar("Del 1 al 18").cubre(18) and not buscar("Del 1 al 18").cubre(19), "del 1 al 18")
assert(buscar("Del 19 al 36").cubre(19) and not buscar("Del 19 al 36").cubre(18), "del 19 al 36")
assert(buscar("Rojo").cubre(32) and buscar("Negro").cubre(15), "rojo y negro")

local rojo, diecisiete = buscar("Rojo"), buscar("Número 17")
assert(Apuestas.pago({ { apuesta = rojo, monto = 2 } }, 32) == 4, "rojo devuelve lo apostado y otro tanto")
assert(Apuestas.pago({ { apuesta = rojo, monto = 2 } }, 15) == 0, "si pierde no devuelve nada")
assert(Apuestas.pago({ { apuesta = rojo, monto = 2 } }, 0) == 0, "con el 0 pierde el rojo")
assert(Apuestas.pago({ { apuesta = diecisiete, monto = 1 } }, 17) == 36, "un numero paga 35 a 1")
assert(Apuestas.pago({ { apuesta = buscar("Número 0"), monto = 1 } }, 0) == 36, "el 0 paga 35 a 1")
assert(Apuestas.pago({ { apuesta = buscar("Docena del 1 al 12"), monto = 3 } }, 12) == 9, "la docena paga 2 a 1")
assert(Apuestas.pago({ { apuesta = rojo, monto = 2 }, { apuesta = diecisiete, monto = 1 } }, 17) == 36, "varias apuestas suman su pago")

local pedidos = {}
local function azar_fijo(valor)
  return function(n)
    pedidos[#pedidos + 1] = n
    return math.min(valor, n)
  end
end
assert(Apuestas.girar({ { apuesta = rojo, monto = 2 } }, azar_fijo(2), 100) == 32, "el azar elige la casilla de la rueda")
assert(pedidos[1] == 37, "el azar elige entre las 37 casillas")
assert(Apuestas.girar({ { apuesta = rojo, monto = 100 } }, azar_fijo(2), 100) == 32, "con 100 M todavia puede ganar")
assert(Apuestas.girar({ { apuesta = rojo, monto = 500 } }, azar_fijo(2)) == 32, "sin limite no hay codicia")
local numero = Apuestas.girar({ { apuesta = rojo, monto = 101 } }, azar_fijo(2), 100)
assert(Apuestas.pago({ { apuesta = rojo, monto = 101 } }, numero) == 0, "con mas de 100 M la pelota cae en un numero que pierde")
assert(pedidos[#pedidos] == 19, "elige entre los 19 numeros que pierden con rojo")
for valor = 1, 37 do
  assert(Apuestas.girar({ { apuesta = diecisiete, monto = 200 } }, azar_fijo(valor), 100) ~= 17, "la codicia nunca deja ganar")
end

print("test_ruleta_apuestas: ok")
