local Apuesta = require("src/states/casino/apuesta")

local apuesta = Apuesta.new({ minimo = 2, dinero = 15 })
assert(apuesta.monto == 2, "la apuesta empieza en el minimo de la mesa")
assert(apuesta.minimo == 2, "el limite inferior es el minimo de la mesa")
assert(apuesta.maximo == 15, "el limite superior es el dinero disponible")

print("test_apuesta: ok")
