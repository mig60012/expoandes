local Giro = {}

local VUELTA = 2 * math.pi

local function frenar(x)
  return 1 - (1 - x) ^ 3
end

local function sostener(x)
  return (3 * x - x ^ 3) / 2
end

function Giro.nuevo(casilla, casillas, desde, opciones)
  opciones = opciones or {}
  return {
    casilla = casilla,
    casillas = casillas,
    desde = desde or 0,
    duracion = opciones.duracion or 6,
    caida = opciones.caida or 0.5,
    llegada = opciones.llegada or 0.75,
    vueltas_rueda = opciones.vueltas_rueda or 2,
    vueltas_pelota = opciones.vueltas_pelota or 12,
  }
end

function Giro.estado(g, t)
  t = math.max(0, math.min(t, g.duracion))
  local rueda = g.desde + g.vueltas_rueda * VUELTA * frenar(t / g.duracion)
  local pelota = rueda + (g.casilla - 1) * VUELTA / g.casillas
  local llegada = g.llegada * g.duracion
  if t >= llegada then
    return rueda, pelota, 0.71, 0
  end
  pelota = pelota + g.vueltas_pelota * VUELTA * (1 - sostener(t / llegada))
  local caida = g.caida * g.duracion
  if t < caida then
    return rueda, pelota, 1.1, 0
  end
  local p = (t - caida) / (llegada - caida)
  local rebote = math.abs(math.sin(p * 3 * math.pi)) * (1 - p)
  return rueda, pelota, 1.1 - 0.39 * p * p * (3 - 2 * p) + 0.06 * rebote, 24 * rebote
end

return Giro
