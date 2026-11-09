local Plano = {
  ancho = 1920,
  alto = 1080,
  suelo = { 420, 430, 1500, 430, 1920, 1080, 0, 1080 },
  fondo = {
    techo = { 0, 0, 1920, 0, 1500, 90, 420, 90 },
    pared_izquierda = { 0, 0, 420, 90, 420, 430, 0, 1080 },
    pared_derecha = { 1500, 90, 1920, 0, 1920, 1080, 1500, 430 },
    pared_fondo = { 420, 90, 1500, 90, 1500, 430, 420, 430 },
  },
  profundidad = { y_fondo = 430, y_frente = 1080, escala_fondo = 0.6, escala_frente = 1 },
  inicio = { x = 1430, y = 580 },
  puerta = { zona = { 1540, 492, 1640, 647, 1550, 660, 1450, 505 } },
  objetos = {
    { nombre = "reloj", caja = { 900, 130, 120, 120 } },
    { nombre = "cuadro", caja = { 150, 250, 160, 200 } },
    { nombre = "puerta", caja = { 1540, 230, 100, 420 } },
    {
      nombre = "mesa_blackjack", x = 540, y = 740, caja = { 360, 560, 360, 300 },
      choque = { 380, 739, 662, 637, 700, 741, 418, 843 },
      interaccion = "blackjack", etiqueta = "Blackjack",
    },
    {
      nombre = "mesa_poker", x = 960, y = 650, caja = { 770, 470, 400, 310 },
      choque = { 780, 652, 1100, 536, 1140, 648, 820, 764 },
      interaccion = "poker", etiqueta = "Póker",
    },
    {
      nombre = "mesa_ruleta", x = 1380, y = 740, caja = { 1200, 560, 360, 300 },
      choque = { 1220, 739, 1502, 637, 1540, 741, 1258, 843 },
      interaccion = "ruleta", etiqueta = "Ruleta",
    },
    {
      nombre = "dueno", x = 520, y = 480, caja = { 470, 300, 100, 190 },
      choque = { 490, 465, 550, 465, 550, 495, 490, 495 },
      interaccion = "dueno", etiqueta = "Hablar con el dueño",
    },
    {
      nombre = "matera", x = 700, y = 460, caja = { 669, 376, 62, 99 },
      choque = { 670, 445, 730, 445, 730, 475, 670, 475 },
    },
    {
      nombre = "matera", x = 150, y = 1000, caja = { 103, 863, 95, 152 },
      choque = { 110, 985, 190, 985, 190, 1015, 110, 1015 },
    },
    {
      nombre = "matera", x = 1770, y = 1000, caja = { 1723, 863, 95, 152 },
      choque = { 1730, 985, 1810, 985, 1810, 1015, 1730, 1015 },
    },
    {
      nombre = "tragamonedas", x = 1290, y = 452, caja = { 1245, 290, 90, 180 },
      choque = { 1250, 435, 1330, 435, 1330, 470, 1250, 470 },
    },
    {
      nombre = "tragamonedas", x = 1410, y = 452, caja = { 1365, 290, 90, 180 },
      choque = { 1370, 435, 1450, 435, 1450, 470, 1370, 470 },
    },
  },
}

return Plano
