-- Reglas, motor y vista del subestado de blackjack.
-- Reglas puras, IA sin información privada, motor y vista separados aquí.
-- Opciones de enter: minimo=2, incremento=2, saldo_bots=100, semilla,
-- pausa=0.65, puede_jugar y al_jugar (callbacks existentes del casino).
local Audio = require("src/systems/audio")
local Blackjack = {}
local Reglas, Bot, Motor, Vista = {}, {}, {}, {}
local MAX_PARTIDAS = 4

function Reglas.valor(c) return math.min(c.rank, 10) end
function Reglas.total(cartas)
  local total, ases = 0, 0
  for _, c in ipairs(cartas) do
    total = total + (c.rank == 1 and 11 or Reglas.valor(c))
    if c.rank == 1 then ases = ases + 1 end
  end
  while total > 21 and ases > 0 do total, ases = total - 10, ases - 1 end
  return total, ases > 0
end
function Reglas.natural(mano)
  return not mano.dividida and #mano.cartas == 2 and Reglas.total(mano.cartas) == 21
end
function Reglas.apuesta(monto, saldo, minimo, incremento)
  return type(monto) == "number" and monto == monto and monto < math.huge
    and monto >= minimo and monto <= saldo and monto % 2 == 0
    and (monto - minimo) % incremento == 0
end
function Reglas.acciones(jugador, mano, saldo)
  local abierta = mano ~= nil and not mano.cerrada and Reglas.total(mano.cartas) < 21
  return { pedir = abierta, plantarse = abierta,
    dividir = abierta and not jugador.dividio and #mano.cartas == 2
      and Reglas.valor(mano.cartas[1]) == Reglas.valor(mano.cartas[2])
      and saldo >= mano.apuesta }
end
function Reglas.pago(mano, crupier)
  local total, banca = Reglas.total(mano.cartas), Reglas.total(crupier.cartas)
  local natural, natural_banca = Reglas.natural(mano), Reglas.natural(crupier)
  if total > 21 then return 0, "Te pasaste" end
  if natural and natural_banca then return mano.apuesta, "Empate de blackjack" end
  if natural_banca then return 0, "Blackjack del crupier" end
  if natural then return mano.apuesta * 2.5, "Blackjack natural" end
  if banca > 21 or total > banca then return mano.apuesta * 2, "Victoria" end
  if total == banca then return mano.apuesta, "Empate" end
  return 0, "Derrota"
end
-- PRNG privado: ni el audio ni otros estados alteran la semilla de pruebas.
local function aleatorio(semilla)
  local estado = math.floor(tonumber(semilla) or os.time()) % 2147483647
  if estado <= 0 then estado = 1 end
  return function(n)
    estado = (estado * 16807) % 2147483647
    local v = (estado - 1) / 2147483646
    return n and (math.floor(v * n) + 1) or v
  end
end
function Reglas.mazo(random)
  local cartas = {}
  for _, palo in ipairs({ "hearts", "spades", "diamonds", "clubs" }) do
    for rank = 1, 13 do cartas[#cartas + 1] = { rank = rank, suit = palo } end
  end
  for i = #cartas, 2, -1 do
    local j = random(i)
    cartas[i], cartas[j] = cartas[j], cartas[i]
  end
  return cartas
end

-- Solo recibe cartas públicas; la carta tapada cuenta entre las no vistas.
function Bot.riesgo(mano, reveladas)
  local restantes, vistas = {}, {}
  for rank = 1, 13 do restantes[rank] = 4 end
  for _, c in ipairs(reveladas) do
    local id = c.suit .. c.rank
    if not vistas[id] then
      vistas[id] = true
      restantes[c.rank] = restantes[c.rank] - 1
    end
  end
  local malas, todas, simulada = 0, 0, {}
  for i, c in ipairs(mano.cartas) do simulada[i] = c end
  for rank = 1, 13 do
    simulada[#mano.cartas + 1] = { rank = rank }
    local n = math.max(0, restantes[rank])
    todas = todas + n
    if Reglas.total(simulada) > 21 then malas = malas + n end
  end
  return todas > 0 and malas / todas or 1
end
function Bot.decidir(mano, visible, reveladas, saldo, validas, perfil, random)
  local riesgo = Bot.riesgo(mano, reveladas)
  if validas.dividir and saldo >= mano.apuesta
    and (mano.cartas[1].rank == 1 or mano.cartas[1].rank == 8) then
    return "dividir", riesgo
  end
  if not validas.pedir then return "plantarse", riesgo end
  local total, suave = Reglas.total(mano.cartas)
  local fuerte = visible.rank == 1 or Reglas.valor(visible) >= 7
  if total <= 11 then return "pedir", riesgo end
  if total >= 19 then return "plantarse", riesgo end
  if suave and total <= 17 then return "pedir", riesgo end
  local limite = perfil == "conservador" and 0.34 or 0.52
  limite = limite + (fuerte and 0.10 or -0.12) - math.max(0, total - 16) * 0.08
  -- Variación pequeña únicamente cerca del umbral de decisión.
  if math.abs(riesgo - limite) < 0.06 then limite = limite + (random() - 0.5) * 0.08 end
  return riesgo <= limite and "pedir" or "plantarse", riesgo
end
function Bot.apuesta(saldo, perfil, minimo, incremento, random)
  if saldo < minimo then return nil end
  local pasos = math.floor((saldo - minimo) / incremento)
  local deseados = perfil == "conservador" and 0 or random(4) - 1
  return minimo + math.min(pasos, deseados) * incremento
end

Motor.__index = Motor
local function mano(apuesta, cartas, dividida)
  return { apuesta = apuesta, cartas = cartas or {}, dividida = dividida or false, cerrada = false }
end
function Motor.nuevo(economia, opciones)
  opciones = opciones or {}
  local minimo, incremento = opciones.minimo or 2, opciones.incremento or 2
  assert(minimo > 0 and minimo % 2 == 0, "El mínimo debe ser un entero positivo par")
  assert(incremento > 0 and incremento % 2 == 0, "El incremento debe ser un entero positivo par")
  local self = setmetatable({ economia = economia, opciones = opciones,
    minimo = minimo, incremento = incremento, random = aleatorio(opciones.semilla),
    pausa = math.max(0.05, opciones.pausa or 0.65), eventos = {}, ronda = 0,
    jugadores = { { nombre = "Tú", humano = true },
      { nombre = "Bot 1", perfil = "conservador", saldo = opciones.saldo_bots or 100 },
      { nombre = "Bot 2", perfil = "arriesgado", saldo = opciones.saldo_bots or 100 } } }, Motor)
  self:nueva_ronda()
  return self
end
function Motor:saldo(j) return j.humano and self.economia:get_money() or j.saldo end
function Motor:debitar(j, monto)
  if self:saldo(j) < monto then return false end
  if j.humano then return self.economia:spend_money(monto) end
  j.saldo = j.saldo - monto
  return true
end
function Motor:acreditar(j, monto)
  if j.humano then self.economia:add_money(monto) else j.saldo = j.saldo + monto end
end
function Motor:evento(nombre) self.eventos[#self.eventos + 1] = nombre end
function Motor:puede_jugar()
  return not self.opciones.puede_jugar or self.opciones.puede_jugar()
end
function Motor:nueva_ronda()
  if self.fase and self.fase ~= "resultado" then return false end
  self.fase, self.tiempo, self.cola = "apuestas", 0, {}
  self.turno, self.indice_mano, self.revelada = nil, nil, false
  self.crupier, self.mazo = mano(0), Reglas.mazo(self.random)
  self.monto, self.mensaje = self.minimo, "Elige tu apuesta. Cada mano juega contra el crupier."
  for _, j in ipairs(self.jugadores) do j.manos, j.dividio, j.accion, j.ganador = {}, false, nil, false end
  if not self:puede_jugar() then self.mensaje = "Ya no quedan jugadas por hoy. Vuelve al casino."
  elseif self:saldo(self.jugadores[1]) < self.minimo then
    self.mensaje = "Saldo insuficiente: necesitas " .. self.minimo .. " M. Puedes volver al casino."
  end
  return true
end
function Motor:cambiar_monto(paso)
  if self.fase ~= "apuestas" then return end
  local maximo = self.minimo + math.floor((self:saldo(self.jugadores[1]) - self.minimo) / self.incremento) * self.incremento
  self.monto = math.max(self.minimo, math.min(maximo, self.monto + paso * self.incremento))
end
function Motor:confirmar()
  if self.fase ~= "apuestas" then return false end
  if not self:puede_jugar() then self.mensaje = "Ya no quedan jugadas por hoy."; return false end
  if not Reglas.apuesta(self.monto, self:saldo(self.jugadores[1]), self.minimo, self.incremento) then
    self.mensaje = "Apuesta inválida o saldo insuficiente. Mínimo: " .. self.minimo .. " M; paso: " .. self.incremento .. " M."
    return false
  end
  for i, j in ipairs(self.jugadores) do
    local monto = i == 1 and self.monto or Bot.apuesta(self:saldo(j), j.perfil, self.minimo, self.incremento, self.random)
    if monto and self:debitar(j, monto) then j.manos = { mano(monto) }
    else j.accion = "Sin saldo: no juega" end
  end
  self.fase, self.tiempo, self.ronda = "reparto", 0, self.ronda + 1
  for _ = 1, 2 do
    for _, j in ipairs(self.jugadores) do
      if j.manos[1] then self.cola[#self.cola + 1] = j.manos[1] end
    end
    self.cola[#self.cola + 1] = self.crupier
  end
  self.vuelta = 1
  self:evento("chip_place")
  if self.opciones.al_jugar then self.opciones.al_jugar(self.monto) end
  self.mensaje = "Repartiendo las cartas…"
  return true
end
function Motor:robar(m)
  local c = assert(table.remove(self.mazo), "Mazo agotado")
  m.cartas[#m.cartas + 1] = c
  self:evento("card_flip")
end
function Motor:publicas()
  local cartas = {}
  for i, c in ipairs(self.crupier.cartas) do
    if i == 1 or self.revelada then cartas[#cartas + 1] = c end
  end
  for _, j in ipairs(self.jugadores) do
    for _, m in ipairs(j.manos) do
      for _, c in ipairs(m.cartas) do cartas[#cartas + 1] = c end
    end
  end
  return cartas
end
function Motor:validas(indice)
  if self.fase ~= "turnos" or self.turno ~= indice then return {} end
  local j = self.jugadores[indice]
  return Reglas.acciones(j, j.manos[self.indice_mano], self:saldo(j))
end
function Motor:avanzar()
  local manos = {}
  for i, j in ipairs(self.jugadores) do
    for k, m in ipairs(j.manos) do
      if Reglas.total(m.cartas) >= 21 then m.cerrada = true end
      if not m.cerrada then manos[#manos + 1] = { jugador = i, mano = k } end
    end
  end

  if #manos > 0 then
    if not self.turno then
      self.turno, self.indice_mano = manos[1].jugador, manos[1].mano
    else
      local siguiente
      for _, posicion in ipairs(manos) do
        if posicion.jugador > self.turno
          or (posicion.jugador == self.turno and posicion.mano > self.indice_mano) then
          siguiente = posicion
          break
        end
      end
      if not siguiente then
        if self.vuelta >= 5 then manos = {}
        else
          self.vuelta = self.vuelta + 1
          siguiente = manos[1]
        end
      end
      if siguiente then
        self.turno, self.indice_mano = siguiente.jugador, siguiente.mano
      end
    end
  end

  if #manos > 0 then
    local jugador = self.jugadores[self.turno]
    self.mensaje = jugador.humano and ("Tu turno · mano " .. self.indice_mano) or "Turno de los demás jugadores."
    self.fase, self.tiempo = "turnos", 0
    return
  end
  self.fase, self.turno, self.indice_mano, self.tiempo = "crupier", nil, nil, 0
  self.mensaje = "El crupier revela su carta."
end
function Motor:accion(indice, accion)
  if not self:validas(indice)[accion] then return false end
  local j, k = self.jugadores[indice], self.indice_mano
  local m = j.manos[k]
  if accion == "dividir" then
    if not self:debitar(j, m.apuesta) then return false end
    j.dividio = true
    local c = table.remove(m.cartas)
    m.dividida = true
    j.manos[2] = mano(m.apuesta, { c }, true)
    self.fase, self.tiempo = "division", 0
    self.cola = { m, j.manos[2] }
    self.ases_divididos = m.cartas[1].rank == 1
    self:evento("chip_place")
    self.mensaje = "Dividiendo: una carta para cada mano…"
  elseif accion == "pedir" then
    self:robar(m)
    -- Bloqueo breve contra doble clic; la carta se muestra antes de avanzar.
    self.fase, self.tiempo = "carta", 0
  else
    m.cerrada = true
    self:evento("clack")
    self:avanzar()
  end
  j.accion = ({ pedir = "Pide", plantarse = "Se planta", dividir = "Divide" })[accion]
  return true
end
function Motor:liquidar()
  if self.fase == "resultado" then return false end
  self.revelada = true
  for _, j in ipairs(self.jugadores) do
    for _, m in ipairs(j.manos) do
      if not m.liquidada then
        m.pago, m.resultado = Reglas.pago(m, self.crupier)
        m.neto, m.liquidada, m.cerrada = m.pago - m.apuesta, true, true
        m.ganadora = m.neto > 0
        j.ganador = j.ganador or m.ganadora
        self:acreditar(j, m.pago)
      end
    end
  end
  self.fase, self.turno, self.indice_mano = "resultado", nil, nil
  self.mensaje = "Ronda terminada. Los pagos ya están incluidos en los saldos."
  if self:saldo(self.jugadores[1]) < self.minimo then
    self.mensaje = "Saldo insuficiente para otra ronda (mínimo " .. self.minimo .. " M). Vuelve al casino."
  elseif not self:puede_jugar() then
    self.mensaje = "Ronda liquidada. Completaste las jugadas disponibles; vuelve al casino."
  end
  self:evento("chip_place")
  return true
end
function Motor:update(dt)
  if self.fase == "apuestas" or self.fase == "resultado" then return end
  if self.fase == "turnos" and self.turno == 1 then return end
  self.tiempo = self.tiempo + dt
  if self.tiempo < self.pausa then return end
  self.tiempo = 0 -- Nunca consumir varios pasos visuales en el mismo cuadro.
  if self.fase == "reparto" or self.fase == "division" then
    if #self.cola > 0 then self:robar(table.remove(self.cola, 1)); return end
    if self.fase == "division" then
      if self.ases_divididos then
        for _, m in ipairs(self.jugadores[self.turno].manos) do m.cerrada = true end
      end
      self:avanzar()
    elseif Reglas.natural(self.crupier) then self:liquidar()
    else self:avanzar() end
  elseif self.fase == "carta" then self:avanzar()
  elseif self.fase == "turnos" then
    local j = self.jugadores[self.turno]
    local accion, riesgo = Bot.decidir(j.manos[self.indice_mano], self.crupier.cartas[1],
      self:publicas(), self:saldo(j), self:validas(self.turno), j.perfil, self.random)
    j.riesgo = riesgo
    self:accion(self.turno, accion)
  elseif self.fase == "crupier" then
    if not self.revelada then self.revelada = true; self:evento("card_flip"); return end
    local comparar = false
    for _, j in ipairs(self.jugadores) do
      for _, m in ipairs(j.manos) do
        if Reglas.total(m.cartas) <= 21 and not Reglas.natural(m) then comparar = true end
      end
    end
    if comparar and Reglas.total(self.crupier.cartas) < 17 then self:robar(self.crupier)
    else self:liquidar() end
  end
end

-- Vista con lienzo virtual: mismos puntos para dibujo y ratón en toda resolución.
local ANCHO, ALTO = 1280, 800
local ORO, TEXTO = { 0.84, 0.70, 0.43 }, { 0.94, 0.93, 0.85 }
function Vista.escala()
  local w, h = love.graphics.getDimensions()
  local s = math.min(w / ANCHO, h / ALTO)
  return s, (w - ANCHO * s) / 2, (h - ALTO * s) / 2
end
function Vista.recursos()
  local g = love.graphics
  local r = { fondo = g.newImage("assets/casino/blackjack/fondo_blackjack.png"),
    titulo = g.newFont("assets/AntonSC-Regular.ttf", 44),
    texto = g.newFont("assets/AntonSC-Regular.ttf", 20),
    chica = g.newFont("assets/AntonSC-Regular.ttf", 16),
    atlas = g.newImage("assets/casino/poker/cards_atlas.png"), frentes = {} }
  for fila, palo in ipairs({ "hearts", "spades", "diamonds", "clubs" }) do
    r.frentes[palo] = {}
    for rank = 1, 13 do r.frentes[palo][rank] = g.newQuad(rank * 56, (fila - 1) * 80, 56, 80, r.atlas) end
  end
  r.dorso = g.newQuad(0, 160, 56, 80, r.atlas)
  return r
end
function Vista.botones(m)
  local libre = m.fase == "apuestas" or m.fase == "resultado"
  local botones = { { id = "salir", texto = "Esc · Volver al casino", x = 1010, y = 26, w = 244, h = 48,
    color = { 0.28, 0.10, 0.13 }, activo = libre } }
  local function agregar(id, texto, x, w, activo)
    local colores = {
      menos = { 0.18, 0.28, 0.34 }, mas = { 0.18, 0.28, 0.34 },
      confirmar = { 0.42, 0.29, 0.12 }, siguiente = { 0.42, 0.29, 0.12 },
      pedir = { 0.42, 0.29, 0.12 }, plantarse = { 0.16, 0.31, 0.31 },
      dividir = { 0.29, 0.17, 0.34 },
    }
    botones[#botones + 1] = { id = id, texto = texto, x = x, y = 702, w = w, h = 48,
      color = colores[id], activo = activo }
  end
  if m.fase == "apuestas" then
    local saldo = m:saldo(m.jugadores[1])
    agregar("menos", "−", 325, 64, m.monto > m.minimo)
    agregar("mas", "+", 405, 64, m.monto + m.incremento <= saldo)
    agregar("confirmar", "Confirmar apuesta · Enter", 490, 465,
      m:puede_jugar() and Reglas.apuesta(m.monto, saldo, m.minimo, m.incremento))
  elseif m.fase == "resultado" then
    agregar("siguiente", "Siguiente ronda · Enter", 450, 380, m:puede_jugar() and m:saldo(m.jugadores[1]) >= m.minimo)
  else
    local v = m:validas(1)
    agregar("pedir", "Pedir · P", 280, 220, v.pedir)
    agregar("plantarse", "Plantarse · S", 530, 220, v.plantarse)
    agregar("dividir", "Dividir · D", 780, 220, v.dividir)
  end
  return botones
end
local function texto(r, contenido, x, y, w, fuente, color)
  love.graphics.setFont(r[fuente or "texto"])
  love.graphics.setColor(color or TEXTO)
  love.graphics.printf(contenido, x, y, w, "center")
end
function Vista.mano(r, m, x, y, w, activa, oculta, indice)
  local g = love.graphics
  local cartas = oculta and { m.cartas[1] } or m.cartas
  local total = #m.cartas > 0 and Reglas.total(cartas) or 0
  texto(r, (indice and ("Mano " .. indice .. " · ") or "") .. (oculta and "Visible: " or "Total: ") .. total
    .. (m.apuesta > 0 and (" · " .. m.apuesta .. " M") or ""), x, y + 7, w, "chica")
  local paso = math.min(57, (w - 76) / math.max(1, #m.cartas - 1))
  local inicio = x + (w - (56 + paso * math.max(0, #m.cartas - 1))) / 2
  for i, c in ipairs(m.cartas) do
    g.setColor(1, 1, 1)
    g.draw(r.atlas, (oculta and i == 2) and r.dorso or r.frentes[c.suit][c.rank], inicio + (i - 1) * paso, y + 36)
  end
  local estado = (m.ganadora and "GANADORA · " or "") .. (m.resultado or (Reglas.natural(m) and "Blackjack natural")
    or (total > 21 and "Se pasó") or (m.cerrada and "Mano cerrada") or (activa and "EN TURNO") or ""
  )
  if oculta then estado = "Carta oculta" end
  texto(r, estado, x + 3, y + 119, w - 6, "chica", activa and ORO or TEXTO)
  if m.liquidada then
    local balance = m.neto > 0 and ("Ganó " .. m.neto) or m.neto < 0 and ("Perdió " .. -m.neto) or ("Recuperó " .. m.apuesta)
    texto(r, balance .. " M · abono " .. m.pago .. " M", x + 3, y + 143, w - 6, "chica")
  end
end
function Vista.jugador(r, m, i, x, y, w)
  local j = m.jugadores[i]
  if j.humano then texto(r, j.nombre, x, y, w, "texto", ORO) end
  if j.humano then
    texto(r, "Saldo: " .. m:saldo(j) .. " M" .. (j.accion and (" · " .. j.accion) or ""), x, y + 27, w, "chica")
  end
  if #j.manos == 0 then
    if j.humano then texto(r, j.accion or "Esperando apuesta", x, y + 100, w, "chica") end
  else
    local ancho = (w - (#j.manos - 1) * 10) / #j.manos
    for k, mano_actual in ipairs(j.manos) do
      Vista.mano(r, mano_actual, x + (k - 1) * (ancho + 10), y + 54, ancho,
        m.turno == i and m.indice_mano == k, false, #j.manos > 1 and k or nil)
    end
  end
end
function Vista.dibujar(r, m, confirmar_salida)
  local g = love.graphics
  g.push("all")
  g.origin()
  g.clear(0.025, 0.055, 0.047)
  local s, ox, oy = Vista.escala()
  g.translate(ox, oy); g.scale(s)
  local fondo = r.fondo
  local escala_fondo = math.max(ANCHO / fondo:getWidth(), ALTO / fondo:getHeight())
  g.setColor(1, 1, 1, 1)
  g.draw(fondo, (ANCHO - fondo:getWidth() * escala_fondo) / 2,
    (ALTO - fondo:getHeight() * escala_fondo) / 2, 0, escala_fondo, escala_fondo)
  texto(r, "BLACKJACK", 24, 17, 330, "titulo", ORO)
  texto(r, "DINERO: " .. m:saldo(m.jugadores[1]) .. " M", 370, 30, 230, "chica", ORO)
  texto(r, "PARTIDAS: " .. math.min(m.ronda, MAX_PARTIDAS) .. " / " .. MAX_PARTIDAS, 610, 30, 300, "chica")
  texto(r, "CRUPIER", 420, 244, 440, "texto", ORO)
  Vista.mano(r, m.crupier, 460, 278, 360, m.fase == "crupier", not m.revelada and #m.crupier.cartas >= 2)
  Vista.jugador(r, m, 2, 26, 314, 390)
  Vista.jugador(r, m, 3, 864, 314, 390)
  Vista.jugador(r, m, 1, 440, 438, 400)
  local mensaje = m.mensaje
  if m.fase == "apuestas" then mensaje = mensaje .. "  Apuesta: " .. m.monto .. " M." end
  texto(r, mensaje, 50, 662, 1180, "texto")
  local mx, my = love.mouse.getPosition(); mx, my = (mx - ox) / s, (my - oy) / s
  for _, b in ipairs(Vista.botones(m)) do
    local encima = mx >= b.x and mx <= b.x + b.w and my >= b.y and my <= b.y + b.h
    local color = b.color
    g.setColor(0.025, 0.025, 0.025, 0.72)
    g.rectangle("fill", b.x + 5, b.y + 6, b.w, b.h, 13)
    g.setColor(not b.activo and { 0.15, 0.16, 0.17 } or encima
      and { math.min(1, color[1] + 0.14), math.min(1, color[2] + 0.14), math.min(1, color[3] + 0.14) }
      or color)
    g.rectangle("fill", b.x, b.y, b.w, b.h, 13)
    g.setColor(b.activo and ORO or { 0.32, 0.32, 0.32 })
    g.setLineWidth(2)
    g.rectangle("line", b.x, b.y, b.w, b.h, 13)
    texto(r, b.texto, b.x, b.y + 10, b.w, "chica", b.activo and TEXTO or { 0.58, 0.58, 0.58 })
  end
  if confirmar_salida then
    g.setColor(0, 0, 0, 0.78)
    g.rectangle("fill", 0, 0, ANCHO, ALTO)
    g.setColor(0.06, 0.10, 0.09, 0.98)
    g.rectangle("fill", 300, 285, 680, 230, 14)
    g.setColor(ORO)
    g.setLineWidth(2)
    g.rectangle("line", 300, 285, 680, 230, 14)
    texto(r, "¿Salir del blackjack?", 330, 310, 620, "titulo", ORO)
    texto(r, "Si sales ahora, perderás las partidas restantes de las 4 rondas.", 330, 370, 620, "chica")
    for _, b in ipairs({
      { texto = "Sí, salir", x = 390, color = { 0.38, 0.13, 0.15 } },
      { texto = "No, seguir jugando", x = 650, color = { 0.16, 0.31, 0.31 } },
    }) do
      g.setColor(b.color)
      g.rectangle("fill", b.x, 440, 240, 52, 13)
      g.setColor(ORO)
      g.rectangle("line", b.x, 440, 240, 52, 13)
      texto(r, b.texto, b.x, 453, 240, "chica")
    end
  end
  texto(r, "Natural paga 3:2 · Victoria 1:1 · Una división · Ases divididos: una carta · ← / → apuesta", 40, 771, 1200, "chica")
  g.pop()
end

-- Adaptador del subestado ya registrado: ningún callback global de LÖVE.
function Blackjack:enter(context, machine, opciones)
  self.context, self.machine = context, machine
  self.partidas = 0
  local opciones_motor = {}
  for clave, valor in pairs(opciones or {}) do opciones_motor[clave] = valor end
  local puede_jugar, al_jugar = opciones_motor.puede_jugar, opciones_motor.al_jugar
  opciones_motor.puede_jugar = function()
    return self.partidas < MAX_PARTIDAS and (not puede_jugar or puede_jugar())
  end
  opciones_motor.al_jugar = function(monto)
    self.partidas = self.partidas + 1
    if al_jugar then al_jugar(monto) end
  end
  self.motor = Motor.nuevo(context.economy, opciones_motor)
  self.recursos = Vista.recursos()
  self.raton_visible = love.mouse.isVisible()
  love.mouse.setVisible(true)
end
function Blackjack:listo_para_salir()
  return self.motor.fase == "resultado" or self.motor.fase == "apuestas"
end
function Blackjack:ejecutar(accion)
  local m = self.motor
  if accion == "salir" then
    if self.partidas >= MAX_PARTIDAS then self.machine:switch(nil)
    else self.confirmar_salida = true end
  elseif accion == "confirmar_salir" then
    self.machine:switch(nil)
  elseif accion == "cancelar_salir" then
    self.confirmar_salida = false
  elseif accion == "menos" then m:cambiar_monto(-1)
  elseif accion == "mas" then m:cambiar_monto(1)
  elseif accion == "confirmar" then m:confirmar()
  elseif accion == "siguiente" then
    if m.fase == "resultado" and m:puede_jugar() and m:saldo(m.jugadores[1]) >= m.minimo then m:nueva_ronda() end
  else m:accion(1, accion) end
end
function Blackjack:keypressed(key, _, isrepeat)
  if isrepeat then return end
  if self.confirmar_salida then
    if key == "y" then self:ejecutar("confirmar_salir")
    elseif key == "n" or key == "escape" then self:ejecutar("cancelar_salir") end
    return
  end
  local mapa = { escape = "salir", left = "menos", down = "menos", right = "mas", up = "mas",
    p = "pedir", s = "plantarse", d = "dividir" }
  local accion = mapa[key]
  if key == "return" or key == "z" then
    accion = self.motor.fase == "apuestas" and "confirmar" or self.motor.fase == "resultado" and "siguiente" or nil
  end
  if accion then self:ejecutar(accion) end
end
function Blackjack:mousepressed(x, y, button)
  if button ~= 1 then return end
  local s, ox, oy = Vista.escala(); x, y = (x - ox) / s, (y - oy) / s
  if self.confirmar_salida then
    if x >= 390 and x <= 630 and y >= 440 and y <= 492 then self:ejecutar("confirmar_salir")
    elseif x >= 650 and x <= 890 and y >= 440 and y <= 492 then self:ejecutar("cancelar_salir") end
    return
  end
  for _, b in ipairs(Vista.botones(self.motor)) do
    if b.activo and x >= b.x and x <= b.x + b.w and y >= b.y and y <= b.y + b.h then
      self:ejecutar(b.id); return
    end
  end
end
function Blackjack:update(dt)
  local motor = self.motor
  if not self.confirmar_salida then motor:update(dt) end
  for _, evento in ipairs(motor.eventos) do Audio.reproducir(evento) end
  motor.eventos = {}
  if motor.fase == "resultado" and self.partidas >= MAX_PARTIDAS then
    self.machine:switch(nil)
  end
end
function Blackjack:draw() Vista.dibujar(self.recursos, self.motor, self.confirmar_salida) end
function Blackjack:leave()
  love.mouse.setVisible(self.raton_visible)
  self.context, self.machine, self.motor, self.recursos, self.partidas, self.confirmar_salida = nil, nil, nil, nil, nil, nil
end
-- API sin gráficos para pruebas deterministas y reutilización de las reglas.
Blackjack.Reglas, Blackjack.Bot, Blackjack.Motor = Reglas, Bot, Motor
return Blackjack
