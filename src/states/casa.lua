--[[
-- Estado CASA
-- Funciona como un menu: la casa es solo un fondo y el "personaje" es el mouse.
-- Hay objetos (hotspots) que al pasar el mouse por encima se resaltan y al hacer
-- click ejecutan una accion.
--
-- RESOLUCION VIRTUAL
-- Todo el estado se disena en un espacio fijo de 1280x720 (16:9). Al dibujar, ese
-- espacio se escala para llenar la ventana (sea 800x600, 1920x1080, pantalla
-- completa, etc.) manteniendo la proporcion. Asi las posiciones y tamanos de los
-- objetos siempre estan en proporcion, sin importar el tamano de la ventana.
--
-- Capas de interaccion (la de arriba bloquea a las de abajo):
--   1. cinematica  (pantalla negra con texto, click para avanzar)
--   2. dialogo     (cuadro de texto, click para cerrar)
--   3. panel       (infraestructura legada; el celular ya no tiene hotspot)
--   4. objetos     (puerta, foto y maletin)
--
-- Guardar como: src/states/casa.lua
--]]

local Casa = {}
Casa.usa_cursor = true
local DialogueView = require("src/states/casa/dialogue")
local Mando = require("src/systems/mando")

-- Tamano del espacio virtual en el que se disena todo
local VW, VH = 1280, 720

-- Altura (en coordenadas virtuales) donde termina la pared y empieza el piso
local PISO_Y = 504

-- Colores del placeholder del fondo
local COLOR_PARED = { 0.85, 0.80, 0.70 }
local COLOR_PISO = { 0.45, 0.30, 0.20 }

-- ============================================================
-- SPRITES
-- Aqui estan indicados todos los sprites que necesita este estado.
-- Mientras el archivo no exista, se dibuja un rectangulo de color como reemplazo.
-- Cuando tengas la imagen, solo ponla en la ruta indicada.
-- ============================================================
local RUTAS_SPRITES = {
  fondo   = "assets/casa/fondo.png",  -- 1920x1080 (16:9), la casa completa (de dia)
  fondo_noche = "assets/casa/fondo_noche.png",
  cursor  = "assets/casa/cursor.png", -- el "personaje" (reemplaza al mouse)
  -- La puerta, el maletin y la foto de la hija YA ESTAN DIBUJADOS en el fondo,
  -- por eso no tienen sprite propio: solo son zonas clickeables invisibles.
}

local function cargar_sprite(ruta)
  if love.filesystem.getInfo(ruta) then
    return love.graphics.newImage(ruta)
  end
  return nil -- todavia no hay imagen: se usa el placeholder
end

-- ============================================================
-- UTILIDADES
-- ============================================================
local function punto_en_rect(px, py, r)
  return px >= r.x and px <= r.x + r.w and py >= r.y and py <= r.y + r.h
end

local function dia_actual(context)
  local day_flow = context.day_flow
  if day_flow and day_flow.get_day then return day_flow:get_day() end
  if context.progress then return context.progress:get_value("current_day") end
  return context.time_of_day
end

local function tiene_poco_dinero(context)
  return context.economy ~= nil and context.economy:get_money() <= 4
end

local function maletin_disponible(casa, today)
  local day_flow = casa.context.day_flow
  return tiene_poco_dinero(casa.context)
    and casa.dia_trabajado ~= today
    and not (day_flow and day_flow.decisions and day_flow.decisions.worked)
end

local function texto_hover(context, objeto)
  local dinero = context.economy and context.economy:get_money()
  if objeto.id == "puerta" then
    if dinero == 0 then
      return "No tienes dinero, ve a trabajar (haz clic en el maletín)"
    end
    return "Puedes ir al casino o ir a trabajar (haz clic en el maletín)"
  elseif objeto.id == "maletin" and dinero ~= nil and dinero <= 4 then
    return "Tienes poco dinero, trabaja para ganar más"
  end
  return objeto.nombre
end

-- ============================================================
-- ESCALA (resolucion virtual -> ventana real)
-- Solo recalcula cuando cambia el tamano de la ventana, no en cada frame.
-- ============================================================
function Casa:ajustar_escala()
  local w, h = love.graphics.getDimensions()
  if w == self.win_w and h == self.win_h then return end

  self.win_w, self.win_h = w, h

  -- Escala uniforme: el espacio virtual cabe completo en la ventana
  local s = math.min(w / VW, h / VH)
  self.escala = s

  -- Desplazamiento para centrar (solo hay barras si la ventana no es 16:9)
  self.off_x = (w - VW * s) / 2
  self.off_y = (h - VH * s) / 2

  -- Fuentes rasterizadas a la resolucion real (el 3er parametro es el dpiscale),
  -- asi el texto se ve nitido aunque se escale
  self.fuente_chica = love.graphics.newFont(12, "normal", s)
  self.fuente = love.graphics.newFont(18, "normal", s)
  self.fuente_titulo = love.graphics.newFont(26, "normal", s)
end

-- Convierte una posicion en pixeles de la ventana a coordenadas virtuales
function Casa:a_virtual(px, py)
  return (px - self.off_x) / self.escala, (py - self.off_y) / self.escala
end

-- Dibuja un rectangulo que cubre TODA la ventana (incluidas las barras, si las hay).
-- Se usa dentro de la transformacion virtual, por eso las coordenadas se convierten.
function Casa:cubrir_ventana()
  love.graphics.rectangle("fill",
    -self.off_x / self.escala, -self.off_y / self.escala,
    self.win_w / self.escala, self.win_h / self.escala)
end

-- ============================================================
-- ENTER / LEAVE
-- ============================================================
function Casa:enter(context)
  self.context = context

  if context.story and context.rules then
    context.rules.work_income = 3
  end

  local day_flow = context.day_flow
  local today = dia_actual(context)
  if day_flow and day_flow.decisions and day_flow.decisions.worked then
    self.dia_trabajado = today
  end

  -- El mouse del sistema se oculta: ahora el mouse ES el personaje
  love.mouse.setVisible(false)
  love.mouse.setGrabbed(true) -- opcional: evita que el mouse salga de la ventana

  -- Forzar el calculo de escala y fuentes
  self.win_w, self.win_h = nil, nil
  self:ajustar_escala()

  -- Cargar sprites (los que no existan quedan en nil)
  self.sprites = {}
  for nombre, ruta in pairs(RUTAS_SPRITES) do
    self.sprites[nombre] = cargar_sprite(ruta)
  end
  if context.time_of_day and context.time_of_day >= 2 then
    self.sprites.fondo = self.sprites.fondo_noche or self.sprites.fondo
  end

  -- Posicion del "personaje" (el mouse), en coordenadas virtuales
  self.mx, self.my = self:a_virtual(love.mouse.getPosition())

  -- Estado de las capas de interaccion
  self.hover = nil      -- objeto bajo el mouse
  self.dialogue = nil   -- diálogo narrativo abierto
  self.dialogue_error = nil
  self.panel = nil      -- pestana abierta (celular)
  self.hover_item = nil -- opcion de la pestana bajo el mouse
  self.cinematica = nil -- cinematica activa

  -- ----------------------------------------------------------
  -- OBJETOS INTERACTIVOS (coordenadas virtuales, espacio de 1280x720)
  -- x, y, w, h : zona clickeable (y donde se dibuja el sprite)
  -- sprite     : llave dentro de RUTAS_SPRITES
  -- color      : color del placeholder mientras no haya imagen
  -- en_fondo   : true si el objeto ya esta dibujado en el fondo (solo zona clickeable)
  -- accion     : funcion que se ejecuta al hacer click
  -- ----------------------------------------------------------
  self.objetos = {
    {
      -- Foto de la hija: el cuadro inclinado sobre la mesita, al lado de la cama.
      -- Va PRIMERO en la lista porque su zona se solapa un poco con la de la puerta
      -- (el cuadro esta enfrente de ella) y asi gana el click.
      id = "foto_hija",
      nombre = "Foto de tu hija",
      en_fondo = true, -- ya esta dibujada en el fondo: no se dibuja placeholder
      x = 627,
      y = 288,
      w = 146,
      h = 209,
      color = { 0.90, 0.75, 0.80 }, -- solo se usa si falta el fondo
      accion = function(casa)
        if casa.context.story then casa.context.story:inspect_photo(casa)
        else casa:iniciar_dialogo_hija() end
      end,
    },
    {
      -- Puerta: al fondo, en el centro-derecha de la pared
      id = "puerta",
      nombre = "Puerta (ir al casino)",
      en_fondo = true,
      x = 693,
      y = 83,
      w = 206,
      h = 354,
      color = { 0.50, 0.30, 0.15 },
      accion = function(casa)
        -- Cambia de estado: sale de la casa y va al casino
        casa.context.state_machine:switch("transicion", true)
      end,
    },
    {
      -- Maletin: a la izquierda, colgado/apoyado contra la pared
      id = "maletin",
      activo = maletin_disponible(self, today),
      nombre = "Maletin (ir al trabajo)",
      en_fondo = true,
      x = 0,
      y = 95,
      w = 137,
      h = 315,
      color = { 0.25, 0.20, 0.15 },
      accion = function(casa)
        if tiene_poco_dinero(casa.context) then casa:ir_al_trabajo() end
      end,
    },
  }

  if context.story then
    context.story:enter_house(self)
    return
  end
  local day_flow = self.context.day_flow
  if day_flow and day_flow:is_active() then
    local current_day = self.context.progress:get_value("current_day")
    local games = self.context.progress:get_value("casino_games_today")
    if current_day == 2 and games == 0 then
      self:iniciar_dialogo_dia2()
    elseif current_day == 3 and games == 0 then
      self:iniciar_dialogo_dia3()
    elseif current_day == 4 and games == 0 then
      self:iniciar_dialogo_dia4()
    elseif current_day == 3 and (games == 3 or games == 6) then
      self:iniciar_decision_carro()
    elseif current_day == 4 and (games == 3 or games == 6) then
      self:iniciar_dialogo_noche_dia4()
    elseif current_day == 5 and not day_flow.decisions.morning_complete then
      self:iniciar_dialogo_dia5()
    elseif current_day == 5 and not self.context.progress:get_outcome("N5") then
      self:iniciar_decision_economica()
    elseif games == 3 then
      self:iniciar_decision_regreso()
    end
  end
end

function Casa:leave()
  -- Devolver el mouse normal al salir de la casa
  love.mouse.setVisible(true)
  love.mouse.setGrabbed(false)
end

function Casa:ir_al_trabajo()
  local today = dia_actual(self.context)
  local day_flow = self.context.day_flow
  if self.dia_trabajado == today
      or (day_flow and day_flow.decisions and day_flow.decisions.worked) then
    return false
  end

  if self.context.story and day_flow and day_flow:is_active() then
    local day = day_flow:get_day()
    if (day == 1 or day == 2 or day == 3) and not day_flow.decisions.games then
      day_flow:record_games(3)
    end
    if day == 3 and type(day_flow.decisions.car_sold) ~= "boolean" then
      day_flow.decisions.car_sold = false
      day_flow.decisions.wife_knows_about_car = false
      self.context.progress:set_flag("car_sold", false)
    end
    self.context.rules.work_income = 0
  end

  self.dia_trabajado = today
  self.context.economy:add_money(3)
  self.context.state_machine:switch("trabajo")
  return true
end

-- ============================================================
-- DIALOGO
-- ============================================================
function Casa:iniciar_dialogo_hija()
  self.dialogue = DialogueView.new(self.context, "day_1.lua", function()
    self.dialogue = nil
  end)
end

function Casa:iniciar_decision_regreso()
  self.dialogue = DialogueView.new(self.context, "day_1_return.lua", function(view, choice)
    self.dialogue = nil
    if choice and choice.action == "work" then
      self:ir_al_trabajo()
    elseif choice and choice.action == "family" then
      local finished = self.context.day_flow:record_return_home()
      if finished then
        self.context.day_flow:advance_after_finished_day()
        self.context.time_of_day = 0
        self.context.state_machine:switch("casa")
      end
    end
  end)
end

function Casa:iniciar_dialogo_dia2()
  self.dialogue = DialogueView.new(self.context, "day_2.lua", function()
    self.dialogue = nil
  end)
end

function Casa:iniciar_dialogo_dia3()
  self.dialogue = DialogueView.new(self.context, "day_3.lua", function()
    self.dialogue = nil
  end)
end

function Casa:iniciar_dialogo_dia4()
  self.dialogue = DialogueView.new(self.context, "day_4.lua", function()
    self.dialogue = nil
  end)
end

function Casa:iniciar_dialogo_noche_dia4()
  self.dialogue = DialogueView.new(self.context, "day_4_night.lua", function()
    self.dialogue = nil
    local flow = self.context.day_flow
    local finished = flow:finish_day()
    if finished then
      flow:advance_after_finished_day()
      self.context.time_of_day = 0
      self.context.state_machine:switch("casa")
    end
  end)
end

function Casa:iniciar_dialogo_dia5()
  self.dialogue = DialogueView.new(self.context, "day_5.lua", function(view, choice)
    self.dialogue = nil
    local flow = self.context.day_flow
    flow:mark_morning_complete()
    if choice and choice.action == "work" then
      self:ir_al_trabajo()
    elseif choice and choice.action == "casino" then
      self.context.state_machine:switch("transicion", true)
    end
  end)
end

function Casa:iniciar_decision_economica()
  self.dialogue = DialogueView.new(self.context, "day_5_economic.lua", function(view, choice)
    self.dialogue = nil
    if not choice or not choice.action then return end
    local flow = self.context.day_flow
    local ok, error_message = flow:record_economic_decision(choice.action)
    if not ok then
      self.dialogue_error = error_message
      return
    end
    local finished = flow:finish_day()
    if finished then
      self.context.state_machine:switch("finales")
    end
  end)
end

function Casa:iniciar_decision_carro()
  self.dialogue = DialogueView.new(self.context, "day_3_return.lua", function(view, choice)
    self.dialogue = nil
    if not choice or not choice.action then return end

    local day_flow = self.context.day_flow
    local recorded, error_message = day_flow:record_car_decision(choice.action)
    if not recorded then
      self.dialogue_error = error_message
      return
    end

    local finished = day_flow:finish_day()
    if finished then
      day_flow:advance_after_finished_day()
      self.context.time_of_day = 0
      self.context.state_machine:switch("casa")
    end
  end)
end

function Casa:cerrar_dialogo()
  self.dialogue = nil
end

-- ============================================================
-- CINEMATICA DEL TRABAJO
-- Pantalla negra con paginas de texto. Click para avanzar; al terminar, vuelve a la casa.
-- ============================================================
function Casa:iniciar_cinematica_trabajo()
  self.cinematica = {
    indice = 1,
    paginas = {
      "Tomas tu maletin y te vas al trabajo.",
      "Pasas todo el dia trabajando.",
      "Regresas a casa, agotado.",
    },
  }
end

function Casa:avanzar_cinematica()
  local c = self.cinematica
  c.indice = c.indice + 1
  if c.indice > #c.paginas then
    self.cinematica = nil -- termino: vuelve a la casa
  end
end

-- ============================================================
-- PANEL DEL CELULAR (pestana con lista de opciones)
-- ============================================================
function Casa:abrir_celular()
  local pw, ph = 520, 340
  local px, py = (VW - pw) / 2, (VH - ph) / 2

  -- Opciones de la lista. Cada una es clickeable.
  -- Por ahora solo muestran un aviso dentro de la pestana.
  local opciones = {
    {
      texto = "Vender carro",
      accion = function(casa)
        casa.panel.mensaje = "Vender carro: pendiente por implementar."
      end,
    },
    {
      texto = "Vender casa",
      accion = function(casa)
        casa.panel.mensaje = "Vender casa: pendiente por implementar."
      end,
    },
  }

  -- Calcular el rectangulo de cada opcion (para dibujar y para detectar el click)
  for i, op in ipairs(opciones) do
    op.x = px + 24
    op.y = py + 84 + (i - 1) * 72
    op.w = pw - 48
    op.h = 56
  end

  self.panel = {
    titulo = "Celular",
    x = px,
    y = py,
    w = pw,
    h = ph,
    cerrar = { x = px + pw - 42, y = py + 12, w = 30, h = 30 }, -- boton X
    items = opciones,
    mensaje = nil,
  }
end

function Casa:cerrar_panel()
  self.panel = nil
  self.hover_item = nil
end

-- ============================================================
-- UPDATE
-- ============================================================
function Casa:update(dt)
  -- Si la ventana cambio de tamano, se recalcula la escala
  self:ajustar_escala()

  -- El "personaje" es simplemente la posicion del mouse (en coordenadas virtuales)
  self.mx, self.my = self:a_virtual(love.mouse.getPosition())

  self.hover = nil
  self.hover_item = nil

  local today = dia_actual(self.context)
  for _, obj in ipairs(self.objetos or {}) do
    if obj.id == "maletin" then
      obj.activo = maletin_disponible(self, today)
    end
  end

  -- Con una cinematica o un dialogo abierto no se detecta nada mas
  if self.cinematica or self.dialogue then
    if self.dialogue then self.dialogue:update(dt) end
    return
  end

  -- Pestana del celular: detectar la opcion bajo el mouse
  if self.panel then
    for _, item in ipairs(self.panel.items) do
      if punto_en_rect(self.mx, self.my, item) then
        self.hover_item = item
        break
      end
    end
    return
  end

  -- Detectar sobre que objeto de la casa esta el mouse
  for _, obj in ipairs(self.objetos) do
    if obj.activo ~= false and punto_en_rect(self.mx, self.my, obj) then
      self.hover = obj
      break
    end
  end
end

-- ============================================================
-- DRAW
-- ============================================================
function Casa:draw()
  local s = self.escala

  -- 0) Fondo de la ventana completa (cubre tambien las barras si la ventana no es 16:9)
  if self.sprites.fondo then
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("fill", 0, 0, self.win_w, self.win_h)
  else
    love.graphics.setColor(COLOR_PARED)
    love.graphics.rectangle("fill", 0, 0, self.win_w, self.win_h)
    love.graphics.setColor(COLOR_PISO)
    local piso_px = self.off_y + PISO_Y * s
    love.graphics.rectangle("fill", 0, piso_px, self.win_w, self.win_h - piso_px)
  end

  -- A partir de aqui todo se dibuja en coordenadas virtuales (1280x720)
  love.graphics.push()
  love.graphics.translate(self.off_x, self.off_y)
  love.graphics.scale(s, s)

  -- 1) Sprite de fondo (si existe)
  if self.sprites.fondo then
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(self.sprites.fondo, 0, 0, 0,
      VW / self.sprites.fondo:getWidth(),
      VH / self.sprites.fondo:getHeight())
  end

  -- 2) Objetos
  for _, obj in ipairs(self.objetos) do
    local sprite = obj.sprite and self.sprites[obj.sprite]
    if obj.en_fondo and self.sprites.fondo then
      -- Ya esta en la imagen de fondo: no se dibuja nada encima
    elseif sprite then
      love.graphics.setColor(1, 1, 1)
      love.graphics.draw(sprite, obj.x, obj.y, 0,
        obj.w / sprite:getWidth(), obj.h / sprite:getHeight())
    else
      -- Placeholder: rectangulo de color con el nombre
      love.graphics.setColor(obj.color)
      love.graphics.rectangle("fill", obj.x, obj.y, obj.w, obj.h)
      love.graphics.setColor(1, 1, 1)
      love.graphics.setFont(self.fuente_chica)
      love.graphics.printf(obj.id, obj.x, obj.y + obj.h / 2 - self.fuente_chica:getHeight() / 2,
        obj.w, "center")
    end
  end

  -- 3) Resaltado y etiqueta del objeto bajo el mouse
  if self.hover then
    local h = self.hover
    local label = texto_hover(self.context, h)
    love.graphics.setColor(1, 1, 0.2)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", h.x, h.y, h.w, h.h)
    love.graphics.setLineWidth(1)

    love.graphics.setFont(self.fuente)
    local tw = self.fuente:getWidth(label) + 16
    local th = self.fuente:getHeight() + 8

    -- Posicion por defecto: abajo a la derecha del cursor
    local tx = self.mx + 18
    local ty = self.my + 18

    -- Si se sale por la derecha, se pone a la izquierda del cursor
    if tx + tw > VW then tx = self.mx - tw - 8 end
    -- Si se sale por abajo, se pone arriba del cursor
    if ty + th > VH then ty = self.my - th - 8 end

    -- Seguro final: nunca fuera de los bordes
    tx = math.max(0, math.min(tx, VW - tw))
    ty = math.max(0, math.min(ty, VH - th))

    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", tx, ty, tw, th, 4, 4)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(label, tx + 8, ty + 4)
  end

  -- 4) Panel del celular
  if self.panel then
    local p = self.panel

    love.graphics.setColor(0, 0, 0, 0.5)
    self:cubrir_ventana()

    -- Caja
    love.graphics.setColor(0.12, 0.12, 0.18)
    love.graphics.rectangle("fill", p.x, p.y, p.w, p.h, 12, 12)
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("line", p.x, p.y, p.w, p.h, 12, 12)

    -- Titulo
    love.graphics.setFont(self.fuente_titulo)
    love.graphics.print(p.titulo, p.x + 24, p.y + 18)

    -- Boton cerrar (X)
    local c = p.cerrar
    local sobre_cerrar = punto_en_rect(self.mx, self.my, c)
    love.graphics.setColor(sobre_cerrar and { 0.9, 0.3, 0.3 } or { 0.6, 0.2, 0.2 })
    love.graphics.rectangle("fill", c.x, c.y, c.w, c.h, 4, 4)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.fuente)
    love.graphics.printf("X", c.x, c.y + (c.h - self.fuente:getHeight()) / 2, c.w, "center")

    -- Opciones de la lista
    for _, item in ipairs(p.items) do
      if item == self.hover_item then
        love.graphics.setColor(0.35, 0.35, 0.55)
      else
        love.graphics.setColor(0.22, 0.22, 0.32)
      end
      love.graphics.rectangle("fill", item.x, item.y, item.w, item.h, 6, 6)

      if item == self.hover_item then
        love.graphics.setColor(1, 1, 0.2)
        love.graphics.rectangle("line", item.x, item.y, item.w, item.h, 6, 6)
      end

      love.graphics.setColor(1, 1, 1)
      love.graphics.setFont(self.fuente)
      love.graphics.print(item.texto, item.x + 16, item.y + (item.h - self.fuente:getHeight()) / 2)
    end

    -- Mensaje de estado (ej. "pendiente por implementar")
    if p.mensaje then
      love.graphics.setColor(1, 0.85, 0.4)
      love.graphics.setFont(self.fuente)
      love.graphics.printf(p.mensaje, p.x + 24, p.y + p.h - 56, p.w - 48, "left")
    end
  end

  -- 5) Diálogo narrativo
  if self.dialogue then
    self.dialogue:draw(VW, VH)
  end
  if self.dialogue_error then
    love.graphics.setColor(1, 0.3, 0.3)
    love.graphics.print(self.dialogue_error, 30, VH - 40)
    love.graphics.setColor(1, 1, 1)
  end

  -- 6) Cinematica (cubre toda la ventana)
  if self.cinematica then
    local c = self.cinematica
    love.graphics.setColor(0, 0, 0)
    self:cubrir_ventana()

    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.fuente_titulo)
    love.graphics.printf(c.paginas[c.indice], 100, VH / 2 - 40, VW - 200, "center")

    love.graphics.setColor(0.6, 0.6, 0.6)
    love.graphics.setFont(self.fuente)
    local pista = Mando.boton("aceptar") .. " · Continuar"
    love.graphics.printf(pista, 0, VH - 60, VW, "center")
  end

  -- 7) El "personaje": el cursor (siempre al final, encima de todo)
  if self.sprites.cursor then
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(self.sprites.cursor, self.mx, self.my)
  else
    -- Placeholder: flechita simple
    love.graphics.setColor(1, 1, 1)
    love.graphics.polygon("fill",
      self.mx, self.my,
      self.mx, self.my + 24,
      self.mx + 7, self.my + 19,
      self.mx + 16, self.my + 16)
    love.graphics.setColor(0, 0, 0)
    love.graphics.polygon("line",
      self.mx, self.my,
      self.mx, self.my + 24,
      self.mx + 7, self.my + 19,
      self.mx + 16, self.my + 16)
  end

  love.graphics.pop()
  love.graphics.setColor(1, 1, 1)
end

-- ============================================================
-- INPUT
-- ============================================================
function Casa:mousepressed(px, py, button)
  if button ~= 1 then return end -- solo click izquierdo

  -- El click llega en pixeles de la ventana: se pasa a coordenadas virtuales
  local x, y = self:a_virtual(px, py)

  -- Capa 1: cinematica (click avanza)
  if self.cinematica then
    self:avanzar_cinematica()
    return
  end

  -- Capa 2: diálogo narrativo
  if self.dialogue then
    self.dialogue:mousepressed(x, y, button)
    return
  end

  -- Capa 3: panel del celular
  if self.panel then
    if punto_en_rect(x, y, self.panel.cerrar) then
      self:cerrar_panel()
    elseif self.hover_item then
      self.hover_item.accion(self, self.context)
    elseif not punto_en_rect(x, y, self.panel) then
      self:cerrar_panel() -- click fuera de la pestana la cierra
    end
    return
  end

  -- Capa 4: objetos de la casa
  if self.hover and self.hover.activo ~= false and self.hover.accion and punto_en_rect(x, y, self.hover) then
    self.hover.accion(self, self.context)
    return
  end

  -- También se acepta el clic directo aunque todavía no se haya ejecutado
  -- `update` (útil para entradas sintéticas y para el primer frame).
  for _, objeto in ipairs(self.objetos) do
    if objeto.activo ~= false and punto_en_rect(x, y, objeto) and objeto.accion then
      objeto.accion(self, self.context)
      return
    end
  end

  -- La etiqueta de entrada de la puerta también funciona como hotspot.
  if x >= 0 and x <= 220 and y >= 480 and y <= 560 then
    self.context.state_machine:switch("transicion", true)
  end
end

function Casa:keypressed(key, scancode, isrepeat)
  if self.dialogue then
    self.dialogue:keypressed(key, scancode, isrepeat)
    return
  end
  if self.cinematica and (key == "z" or key == "return" or key == "space") then
    self:avanzar_cinematica()
    return
  end
  if key == "escape" then
    if self.dialogue then
      self:cerrar_dialogo()
    elseif self.panel then
      self:cerrar_panel()
    end
  end
end

return Casa
