local Probador = {}
Probador.__index = Probador

local function describir(valor, vistos)
  if type(valor) == "string" then
    return string.format("%q", valor)
  end
  if type(valor) ~= "table" then
    return tostring(valor)
  end

  vistos = vistos or {}
  if vistos[valor] then return "{...}" end
  vistos[valor] = true

  local partes, n = {}, #valor
  for i = 1, n do
    partes[#partes + 1] = describir(valor[i], vistos)
  end

  local claves = {}
  for clave in pairs(valor) do
    local es_de_lista = type(clave) == "number" and clave >= 1 and clave <= n and clave % 1 == 0
    if not es_de_lista then claves[#claves + 1] = clave end
  end
  table.sort(claves, function(a, b) return tostring(a) < tostring(b) end)

  for _, clave in ipairs(claves) do
    local nombre
    if type(clave) == "string" and clave:match("^[%a_][%w_]*$") then
      nombre = clave
    else
      nombre = "[" .. describir(clave, vistos) .. "]"
    end
    partes[#partes + 1] = nombre .. " = " .. describir(valor[clave], vistos)
  end

  vistos[valor] = nil
  return "{" .. table.concat(partes, ", ") .. "}"
end

local function iguales(a, b, vistos)
  if a == b then return true end
  if type(a) ~= "table" or type(b) ~= "table" then return false end

  vistos = vistos or {}
  if vistos[a] == b then return true end
  vistos[a] = b

  for clave, valor in pairs(a) do
    if not iguales(valor, b[clave], vistos) then return false end
  end
  for clave in pairs(b) do
    if a[clave] == nil then return false end
  end
  return true
end

local function con_mensaje(mensaje, texto)
  if mensaje then return mensaje .. ": " .. texto end
  return texto
end

function Probador.afirmar(condicion, mensaje)
  if not condicion then
    error(mensaje or "la condición no se cumplió", 2)
  end
end

function Probador.afirmar_igual(obtenido, esperado, mensaje)
  if not iguales(obtenido, esperado) then
    error(con_mensaje(mensaje, "esperaba " .. describir(esperado) .. ", obtuve " .. describir(obtenido)), 2)
  end
end

function Probador.afirmar_distinto(obtenido, no_esperado, mensaje)
  if iguales(obtenido, no_esperado) then
    error(con_mensaje(mensaje, "no debía ser " .. describir(no_esperado)), 2)
  end
end

function Probador.afirmar_cerca(obtenido, esperado, tolerancia, mensaje)
  tolerancia = tolerancia or 1e-6
  if type(obtenido) ~= "number" or math.abs(obtenido - esperado) > tolerancia then
    error(con_mensaje(mensaje, "esperaba " .. describir(esperado) .. " +/- " .. tolerancia
      .. ", obtuve " .. describir(obtenido)), 2)
  end
end

function Probador.afirmar_error(funcion, texto, mensaje)
  local ok, err = pcall(funcion)
  if ok then
    error(con_mensaje(mensaje, "esperaba un error y no hubo ninguno"), 2)
  end
  if texto and not tostring(err):find(texto, 1, true) then
    error(con_mensaje(mensaje, "esperaba un error con " .. describir(texto)
      .. ", obtuve " .. describir(tostring(err))), 2)
  end
end

function Probador.new()
  return setmetatable({ resultados = {}, grupo_actual = nil }, Probador)
end

function Probador:grupo(nombre)
  self.grupo_actual = nombre
end

function Probador:anotar(nombre, paso, detalle)
  if detalle ~= nil then
    detalle = tostring(detalle):gsub("%s+$", "")
  end
  self.resultados[#self.resultados + 1] = {
    grupo = self.grupo_actual,
    nombre = nombre,
    paso = paso,
    detalle = detalle,
  }
end

function Probador:prueba(nombre, funcion)
  local ok, err = pcall(funcion)
  self:anotar(nombre, ok, (not ok) and tostring(err) or nil)
  return ok
end

function Probador:resumen()
  local pasadas, falladas = 0, 0
  for _, r in ipairs(self.resultados) do
    if r.paso then pasadas = pasadas + 1 else falladas = falladas + 1 end
  end
  return pasadas, falladas
end

function Probador:informe()
  local pasadas, falladas = self:resumen()
  local lineas = {
    string.format("%d de %d pruebas pasaron%s", pasadas, pasadas + falladas,
      falladas > 0 and (" (" .. falladas .. " fallaron)") or ""),
  }

  local grupo_anterior = {}
  for _, r in ipairs(self.resultados) do
    if r.grupo ~= grupo_anterior then
      lineas[#lineas + 1] = ""
      lineas[#lineas + 1] = "[" .. tostring(r.grupo or "sin grupo") .. "]"
      grupo_anterior = r.grupo
    end
    lineas[#lineas + 1] = (r.paso and "  OK     " or "  FALLA  ") .. r.nombre
    if r.detalle then
      lineas[#lineas + 1] = "         " .. r.detalle
    end
  end

  return table.concat(lineas, "\n")
end

function Probador:herramientas()
  return {
    prueba = function(nombre, funcion) return self:prueba(nombre, funcion) end,
    afirmar = Probador.afirmar,
    afirmar_igual = Probador.afirmar_igual,
    afirmar_distinto = Probador.afirmar_distinto,
    afirmar_cerca = Probador.afirmar_cerca,
    afirmar_error = Probador.afirmar_error,
  }
end

Probador.describir = describir
Probador.iguales = iguales

return Probador
