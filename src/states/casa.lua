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
--   3. panel       (pestana con una lista de opciones, ej. el celular)
--   4. objetos     (puerta, maletin, foto, celular)
--
-- Guardar como: src/states/casa.lua
--]]

local Casa = {}

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
  fondo       = "assets/casa/fondo.png",       -- 1280x720, la casa completa
  cursor      = "assets/casa/cursor.png",      -- el "personaje" (reemplaza al mouse)
  puerta      = "assets/casa/puerta.png",
  maletin     = "assets/casa/maletin.png",
  foto_hija   = "assets/casa/foto_hija.png",
  celular     = "assets/casa/celular.png",
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

  -- Posicion del "personaje" (el mouse), en coordenadas virtuales
  self.mx, self.my = self:a_virtual(love.mouse.getPosition())

  -- Estado de las capas de interaccion
  self.hover = nil        -- objeto bajo el mouse
  self.dialogo = nil      -- cuadro de texto abierto
  self.panel = nil        -- pestana abierta (celular)
  self.hover_item = nil   -- opcion de la pestana bajo el mouse
  self.cinematica = nil   -- cinematica activa

  -- ----------------------------------------------------------
  -- OBJETOS INTERACTIVOS (coordenadas virtuales, espacio de 1280x720)
  -- x, y, w, h : zona clickeable (y donde se dibuja el sprite)
  -- sprite     : llave dentro de RUTAS_SPRITES
  -- color      : color del placeholder mientras no haya imagen
  -- accion     : funcion que se ejecuta al hacer click
  -- ----------------------------------------------------------
  self.objetos = {
    {
      -- Puerta: a la derecha
      id = "puerta", nombre = "Puerta (ir a la transicion)", sprite = "puerta",
      x = 1090, y = 280, w = 130, h = 250,
      color = { 0.50, 0.30, 0.15 },
      accion = function(casa)
        -- Cambia de estado: sale de la casa y va a la transicion
        casa.context.state_machine:switch("transicion")
      end,
    },
    {
      -- Maletin: a la izquierda, mas abajo (en el piso)
      id = "maletin", nombre = "Maletin (ir al trabajo)", sprite = "maletin",
      x = 160, y = 576, w = 160, h = 84,
      color = { 0.25, 0.20, 0.15 },
      accion = function(casa)
        casa.context.state_machine:switch("trabajo")
      end,
    },
    {
      -- Foto de la hija: pequena, en el medio
      id = "foto_hija", nombre = "Foto de tu hija", sprite = "foto_hija",
      x = 608, y = 240, w = 64, h = 76,
      color = { 0.90, 0.75, 0.80 },
      accion = function(casa)
        casa:abrir_dialogo("Foto de tu hija", "Es por ella que haces todo esto.")
      end,
    },
    {
      -- Celular: esquina superior derecha
      id = "celular", nombre = "Celular", sprite = "celular",
      x = 1180, y = 28, w = 64, h = 100,
      color = { 0.20, 0.20, 0.25 },
      accion = function(casa)
        casa:abrir_celular()
      end,
    },
  }
end

function Casa:leave()
  -- Devolver el mouse normal al salir de la casa
  love.mouse.setVisible(true)
  love.mouse.setGrabbed(false)
end

-- ============================================================
-- DIALOGO
-- ============================================================
function Casa:abrir_dialogo(titulo, texto)
  self.dialogo = { titulo = titulo, texto = texto }
end

function Casa:cerrar_dialogo()
  self.dialogo = nil
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
    x = px, y = py, w = pw, h = ph,
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

  -- Con una cinematica o un dialogo abierto no se detecta nada mas
  if self.cinematica or self.dialogo then return end

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
    if punto_en_rect(self.mx, self.my, obj) then
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
    local sprite = self.sprites[obj.sprite]
    if sprite then
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
    love.graphics.setColor(1, 1, 0.2)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", h.x, h.y, h.w, h.h)
    love.graphics.setLineWidth(1)

    love.graphics.setFont(self.fuente)
    local tw = self.fuente:getWidth(h.nombre) + 16
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
    love.graphics.print(h.nombre, tx + 8, ty + 4)
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

  -- 5) Dialogo
  if self.dialogo then
    love.graphics.setColor(0, 0, 0, 0.5)
    self:cubrir_ventana()

    local bw, bh = 640, 200
    local bx, by = (VW - bw) / 2, (VH - bh) / 2
    love.graphics.setColor(0.15, 0.15, 0.2)
    love.graphics.rectangle("fill", bx, by, bw, bh, 10, 10)
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("line", bx, by, bw, bh, 10, 10)

    love.graphics.setFont(self.fuente_titulo)
    love.graphics.print(self.dialogo.titulo, bx + 24, by + 18)
    love.graphics.setFont(self.fuente)
    love.graphics.printf(self.dialogo.texto, bx + 24, by + 70, bw - 48, "left")
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.print("Click para cerrar", bx + 24, by + bh - 38)
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
    local pista = (c.indice < #c.paginas) and "Click para continuar" or "Click para volver a casa"
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

  -- Capa 2: dialogo (click cierra)
  if self.dialogo then
    self:cerrar_dialogo()
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
  if self.hover and self.hover.accion then
    self.hover.accion(self, self.context)
  end
end

function Casa:keypressed(key)
  if key == "escape" then
    if self.dialogo then
      self:cerrar_dialogo()
    elseif self.panel then
      self:cerrar_panel()
    end
  end
end

return Casa