local Jornada = require("src/states/casino/jornada")

local jornada = Jornada.new()
assert(jornada.jugadas == 0, "el dia empieza sin jugadas")
jornada:registrar_jugada()
assert(jornada.jugadas == 1, "una jugada se cuenta")
jornada:registrar_jugada()
jornada:registrar_jugada()
assert(jornada.jugadas == 3, "cada jugada suma una")

local otra = Jornada.new()
assert(otra.jugadas == 0, "cada dia lleva su propia cuenta")

print("test_jornada: ok")
