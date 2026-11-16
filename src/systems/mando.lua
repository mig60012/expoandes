local Mando = {}

local ZONA_MUERTA, UMBRAL_MENU = 0.25, 0.6
local ESPERA, REPETICION = 0.4, 0.09
local RAPIDEZ_CURSOR = 1.3

local DIRECCIONES = {
  dpup = { "up", "w" },
  dpdown = { "down", "s" },
  dpleft = { "left", "a" },
  dpright = { "right", "d" },
}
local TECLAS = {
  b = "escape",
  x = "return",
  y = "r",
  start = "return",
  back = "f1",
  leftshoulder = "c",
}
local SOSTENIDAS = { rightshoulder = "h" }
local SONY = 1356
local NOMBRES = {
  teclado = { aceptar = "Z", volver = "Esc", reiniciar = "R", correr = "H" },
  xbox = { aceptar = "A", volver = "B", reiniciar = "Y", correr = "RB" },
  sony = { aceptar = "X", volver = "O", reiniciar = "Triángulo", correr = "R1" },
}

local function nada() end

local salidas = { tecla = nada, soltar_tecla = nada, clic = nada, soltar_clic = nada }
local cruceta, palanca, repetir, botones = {}, {}, {}, {}
local accion_a, cursor_x, cursor_y
local teclado_real, raton_real
local dispositivo = "teclado"

local function es_sony(joystick)
  local ok, vendedor = pcall(joystick.getDeviceInfo, joystick)
  if ok and vendedor == SONY then return true end
  local ok_nombre, nombre = pcall(joystick.getName, joystick)
  nombre = ok_nombre and tostring(nombre):lower() or ""
  return nombre:find("ps%d") ~= nil or nombre:find("dual") ~= nil or nombre:find("playstation") ~= nil
end

local function usar_mando(joystick)
  if joystick then
    dispositivo = es_sony(joystick) and "sony" or "xbox"
  end
end

function Mando.usar_teclado()
  dispositivo = "teclado"
end

function Mando.boton(accion)
  return NOMBRES[dispositivo][accion] or NOMBRES.teclado[accion]
end

local function sostenida(tecla, grupo)
  for nombre in pairs(grupo) do
    local teclas = DIRECCIONES[nombre]
    if teclas and (teclas[1] == tecla or teclas[2] == tecla) then return true end
  end
  return false
end

function Mando.isDown(...)
  if teclado_real and teclado_real(...) then return true end
  for _, tecla in ipairs({ ... }) do
    if sostenida(tecla, cruceta) or sostenida(tecla, palanca) then return true end
    for boton, nombre in pairs(SOSTENIDAS) do
      if botones[boton] and nombre == tecla then return true end
    end
  end
  return false
end

function Mando.raton_isDown(...)
  if raton_real and raton_real(...) then return true end
  if accion_a ~= "clic" then return false end
  for _, boton in ipairs({ ... }) do
    if boton == 1 then return true end
  end
  return false
end

function Mando.iniciar(opciones)
  for nombre in pairs(salidas) do
    salidas[nombre] = opciones[nombre] or nada
  end
  cruceta, palanca, repetir, botones = {}, {}, {}, {}
  accion_a, cursor_x, cursor_y, dispositivo = nil, nil, nil, "teclado"
  if love and love.keyboard and love.keyboard.isDown ~= Mando.isDown then
    teclado_real = love.keyboard.isDown
    love.keyboard.isDown = Mando.isDown
  end
  if love and love.mouse and love.mouse.isDown and love.mouse.isDown ~= Mando.raton_isDown then
    raton_real = love.mouse.isDown
    love.mouse.isDown = Mando.raton_isDown
  end
end

function Mando.presionar(joystick, boton, cursor)
  usar_mando(joystick)
  botones[boton] = true
  if DIRECCIONES[boton] then
    cruceta[boton] = true
    repetir[boton] = ESPERA
    salidas.tecla(DIRECCIONES[boton][1])
  elseif boton == "a" then
    if cursor then
      accion_a = "clic"
      local x, y = love.mouse.getPosition()
      salidas.clic(x, y, 1)
    else
      accion_a = "tecla"
      salidas.tecla("return")
    end
  elseif TECLAS[boton] then
    salidas.tecla(TECLAS[boton])
  end
end

function Mando.soltar(_, boton)
  botones[boton] = nil
  if DIRECCIONES[boton] then
    cruceta[boton], repetir[boton] = nil, nil
    salidas.soltar_tecla(DIRECCIONES[boton][1])
  elseif boton == "a" then
    local accion = accion_a
    accion_a = nil
    if accion == "clic" then
      local x, y = love.mouse.getPosition()
      salidas.soltar_clic(x, y, 1)
    elseif accion == "tecla" then
      salidas.soltar_tecla("return")
    end
  elseif TECLAS[boton] then
    salidas.soltar_tecla(TECLAS[boton])
  end
end

local function primer_mando()
  if not (love.joystick and love.joystick.getJoysticks) then return nil end
  for _, joystick in ipairs(love.joystick.getJoysticks()) do
    if joystick:isGamepad() then return joystick end
  end
end

local function eje(joystick, nombre)
  return joystick and joystick:getGamepadAxis(nombre) or 0
end

local function mover_cursor(dt, x, y)
  local magnitud = math.sqrt(x * x + y * y)
  if magnitud < ZONA_MUERTA then
    cursor_x, cursor_y = nil, nil
    return
  end
  local fuerza = ((math.min(magnitud, 1) - ZONA_MUERTA) / (1 - ZONA_MUERTA)) ^ 1.6 / magnitud
  local ancho, alto = love.graphics.getDimensions()
  local real_x, real_y = love.mouse.getPosition()
  if not cursor_x or math.abs(real_x - math.floor(cursor_x)) > 1 or math.abs(real_y - math.floor(cursor_y)) > 1 then
    cursor_x, cursor_y = real_x, real_y
  end
  local paso = RAPIDEZ_CURSOR * alto * dt * fuerza
  cursor_x = math.max(0, math.min(ancho - 1, cursor_x + x * paso))
  cursor_y = math.max(0, math.min(alto - 1, cursor_y + y * paso))
  local nuevo_x, nuevo_y = math.floor(cursor_x), math.floor(cursor_y)
  if nuevo_x ~= real_x or nuevo_y ~= real_y then
    love.mouse.setPosition(nuevo_x, nuevo_y)
  end
end

local function direcciones_palanca(x, y, umbral)
  local activas = {}
  if x <= -umbral then activas.dpleft = true elseif x >= umbral then activas.dpright = true end
  if y <= -umbral then activas.dpup = true elseif y >= umbral then activas.dpdown = true end
  return activas
end

function Mando.actualizar(dt, cursor)
  local joystick = primer_mando()
  local x, y = eje(joystick, "leftx"), eje(joystick, "lefty")
  local rx, ry = eje(joystick, "rightx"), eje(joystick, "righty")
  if math.max(math.abs(x), math.abs(y), math.abs(rx), math.abs(ry)) >= ZONA_MUERTA then
    usar_mando(joystick)
  end
  local menu = {}
  if cursor then
    palanca = {}
    if rx * rx + ry * ry > x * x + y * y then x, y = rx, ry end
    mover_cursor(dt, x, y)
  else
    cursor_x, cursor_y = nil, nil
    palanca = direcciones_palanca(x, y, ZONA_MUERTA)
    menu = direcciones_palanca(x, y, UMBRAL_MENU)
  end
  for nombre in pairs(DIRECCIONES) do
    local activa = cruceta[nombre] or menu[nombre]
    if not activa then
      repetir[nombre] = nil
    elseif not repetir[nombre] then
      repetir[nombre] = ESPERA
      salidas.tecla(DIRECCIONES[nombre][1])
    else
      repetir[nombre] = repetir[nombre] - dt
      if repetir[nombre] <= 0 then
        repetir[nombre] = REPETICION
        salidas.tecla(DIRECCIONES[nombre][1])
      end
    end
  end
end

return Mando
