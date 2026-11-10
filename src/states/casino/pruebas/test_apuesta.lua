local Apuesta = require("src/states/casino/apuesta")

local apuesta = Apuesta.new({ minimo = 2, dinero = 15 })
assert(apuesta.monto == 2, "la apuesta empieza en el minimo de la mesa")
assert(apuesta.minimo == 2, "el limite inferior es el minimo de la mesa")
assert(apuesta.maximo == 15, "el limite superior es el dinero disponible")

assert(Apuesta.new({ minimo = 3, dinero = 3 }), "con el minimo exacto se puede sentar")
assert(Apuesta.new({ minimo = 3, dinero = 2.5 }) == nil, "con menos del minimo no se puede sentar")
assert(Apuesta.new({ minimo = 1, dinero = 0 }) == nil, "sin dinero no se puede sentar")

apuesta = Apuesta.new({ minimo = 2, dinero = 15 })
apuesta:cambiar(1)
assert(apuesta.monto == 3, "sube lo que se pide")
apuesta:cambiar(-1)
assert(apuesta.monto == 2, "baja lo que se pide")
apuesta:cambiar(-1)
assert(apuesta.monto == 2, "no baja del minimo")
apuesta:cambiar(10)
assert(apuesta.monto == 12, "el salto grande sube completo si cabe")
apuesta:cambiar(10)
assert(apuesta.monto == 15, "el salto grande se detiene en el dinero disponible")
apuesta:cambiar(-10)
assert(apuesta.monto == 5, "el salto grande baja completo si cabe")
apuesta:cambiar(-10)
assert(apuesta.monto == 2, "el salto grande se detiene en el minimo")

local confirmado, cancelado

local function con_avisos()
  confirmado, cancelado = nil, nil
  return Apuesta.new({
    minimo = 2,
    dinero = 15,
    al_confirmar = function(monto)
      confirmado = monto
    end,
    al_cancelar = function()
      cancelado = true
    end,
  })
end

apuesta = con_avisos()
apuesta:cambiar(3)
apuesta:confirmar()
assert(confirmado == 5, "confirmar avisa el monto elegido")
assert(not cancelado, "confirmar no cancela")

apuesta = con_avisos()
apuesta:cambiar(3)
apuesta:cancelar()
assert(cancelado, "cancelar avisa que no hubo apuesta")
assert(confirmado == nil, "cancelar no confirma ningun monto")

print("test_apuesta: ok")
