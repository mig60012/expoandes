local function ovalo(x, y, rx, ry, lados)
  local puntos = {}
  for i = 0, lados - 1 do
    local angulo = i / lados * math.pi * 2
    puntos[#puntos + 1] = x + math.cos(angulo) * rx
    puntos[#puntos + 1] = y + math.sin(angulo) * ry
  end
  return puntos
end

local function colocar(puntos, factor, x, y)
  local colocados = {}
  for i = 1, #puntos, 2 do
    colocados[i], colocados[i + 1] = x + puntos[i] * factor, y + puntos[i + 1] * factor
  end
  return colocados
end

local function solido(nombre, choque, extra)
  local objeto = extra or {}
  local suma_x, suma_y = 0, 0
  local izq_x, izq_y, der_x, der_y = math.huge, 0, -math.huge, 0
  for i = 1, #choque, 2 do
    suma_x, suma_y = suma_x + choque[i], suma_y + choque[i + 1]
    if choque[i] < izq_x then
      izq_x, izq_y = choque[i], choque[i + 1]
    end
    if choque[i] > der_x then
      der_x, der_y = choque[i], choque[i + 1]
    end
  end
  objeto.nombre, objeto.choque = nombre, choque
  objeto.x, objeto.y = suma_x / (#choque / 2), suma_y / (#choque / 2)
  objeto.linea = { x = (izq_x + der_x) / 2, y = (izq_y + der_y) / 2, pendiente = (der_y - izq_y) / (der_x - izq_x) }
  return objeto
end

-- Paredes sobre la referencia de 1257 x 706; mesas y puerta calibradas contra
-- el nuevo arte de 736 x 414, sin cambiar la asignacion de los juegos.
local ESCALA = 1.9
local ESCALA_ARTE = 2400 / 736
local function escena(puntos)
  return colocar(puntos, ESCALA, 0, 0)
end

local function foto(archivo, x, y, ancho, alto)
  return {
    archivo = archivo,
    x = x * ESCALA,
    y = y * ESCALA,
    ancho = ancho * ESCALA,
    alto = alto * ESCALA,
  }
end

local function arte(archivo, x, y, ancho, alto)
  return { archivo = archivo, ruta = "assets/casino/" .. archivo .. ".png",
    x = x * ESCALA_ARTE, y = y * ESCALA_ARTE,
    ancho = ancho * ESCALA_ARTE, alto = alto * ESCALA_ARTE }
end

local function arco_puerta()
  local puntos = { 975, 336 }
  for i = 0, 24 do
    local angulo = math.pi - i / 24 * math.pi
    local x = 1018 + 43 * math.cos(angulo)
    puntos[#puntos + 1] = x
    puntos[#puntos + 1] = 304 + (x - 1018) / 2 - 88 * math.sin(angulo)
  end
  puntos[#puntos + 1], puntos[#puntos + 2] = 1061, 378
  return escena(puntos)
end

local BLACKJACK = {
  67, -71, 101, -53, 122, -30, 127, -10, 115, 20, 99, 36, 64, 56,
  30, 66, -14, 71, -67, 65, -94, 64, -109, 54, -128, 27,
}

local RULETA = {
  110, -104, 184, -69, 194, -58, 194, -34, 200, 10, -40, 132, -92, 130,
  -196, 54, -194, 40, -18, -53, -17, -69, 28, -92, 66, -104,
}

local Plano = {
  ancho = 2400,
  alto = 1350,
  vista = { ancho = 1536, alto = 864 },
  arte = { ruta = "assets/casino/sala.png" },
  estiramiento = 2,
  jugador = { velocidad = 440, radio = 26, alcance = 96, ancho = 84, alto = 150 },
  suelo = escena({ 102, 414, 477, 224, 767, 370, 905, 301, 1151, 423, 628, 686 }),
  -- Las paredes se prolongan hasta el borde del lienzo. La camara muestra el
  -- interior, no el recorte negro que rodeaba la maqueta isometrica.
  capas = {
    { color = { 0.54, 0.54, 0.54 }, puntos = escena({ 0, 0, 477, 0, 477, 224, 0, 466 }) },
    { color = { 0.67, 0.67, 0.67 }, puntos = escena({ 477, 0, 767, 0, 767, 370, 477, 224 }) },
    { color = { 0.54, 0.54, 0.54 }, puntos = escena({ 767, 0, 905, 0, 905, 301, 767, 370 }) },
    { color = { 0.67, 0.67, 0.67 }, puntos = escena({ 905, 0, 1264, 0, 1264, 479, 905, 301 }) },
  },
  inicio = { x = 574 * ESCALA_ARTE, y = 265 * ESCALA_ARTE },
  puerta = {
    zona = colocar({ 598,221, 637,241, 611,254, 572,234 }, ESCALA_ARTE, 0, 0),
    marco = arco_puerta(),
    centro = { x = 604 * ESCALA_ARTE, y = 237 * ESCALA_ARTE },
  },
  objetos = {
    solido("mesa blackjack", colocar(BLACKJACK, 0.40 * ESCALA_ARTE, 232 * ESCALA_ARTE, 220 * ESCALA_ARTE), {
      interaccion = "blackjack", etiqueta = "Blackjack",
      foto = foto("mesa_blackjack", 294, 297, 191, 133),
      arte = arte("sala_blackjack", 172, 174, 112, 78),
    }),
    solido("mesa póker", colocar(ovalo(302, 285, 32, 22, 24), ESCALA_ARTE, 0, 0), {
      interaccion = "poker", etiqueta = "Póker",
      foto = foto("mesa_poker", 459, 430, 114, 99),
      arte = arte("sala_poker", 269, 252, 67, 58),
    }),
    solido("mesa ruleta", colocar(RULETA, 0.36 * ESCALA_ARTE, 421 * ESCALA_ARTE, 313 * ESCALA_ARTE), {
      interaccion = "ruleta", etiqueta = "Ruleta",
      foto = foto("mesa_ruleta", 574, 428, 289, 188),
      arte = arte("sala_ruleta", 336, 251, 169, 110),
    }),
  },
}

return Plano
