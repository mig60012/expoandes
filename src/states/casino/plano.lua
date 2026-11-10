local function ovalo(x, y, rx, ry, lados)
  local puntos = {}
  for i = 0, lados - 1 do
    local angulo = i / lados * math.pi * 2
    puntos[#puntos + 1] = x + math.cos(angulo) * rx
    puntos[#puntos + 1] = y + math.sin(angulo) * ry
  end
  return puntos
end

local function rombo(x, y, a, b)
  return { x, y, x + a, y + a / 2, x + a - b, y + (a + b) / 2, x - b, y + b / 2 }
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
  for i = 1, #choque, 2 do
    suma_x, suma_y = suma_x + choque[i], suma_y + choque[i + 1]
  end
  objeto.nombre, objeto.choque = nombre, choque
  objeto.x, objeto.y = suma_x / (#choque / 2), suma_y / (#choque / 2)
  return objeto
end

local function pie_izquierda(x)
  return 400 + (1200 - x) / 2
end

local function pie_derecha(x)
  return 400 + (x - 1200) / 2
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
  estiramiento = 2,
  jugador = { velocidad = 440, radio = 26, alcance = 96, ancho = 84, alto = 150 },
  suelo = { 24, 988, 1200, 400, 2376, 988, 2376, 1338, 24, 1338 },
  paredes = {
    izquierda = { 0, 0, 1200, 0, 1200, 400, 0, 1000 },
    derecha = { 1200, 0, 2400, 0, 2400, 1000, 1200, 400 },
  },
  inicio = { x = 1830, y = 857 },
  puerta = {
    zona = { 1900, 752, 2040, 822, 1950, 867, 1810, 797 },
    marco = { 1900, 750, 2040, 820, 2040, 590, 1900, 520 },
  },
  objetos = {
    solido("mesa_blackjack", colocar(BLACKJACK, 1.66, 700, 1040), { interaccion = "blackjack", etiqueta = "Blackjack" }),
    solido("mesa_poker", ovalo(1200, 900, 146, 104, 24), { interaccion = "poker", etiqueta = "Póker" }),
    solido("mesa_ruleta", colocar(RULETA, 1.3, 1665, 1085), { interaccion = "ruleta", etiqueta = "Ruleta" }),
    solido("dueno", { 1230, 440, 1200, 456, 1170, 440, 1200, 424 }),
    solido("barra", rombo(950, pie_izquierda(950) + 3, 168, 520)),
    solido("caja", rombo(360, pie_izquierda(360) + 3, 130, 250)),
    solido("tragamonedas", rombo(1330, pie_derecha(1330) + 3, 412, 70)),
    solido("tragamonedas", rombo(2130, pie_derecha(2130) + 3, 204, 70)),
    solido("tragamonedas", rombo(1290, 615, 308, 70)),
    solido("tragamonedas", rombo(2060, 1075, 308, 70)),
    solido("columna", ovalo(1010, 770, 42, 21, 24)),
    solido("columna", ovalo(1450, 880, 42, 21, 24)),
    solido("columna", ovalo(960, 1200, 42, 21, 24)),
    solido("columna", ovalo(1380, 1240, 42, 21, 24)),
  },
}

return Plano
