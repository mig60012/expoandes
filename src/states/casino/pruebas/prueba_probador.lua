local t = ...
local prueba, afirmar, afirmar_igual = t.prueba, t.afirmar, t.afirmar_igual
local afirmar_distinto, afirmar_cerca, afirmar_error = t.afirmar_distinto, t.afirmar_cerca, t.afirmar_error

local Probador = require("probador")

prueba("afirmar_igual acepta valores iguales", function()
  afirmar_igual(1 + 1, 2)
  afirmar_igual("casino", "casino")
  afirmar_igual({ 1, 2, { a = 3 } }, { 1, 2, { a = 3 } })
end)

prueba("afirmar_igual falla y dice qué esperaba y qué obtuvo", function()
  afirmar_error(function() afirmar_igual(4, 3) end, "esperaba 3, obtuve 4")
  afirmar_error(function() afirmar_igual({ 1 }, { 1, 2 }) end, "esperaba {1, 2}, obtuve {1}")
end)

prueba("afirmar falla si la condición es falsa", function()
  afirmar(true)
  afirmar_error(function() afirmar(false, "sin dinero") end, "sin dinero")
end)

prueba("afirmar_distinto y afirmar_cerca", function()
  afirmar_distinto({ x = 1 }, { x = 2 })
  afirmar_error(function() afirmar_distinto(5, 5) end, "no debía ser 5")
  afirmar_cerca(0.1 + 0.2, 0.3)
  afirmar_error(function() afirmar_cerca(1.5, 1, 0.1) end, "obtuve 1.5")
end)

prueba("afirmar_error falla si no hubo error", function()
  afirmar_error(function() afirmar_error(function() end) end, "esperaba un error")
end)

prueba("una prueba que falla no detiene a las demás", function()
  local p = Probador.new()
  p:grupo("interno")
  p:prueba("falla a propósito", function() error("boom") end)
  p:prueba("pasa", function() end)

  local pasadas, falladas = p:resumen()
  afirmar_igual({ pasadas, falladas }, { 1, 1 })
  afirmar(p.resultados[1].detalle:find("boom", 1, true) ~= nil, "debió guardar el motivo de la falla")
end)

prueba("el informe muestra el resumen y cada grupo", function()
  local p = Probador.new()
  p:grupo("demo")
  p:prueba("ok", function() end)

  local informe = p:informe()
  afirmar(informe:find("1 de 1 pruebas pasaron", 1, true) ~= nil, informe)
  afirmar(informe:find("[demo]", 1, true) ~= nil, informe)
end)
