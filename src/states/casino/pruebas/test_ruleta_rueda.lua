local Rueda = require("src/states/casino/ruleta/rueda")

assert(#Rueda.orden == 37, "la rueda europea tiene 37 casillas")
local vistos = {}
for _, numero in ipairs(Rueda.orden) do
  assert(not vistos[numero], "ningun numero se repite en la rueda")
  vistos[numero] = true
end
for numero = 0, 36 do
  assert(vistos[numero], "estan todos los numeros del 0 al 36")
end
assert(Rueda.orden[1] == 0 and Rueda.orden[2] == 32 and Rueda.orden[37] == 26, "el 0 va entre el 26 y el 32")

assert(Rueda.color(0) == "verde", "el 0 es verde")
local cuenta = { rojo = 0, negro = 0 }
for numero = 1, 36 do
  local color = Rueda.color(numero)
  cuenta[color] = cuenta[color] + 1
end
assert(cuenta.rojo == 18 and cuenta.negro == 18, "hay 18 rojos y 18 negros")
assert(Rueda.color(1) == "rojo" and Rueda.color(19) == "rojo" and Rueda.color(36) == "rojo", "colores rojos conocidos")
assert(Rueda.color(2) == "negro" and Rueda.color(10) == "negro" and Rueda.color(11) == "negro", "colores negros conocidos")

assert(Rueda.color(Rueda.orden[2]) == "rojo", "despues del 0 viene un rojo")
for i = 2, 36 do
  assert(Rueda.color(Rueda.orden[i]) ~= Rueda.color(Rueda.orden[i + 1]), "en la rueda los colores se alternan")
end

print("test_ruleta_rueda: ok")
