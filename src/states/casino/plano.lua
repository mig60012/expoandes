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
  570, 735, 572, 712, 640, 675, 648, 622, 676, 608, 780, 604, 842, 618, 872, 645,
  905, 650, 925, 700, 925, 790, 885, 808, 845, 832, 775, 848, 720, 848, 655, 815,
  605, 795, 575, 765,
}

local BLACKJACK_SILUETA = {
  564, 735, 566, 700, 640, 640, 645, 555, 708, 550, 712, 600, 780, 578, 842, 594,
  858, 640, 922, 638, 925, 700, 925, 790, 885, 808, 845, 832, 775, 848, 720, 848,
  655, 815, 605, 795, 575, 765,
}

local RULETA = {
  1102, 1042, 1145, 1005, 1145, 968, 1440, 805, 1525, 800, 1600, 825, 1650, 870,
  1660, 915, 1640, 950, 1535, 1058, 1478, 1090, 1455, 1120, 1395, 1148, 1315, 1178,
  1210, 1180, 1095, 1140,
}

local RULETA_SILUETA = {
  1090, 1030, 1145, 1000, 1145, 925, 1185, 918, 1212, 883, 1258, 878, 1272, 848,
  1330, 798, 1338, 772, 1405, 772, 1410, 780, 1452, 772, 1460, 800, 1525, 798,
  1600, 820, 1652, 866, 1660, 915, 1640, 950, 1535, 1058, 1478, 1090, 1455, 1120,
  1395, 1148, 1315, 1178, 1210, 1180, 1095, 1140,
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
      interaccion = "blackjack", etiqueta = "Blackjack", silueta = BLACKJACK_SILUETA,
      foto = foto("mesa_blackjack", 294, 297, 191, 133),
    }),
    solido("mesa póker", ovalo(985, 918, 112, 92, 24), {
      interaccion = "poker", etiqueta = "Póker", silueta = ovalo(985, 900, 125, 112, 24),
      foto = foto("mesa_poker", 459, 430, 114, 99),
    }),
    solido("mesa ruleta", RULETA, {
      interaccion = "ruleta", etiqueta = "Ruleta", silueta = RULETA_SILUETA,
      foto = foto("mesa_ruleta", 574, 428, 289, 188),
    }),
  },
  obstaculos = {
    solido("columna de la esquina", { 196, 787, 240, 765, 262, 780, 262, 800, 220, 812 }),
    solido("tragamonedas de la izquierda", {
      262, 752, 485, 632, 530, 640, 528, 668, 505, 700, 498, 735, 430, 770, 360, 808, 300, 800,
    }),
    solido("tragamonedas del fondo", { 672, 548, 906, 428, 925, 440, 925, 500, 870, 530, 810, 556, 760, 570, 700, 570 }),
    solido("barra", {
      906, 428, 1457, 703, 1590, 637, 1590, 688, 1540, 730, 1460, 748, 1400, 742, 1350, 745,
      1255, 742, 1180, 708, 1105, 668, 1035, 630, 960, 592, 920, 560, 900, 440,
    }),
    solido("cashier", { 1580, 600, 1588, 718, 1610, 722, 1688, 748, 1730, 725, 1905, 640, 1720, 560 }),
    solido("gota a gota", { 2050, 738, 2190, 805, 2185, 830, 2140, 832, 2060, 805, 2045, 770 }, {
      silueta = { 2046, 802, 2048, 612, 2075, 590, 2122, 590, 2142, 612, 2142, 806 },
    }),
  },
}

return Plano
