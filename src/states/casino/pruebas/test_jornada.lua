local Jornada = require("src/states/casino/jornada")

local jornada = Jornada.new({ maximo = 6 })
assert(jornada.jugadas == 0, "el dia empieza sin jugadas")
jornada:registrar_jugada()
assert(jornada.jugadas == 1, "una jugada se cuenta")
jornada:registrar_jugada()
jornada:registrar_jugada()
assert(jornada.jugadas == 3, "cada jugada suma una")
assert(not jornada:completa(), "con 3 de 6 jugadas el dia sigue")
jornada:registrar_jugada()
jornada:registrar_jugada()
assert(not jornada:completa(), "con 5 de 6 jugadas el dia sigue")
jornada:registrar_jugada()
assert(jornada:completa(), "con 6 de 6 jugadas el dia se completa")

local otra = Jornada.new({ maximo = 6 })
assert(otra.jugadas == 0 and not otra:completa(), "cada dia lleva su propia cuenta")

local corta = Jornada.new({ maximo = 1 })
corta:registrar_jugada()
assert(corta:completa(), "el limite lo pone quien crea el dia")

local function cerca(a, b)
  return math.abs(a - b) < 0.000001
end

local cansada = Jornada.new({ maximo = 6, cansancio = 0.08 })
assert(cansada:factor_velocidad() == 1, "sin jugadas camina a velocidad completa")
cansada:registrar_jugada()
assert(cerca(cansada:factor_velocidad(), 0.92), "cada jugada quita un 8 %")
cansada:registrar_jugada()
cansada:registrar_jugada()
assert(cerca(cansada:factor_velocidad(), 0.76), "a las 3 jugadas camina al 76 %")
cansada:registrar_jugada()
cansada:registrar_jugada()
cansada:registrar_jugada()
assert(cerca(cansada:factor_velocidad(), 0.52), "a las 6 jugadas camina al 52 %")

local descansada = Jornada.new({ maximo = 6, cansancio = 0 })
descansada:registrar_jugada()
assert(descansada:factor_velocidad() == 1, "el cansancio lo pone quien crea el dia")

print("test_jornada: ok")
