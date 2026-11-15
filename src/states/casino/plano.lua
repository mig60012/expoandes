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

-- Paredes sobre la referencia de 1257 x 706.
local ESCALA = 1.9
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
  566, 702, 780, 578, 842, 594, 872, 630, 880, 680, 862, 740, 826, 778,
  775, 805, 715, 818, 655, 812, 605, 792, 575, 762, 564, 730,
}

local RULETA = {
  1152, 998, 1455, 836, 1525, 814, 1600, 830, 1645, 872, 1652, 915,
  1628, 955, 1318, 1100, 1172, 1035,
}

local SALON = "assets/casino/salon/"

local Plano = {
  ancho = 2400,
  alto = 1350,
  vista = { ancho = 1536, alto = 864 },
  arte = {
    ruta = SALON .. "fondo.png",
    multiplicar = SALON .. "filtro_1_multiply.png",
    sumar = { SALON .. "filtro_2_add.png", SALON .. "filtro_3_add.png" },
  },
  estiramiento = 2,
  jugador = { velocidad = 440, radio = 26, alcance = 96, ancho = 84, alto = 205 },
  suelo = escena({ 102, 414, 477, 224, 767, 370, 905, 301, 1151, 423, 628, 686 }),
  -- Las paredes se prolongan hasta el borde del lienzo. La camara muestra el
  -- interior, no el recorte negro que rodeaba la maqueta isometrica.
  capas = {
    { color = { 0.54, 0.54, 0.54 }, puntos = escena({ 0, 0, 477, 0, 477, 224, 0, 466 }) },
    { color = { 0.67, 0.67, 0.67 }, puntos = escena({ 477, 0, 767, 0, 767, 370, 477, 224 }) },
    { color = { 0.54, 0.54, 0.54 }, puntos = escena({ 767, 0, 905, 0, 905, 301, 767, 370 }) },
    { color = { 0.67, 0.67, 0.67 }, puntos = escena({ 905, 0, 1264, 0, 1264, 479, 905, 301 }) },
  },
  inicio = { x = 1940, y = 805 },
  puerta = {
    zona = { 1925, 740, 1985, 710, 2045, 740, 1985, 770 },
    marco = arco_puerta(),
    centro = { x = 1985, y = 740 },
  },
  objetos = {
    solido("mesa blackjack", BLACKJACK, {
      interaccion = "blackjack", etiqueta = "Blackjack",
      foto = foto("mesa_blackjack", 294, 297, 191, 133),
    }),
    solido("mesa póker", ovalo(985, 893, 102, 86, 24), {
      interaccion = "poker", etiqueta = "Póker",
      foto = foto("mesa_poker", 459, 430, 114, 99),
    }),
    solido("mesa ruleta", RULETA, {
      interaccion = "ruleta", etiqueta = "Ruleta",
      foto = foto("mesa_ruleta", 574, 428, 289, 188),
    }),
  },
}

return Plano
