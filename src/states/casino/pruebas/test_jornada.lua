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

print("test_jornada: ok")
