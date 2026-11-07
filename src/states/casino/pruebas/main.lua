local ARCHIVOS = {
  "prueba_probador.lua",
}

local Probador = require("probador")

local probador = nil
local lineas = {}
local desplazamiento = 0
local modulos_base = {}

local ALTO_LINEA = 18
local VERDE = { 0.45, 0.9, 0.45 }
local ROJO = { 1, 0.45, 0.45 }
local GRIS = { 0.6, 0.6, 0.6 }
local BLANCO = { 1, 1, 1 }

local function preparar_rutas()
  local casino = love.filesystem.getSource() .. "/.."
  package.path = casino .. "/?.lua;" .. casino .. "/?/init.lua;" .. package.path
end

local function olvidar_modulos_nuevos()
  for nombre in pairs(package.loaded) do
    if not modulos_base[nombre] then package.loaded[nombre] = nil end
  end
end

local function correr_pruebas()
  olvidar_modulos_nuevos()
  probador = Probador.new()

  for _, archivo in ipairs(ARCHIVOS) do
    probador:grupo(archivo)

    local ok_carga, trozo, error_carga = pcall(love.filesystem.load, archivo)
    if not ok_carga or not trozo then
      probador:anotar("cargar el archivo", false, tostring(ok_carga and error_carga or trozo))
    else
      local ok, error_ejecucion = pcall(trozo, probador:herramientas())
      if not ok then
        probador:anotar("ejecutar el archivo", false, tostring(error_ejecucion))
      end
    end
  end
end

local function preparar_lineas()
  lineas = {}
  for linea in (probador:informe() .. "\n"):gmatch("(.-)\n") do
    lineas[#lineas + 1] = linea
  end
end

local function color_de(linea, indice)
  if indice == 1 then
    local _, falladas = probador:resumen()
    return falladas == 0 and VERDE or ROJO
  end
  if linea:find("^  OK") then return VERDE end
  if linea:find("^  FALLA") or linea:find("^         ") then return ROJO end
  return BLANCO
end

local function tiene_bandera(lista, bandera)
  for _, valor in pairs(lista or {}) do
    if valor == bandera then return true end
  end
  return false
end

function love.load(argumentos)
  preparar_rutas()
  for nombre in pairs(package.loaded) do modulos_base[nombre] = true end

  correr_pruebas()

  if tiene_bandera(argumentos, "--auto") or tiene_bandera(arg, "--auto") then
    local informe = probador:informe()
    print(informe)
    if love.filesystem.write("resultado.txt", informe .. "\n") then
      print("Resultado guardado en: " .. love.filesystem.getSaveDirectory() .. "/resultado.txt")
    end
    local _, falladas = probador:resumen()
    love.event.quit(falladas == 0 and 0 or 1)
    return
  end

  preparar_lineas()
end

function love.draw()
  love.graphics.clear(0.08, 0.08, 0.1)

  local limite = love.graphics.getHeight() - 50
  for i = 1 + desplazamiento, #lineas do
    local y = 20 + (i - 1 - desplazamiento) * ALTO_LINEA
    if y > limite then break end
    love.graphics.setColor(color_de(lineas[i], i))
    love.graphics.print(lineas[i], 20, y)
  end

  love.graphics.setColor(GRIS)
  love.graphics.print("R: volver a correr    Flechas: desplazar    Esc: salir", 20, love.graphics.getHeight() - 30)
  love.graphics.setColor(1, 1, 1)
end

function love.keypressed(tecla)
  if tecla == "escape" then
    love.event.quit()
  elseif tecla == "r" then
    correr_pruebas()
    preparar_lineas()
    desplazamiento = 0
  elseif tecla == "down" then
    desplazamiento = math.min(desplazamiento + 1, math.max(#lineas - 1, 0))
  elseif tecla == "up" then
    desplazamiento = math.max(desplazamiento - 1, 0)
  end
end
