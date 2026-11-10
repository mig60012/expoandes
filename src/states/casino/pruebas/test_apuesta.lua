local Apuesta = require("src/states/casino/apuesta")

local apuesta = Apuesta.new({ minimo = 2, dinero = 15 })
assert(apuesta.monto == 2, "la apuesta empieza en el minimo de la mesa")
assert(apuesta.minimo == 2, "el limite inferior es el minimo de la mesa")
assert(apuesta.maximo == 15, "el limite superior es el dinero disponible")

assert(Apuesta.new({ minimo = 3, dinero = 3 }), "con el minimo exacto se puede sentar")
assert(Apuesta.new({ minimo = 3, dinero = 2.5 }) == nil, "con menos del minimo no se puede sentar")
assert(Apuesta.new({ minimo = 1, dinero = 0 }) == nil, "sin dinero no se puede sentar")

print("test_apuesta: ok")
