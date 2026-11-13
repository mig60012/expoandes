local RUTA = (...):match('^(.*[%./])[^%.%/]+$') or ''
local Rueda = require(RUTA .. "rueda")

local Vista = {}

local FUENTES = RUTA:gsub("%.", "/") .. "fuentes/"
local ANCHO, ALTO = 1920, 1080
local PASO = 2 * math.pi / #Rueda.orden
local CREMA, ORO, FIELTRO = { 0.95, 0.92, 0.85 }, { 0.83, 0.69, 0.42 }, { 0.06, 0.24, 0.15 }
local OSCURO, PERDIDA = { 0.12, 0.1, 0.07 }, { 0.85, 0.38, 0.35 }
local COLORES = { rojo = { 0.66, 0.13, 0.14 }, negro = { 0.09, 0.09, 0.1 }, verde = { 0.1, 0.45, 0.27 } }
local INCLINACION = 0.5
local PX, PY, CW, CH = 288, 215, 96, 104
local OPCIONES = { "Rojo", "Par", "Del 1 al 18", "Negro", "Impar", "Del 19 al 36" }
local BARRA_X, BARRA_Y, BARRA_ANCHO = 560, 560, 800

local function color(c, alfa)
  love.graphics.setColor(c[1], c[2], c[3], alfa or 1)
end

local function fuente(archivo, tamano)
  if love.filesystem.getInfo(FUENTES .. archivo) then
    return love.graphics.newFont(FUENTES .. archivo, tamano)
  end
  return love.graphics.newFont(tamano)
end

local function degradado(radio, centro, borde)
  local vertices = { { 0, 0, 0, 0, centro[1], centro[2], centro[3], centro[4] } }
  for i = 0, 48 do
    local a = i / 48 * 2 * math.pi
    vertices[#vertices + 1] = { math.cos(a) * radio, math.sin(a) * radio, 0, 0, borde[1], borde[2], borde[3], borde[4] }
  end
  return love.graphics.newMesh(vertices, "fan")
end

local function casilla(n)
  if n == 0 then
    return PX, PY, CW, CH * 3
  end
  return PX + CW * math.ceil(n / 3), PY + CH * (2 - (n - 1) % 3), CW, CH
end

local function zonas()
  local mesa, monto, resultado = {}, {}, {}
  local function zona(lista, x, y, w, h, datos)
    datos.x, datos.y, datos.w, datos.h = x, y, w, h
    lista[#lista + 1] = datos
  end
  for n = 0, 36 do
    local x, y, w, h = casilla(n)
    zona(mesa, x, y, w, h, { apuesta = "Número " .. n, numero = n })
  end
  for c = 1, 3 do
    zona(mesa, PX + CW * 13, PY + CH * (3 - c), CW, CH, { apuesta = "Columna " .. c, texto = "2 a 1" })
  end
  for d = 1, 3 do
    zona(mesa, PX + CW * (4 * d - 3), PY + CH * 3, CW * 4, 70, { apuesta = "Docena del " .. (12 * d - 11) .. " al " .. (12 * d), texto = (12 * d - 11) .. " a " .. (12 * d) })
  end
  for i, nombre in ipairs(OPCIONES) do
    zona(mesa, PX + 456 * ((i - 1) % 3), 620 + 76 * math.floor((i - 1) / 3), 432, 64, { apuesta = nombre, opcion = true })
  end
  zona(mesa, 1232, 838, 400, 84, { accion = "apostar", texto = "APOSTAR", principal = true })
  zona(monto, BARRA_X - 30, BARRA_Y - 40, BARRA_ANCHO + 60, 80, { accion = "barra" })
  zona(monto, 980, 705, 380, 80, { accion = "confirmar", texto = "CONFIRMAR", principal = true })
  zona(monto, 560, 710, 340, 70, { accion = "volver", texto = "Volver" })
  zona(resultado, 680, 668, 560, 92, { accion = "otra", texto = "APOSTAR OTRA VEZ", principal = true })
  zona(resultado, 810, 806, 300, 58, { accion = "salir", texto = "Salir del juego" })
  return { mesa = mesa, monto = monto, resultado = resultado }
end

function Vista.recursos()
  return {
    titulo = fuente("Cinzel.ttf", 64),
    boton = fuente("Cinzel.ttf", 34),
    cifra = fuente("Cinzel.ttf", 80),
    enorme = fuente("Cinzel.ttf", 96),
    numero = fuente("Cinzel.ttf", 40),
    etiqueta = fuente("Cinzel.ttf", 28),
    pequena = fuente("Cinzel.ttf", 22),
    rueda = fuente("Cinzel.ttf", 24),
    grande = fuente("Marcellus-Regular.ttf", 40),
    texto = fuente("Marcellus-Regular.ttf", 30),
    chica = fuente("Marcellus-Regular.ttf", 24),
    luz = degradado(1, { 1, 1, 1, 0.07 }, { 1, 1, 1, 0 }),
    vineta = degradado(1250, { 0, 0, 0, 0 }, { 0, 0, 0, 0.55 }),
    zonas = zonas(),
    mano = love.mouse.getSystemCursor("hand"),
  }
end

local function escala()
  local ancho, alto = love.graphics.getDimensions()
  local e = math.min(ancho / ANCHO, alto / ALTO)
  return e, (ancho - ANCHO * e) / 2, (alto - ALTO * e) / 2
end

function Vista.tocar(r, etapa, x, y)
  local e, ox, oy = escala()
  x, y = (x - ox) / e, (y - oy) / e
  for _, z in ipairs(r.zonas[etapa] or {}) do
    if x >= z.x and x < z.x + z.w and y >= z.y and y < z.y + z.h then
      return z
    end
  end
end

function Vista.deslizador(x)
  local e, ox = escala()
  return math.max(0, math.min(1, ((x - ox) / e - BARRA_X) / BARRA_ANCHO))
end

local function centrado(f, texto, x, y)
  love.graphics.setFont(f)
  love.graphics.print(texto, math.floor(x - f:getWidth(texto) / 2), math.floor(y - f:getHeight() / 2))
end

local function boton(z, d, r)
  local encima = d.encima == z
  if z.principal then
    color(encima and { 0.92, 0.8, 0.55 } or ORO)
    love.graphics.rectangle("fill", z.x, z.y, z.w, z.h, 6)
    color(OSCURO)
    centrado(r.boton, z.texto, z.x + z.w / 2, z.y + z.h / 2)
  else
    color(CREMA, encima and 0.9 or 0.4)
    love.graphics.setLineWidth(1.5)
    love.graphics.rectangle("line", z.x, z.y, z.w, z.h, 6)
    color(CREMA, encima and 1 or 0.75)
    centrado(r.texto, z.texto, z.x + z.w / 2, z.y + z.h / 2)
  end
end

local function fondo(r)
  color(FIELTRO)
  love.graphics.rectangle("fill", 0, 0, ANCHO, ALTO)
  color(CREMA)
  love.graphics.draw(r.luz, ANCHO / 2, ALTO / 2, 0, 1000, 650)
  color(ORO, 0.35)
  love.graphics.setLineWidth(1.5)
  love.graphics.rectangle("line", 40, 40, ANCHO - 80, ALTO - 80, 6)
end

local function rueda(d, r, cx, cy, R)
  local k = R / 300
  color({ 0, 0, 0 }, 0.3)
  love.graphics.ellipse("fill", cx + 20 * k, cy + 80 * k, R * 1.36, R * 1.36 * INCLINACION)
  color({ 0.17, 0.1, 0.05 })
  love.graphics.ellipse("fill", cx, cy + 50 * k, R * 1.3, R * 1.3 * INCLINACION)
  love.graphics.rectangle("fill", cx - R * 1.3, cy, R * 2.6, 50 * k)
  love.graphics.push()
  love.graphics.translate(cx, cy)
  love.graphics.scale(1, INCLINACION)
  color({ 0.34, 0.19, 0.09 })
  love.graphics.circle("fill", 0, 0, R * 1.3)
  color({ 0.47, 0.3, 0.16 })
  love.graphics.circle("fill", 0, 0, R * 1.16)
  color(ORO, 0.7)
  love.graphics.setLineWidth(2 * k)
  love.graphics.circle("line", 0, 0, R * 1.3)
  love.graphics.circle("line", 0, 0, R * 1.01)
  love.graphics.setFont(r.rueda)
  for i, n in ipairs(Rueda.orden) do
    local a = d.angulo_rueda + (i - 1) * PASO
    local c = COLORES[Rueda.color(n)]
    color(c)
    love.graphics.arc("fill", 0, 0, R, a - PASO / 2, a + PASO / 2)
    color({ c[1] * 0.6, c[2] * 0.6, c[3] * 0.6 })
    love.graphics.arc("fill", 0, 0, R * 0.8, a - PASO / 2, a + PASO / 2)
    color(CREMA, 0.45)
    love.graphics.setLineWidth(1.5 * k)
    love.graphics.line(math.cos(a - PASO / 2) * R * 0.62, math.sin(a - PASO / 2) * R * 0.62, math.cos(a - PASO / 2) * R, math.sin(a - PASO / 2) * R)
    color(n == d.numero and ORO or CREMA)
    love.graphics.print(tostring(n), math.cos(a) * R * 0.9, math.sin(a) * R * 0.9, a + math.pi / 2, k, k, r.rueda:getWidth(tostring(n)) / 2, r.rueda:getHeight() / 2)
  end
  color({ 0.3, 0.18, 0.09 })
  love.graphics.circle("fill", 0, 0, R * 0.62)
  color({ 0.45, 0.31, 0.17 })
  love.graphics.circle("fill", 0, 0, R * 0.45)
  color({ 0.62, 0.48, 0.28 })
  love.graphics.circle("fill", 0, 0, R * 0.25)
  color(ORO, 0.7)
  love.graphics.circle("line", 0, 0, R * 0.62)
  love.graphics.pop()
  color({ 0.72, 0.6, 0.38 })
  love.graphics.rectangle("fill", cx - 8 * k, cy - 46 * k, 16 * k, 46 * k)
  love.graphics.setLineWidth(5 * k)
  for brazo = 0, 3 do
    local a = d.angulo_rueda + brazo * math.pi / 2
    local x, y = cx + math.cos(a) * R * 0.28, cy - 36 * k + math.sin(a) * R * 0.28 * INCLINACION
    love.graphics.line(cx, cy - 36 * k, x, y)
    love.graphics.circle("fill", x, y, 6 * k)
  end
  if d.angulo_pelota then
    local x = cx + math.cos(d.angulo_pelota) * R * d.radio_pelota
    local y = cy + math.sin(d.angulo_pelota) * R * d.radio_pelota * INCLINACION - 8 * k
    color({ 0, 0, 0 }, 0.35)
    love.graphics.ellipse("fill", x + 4 * k, y + 10 * k, 12 * k, 5 * k)
    y = y - (d.salto or 0) * k
    color({ 0.82, 0.8, 0.76 })
    love.graphics.circle("fill", x, y, 12 * k)
    color({ 0.98, 0.97, 0.94 })
    love.graphics.circle("fill", x - 2 * k, y - 2 * k, 9 * k)
  end
end

local function mesa(d, r)
  color(ORO)
  centrado(r.titulo, "RULETA", ANCHO / 2, 100)
  color(CREMA, 0.75)
  centrado(r.texto, "Elige tu apuesta: haz clic en el paño o en una opción", ANCHO / 2, 160)
  for _, z in ipairs(r.zonas.mesa) do
    local elegida = d.apuesta and z.apuesta == d.apuesta.nombre
    local encima = d.encima == z
    if z.numero then
      local cubre = d.apuesta and d.apuesta.cubre(z.numero)
      color(COLORES[Rueda.color(z.numero)])
      love.graphics.rectangle("fill", z.x, z.y, z.w, z.h)
      if d.apuesta and not cubre then
        color(FIELTRO, 0.65)
        love.graphics.rectangle("fill", z.x, z.y, z.w, z.h)
      end
      color(CREMA, (d.apuesta and not cubre) and 0.55 or 1)
      centrado(r.numero, tostring(z.numero), z.x + z.w / 2, z.y + z.h / 2)
    elseif z.opcion then
      color(CREMA, (elegida or encima) and 1 or 0.7)
      love.graphics.setLineWidth(1.5)
      love.graphics.rectangle(elegida and "fill" or "line", z.x + 8, z.y + 18, 28, 28, 4)
      if elegida then
        color(OSCURO)
        love.graphics.setLineWidth(3)
        love.graphics.line(z.x + 14, z.y + 32, z.x + 20, z.y + 39, z.x + 31, z.y + 24)
        color(CREMA)
      end
      love.graphics.setFont(r.etiqueta)
      love.graphics.print(z.apuesta, z.x + 52, z.y + 32 - r.etiqueta:getHeight() / 2)
      local muestra = COLORES[z.apuesta:lower()]
      if muestra then
        color(muestra)
        love.graphics.circle("fill", z.x + 72 + r.etiqueta:getWidth(z.apuesta), z.y + 32, 9)
      end
    elseif z.apuesta then
      color(CREMA, 0.85)
      centrado(r.etiqueta, z.texto, z.x + z.w / 2, z.y + z.h / 2)
    else
      boton(z, d, r)
    end
    if not z.opcion and not z.accion then
      color(CREMA, encima and 0.9 or 0.3)
      love.graphics.setLineWidth(encima and 2.5 or 1)
      love.graphics.rectangle("line", z.x, z.y, z.w, z.h)
    end
  end
  for _, z in ipairs(r.zonas.mesa) do
    if d.apuesta and z.apuesta == d.apuesta.nombre and not z.opcion then
      color(ORO)
      love.graphics.circle("fill", z.x + z.w / 2, z.y + z.h / 2, 17)
      color(OSCURO)
      love.graphics.setLineWidth(2)
      love.graphics.circle("line", z.x + z.w / 2, z.y + z.h / 2, 11)
    end
  end
  color(CREMA, 0.85)
  love.graphics.setFont(r.texto)
  love.graphics.print(d.apuesta and ("Tu apuesta: " .. d.apuesta.nombre .. " (paga " .. d.apuesta.paga .. " a 1), " .. d.apuesta.descripcion .. ".") or "Todavía no elegiste ninguna apuesta.", PX, 778)
  color(CREMA)
  love.graphics.setFont(r.boton)
  love.graphics.print("Dinero: " .. d.dinero .. " M", PX, 850)
  color(ORO)
  love.graphics.setFont(r.chica)
  love.graphics.print(d.mensaje or "", PX, 905)
  color(CREMA, 0.5)
  centrado(r.pequena, "Clic: elige apuesta      Apostar: elige el monto      Esc: salir      F1: +3 M", ANCHO / 2, 985)
end

local function ventana(d, x, y, w, h)
  color({ 0, 0, 0 }, 0.55 * d.aparicion)
  love.graphics.rectangle("fill", 0, 0, ANCHO, ALTO)
  local s = 0.96 + 0.04 * d.aparicion
  love.graphics.push()
  love.graphics.translate(ANCHO / 2, ALTO / 2)
  love.graphics.scale(s)
  love.graphics.translate(-ANCHO / 2, -ALTO / 2)
  color({ 0.04, 0.17, 0.11 })
  love.graphics.rectangle("fill", x, y, w, h, 10)
  color(ORO, 0.6)
  love.graphics.setLineWidth(1.5)
  love.graphics.rectangle("line", x, y, w, h, 10)
end

local function monto(d, r)
  ventana(d, 460, 250, 1000, 580)
  color(CREMA)
  centrado(r.grande, "¿Cuánto quieres apostar?", ANCHO / 2, 325)
  color(CREMA, 0.7)
  centrado(r.texto, "Apuesta: " .. d.apuesta.nombre .. " (paga " .. d.apuesta.paga .. " a 1)", ANCHO / 2, 380)
  color(ORO)
  centrado(r.cifra, d.monto .. " M", ANCHO / 2, 465)
  local f = d.maximo > d.minimo and (d.monto - d.minimo) / (d.maximo - d.minimo) or 1
  color(CREMA, 0.25)
  love.graphics.rectangle("fill", BARRA_X, BARRA_Y - 2, BARRA_ANCHO, 4, 2)
  color(ORO)
  love.graphics.rectangle("fill", BARRA_X, BARRA_Y - 2, BARRA_ANCHO * f, 4, 2)
  color((d.encima and d.encima.accion == "barra") and ORO or CREMA)
  love.graphics.circle("fill", BARRA_X + BARRA_ANCHO * f, BARRA_Y, 14)
  color(CREMA, 0.65)
  love.graphics.setFont(r.pequena)
  love.graphics.print(d.minimo .. " M", BARRA_X, BARRA_Y + 24)
  love.graphics.printf(d.maximo .. " M", BARRA_X + BARRA_ANCHO - 200, BARRA_Y + 24, 200, "right")
  color(CREMA, 0.45)
  centrado(r.chica, "Arrastra el círculo o usa las flechas", ANCHO / 2, BARRA_Y + 42)
  for _, z in ipairs(r.zonas.monto) do
    if z.texto then
      boton(z, d, r)
    end
  end
  love.graphics.pop()
end

local function escena(d, r)
  color(CREMA, 0.85)
  centrado(r.texto, "Tu apuesta: " .. d.apuesta.nombre .. " por " .. d.monto .. " M", ANCHO / 2, 110)
  rueda(d, r, ANCHO / 2, 560, 400 * d.acercamiento)
end

local function resultado(d, r)
  ventana(d, 330, 190, 1260, 720)
  color(d.gano and ORO or PERDIDA)
  centrado(r.enorme, d.gano and "GANASTE" or "PERDISTE", ANCHO / 2, 300)
  color(CREMA)
  centrado(r.grande, d.explicacion[1], ANCHO / 2, 420)
  color(CREMA, 0.7)
  centrado(r.texto, d.explicacion[2], ANCHO / 2, 488)
  color(d.gano and ORO or PERDIDA)
  centrado(r.texto, d.explicacion[3], ANCHO / 2, 536)
  color(CREMA, 0.7)
  centrado(r.pequena, "Dinero: " .. d.dinero .. " M", ANCHO / 2, 598)
  for _, z in ipairs(r.zonas.resultado) do
    boton(z, d, r)
  end
  love.graphics.pop()
end

function Vista.dibujar(d, r)
  local e, ox, oy = escala()
  love.graphics.clear(0, 0, 0)
  love.graphics.push()
  love.graphics.translate(ox, oy)
  love.graphics.scale(e)
  fondo(r)
  if d.etapa == "mesa" or d.etapa == "monto" then
    mesa(d, r)
  else
    escena(d, r)
  end
  if d.etapa == "monto" then
    monto(d, r)
  elseif d.etapa == "resultado" then
    resultado(d, r)
  end
  color(CREMA)
  love.graphics.draw(r.vineta, ANCHO / 2, ALTO / 2)
  if d.fundido > 0 then
    color({ 0, 0, 0 }, d.fundido)
    love.graphics.rectangle("fill", 0, 0, ANCHO, ALTO)
  end
  love.graphics.setLineWidth(1)
  love.graphics.pop()
end

return Vista
