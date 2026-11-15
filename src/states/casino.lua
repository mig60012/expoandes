local Caminante = require("src/states/casino/caminante")
local Colision = require("src/states/casino/colision")
local Encuadre = require("src/states/casino/encuadre")
local Jornada = require("src/states/casino/jornada")
local Plano = require("src/states/casino/plano")
local VistaDialogo = require("src/states/casino/dialogue")
local Camara = require("lib/camera")
local Dialogue = require("src/systems/dialogue")
local CasinoStateMachine = require("src/states/casino/state_machine")
local Poker = require("src/states/casino/poker/poker")
local Blackjack = require("src/states/casino/blackjack/blackjack")
local Ruleta = require("src/states/casino/ruleta/ruleta")
local Characters = require("src/ui/characters")

local casino = {}

local TAMANO_LETRA = 18
local ALTURA_CAMARA = 70
local ALTURA_AVISO = 240
local CARPETA_FOTOS = "src/states/casino/assets/"
local MINIMOS = { ruleta = 1, blackjack = 2, poker = 3 }
local JUGADAS_POR_BLOQUE, CANSANCIO = 3, 0.08
local NOCHE = 2

local PISO = { 0.85, 0.85, 0.85 }
local FIGURA = { 0.8, 0.8, 0.8 }
local BORDE = { 0.2, 0.2, 0.2 }
local TEXTO = { 0.1, 0.1, 0.1 }
local PERSONAJE = { 0.3, 0.3, 0.3 }

local function rotulo(texto, x, y, ancho, color)
  love.graphics.setColor(color or TEXTO)
  love.graphics.printf(texto, x - ancho / 2, y - TAMANO_LETRA, ancho, "center")
end

local function figura(poligono, color, borde)
  love.graphics.setColor(color)
  for _, triangulo in ipairs(love.math.triangulate(poligono)) do
    love.graphics.polygon("fill", triangulo)
  end
  if borde then
    love.graphics.setColor(BORDE)
    love.graphics.setLineWidth(3)
    love.graphics.polygon("line", poligono)
  end
end

local function cargar_fotos(con_arte)
  local fotos = {}
  for _, objeto in ipairs(Plano.objetos) do
    local foto = con_arte and objeto.arte or objeto.foto
    if foto then
      local ok, imagen = pcall(love.graphics.newImage, foto.ruta or CARPETA_FOTOS .. foto.archivo .. ".png")
      if ok then
        fotos[objeto] = imagen
      end
    end
  end
  return fotos
end

local function dibujar_mesa(objeto, imagen, con_arte)
  local foto = con_arte and objeto.arte or objeto.foto
  love.graphics.setColor(1, 1, 1)
  love.graphics.draw(imagen, foto.x, foto.y, 0, foto.ancho / imagen:getWidth(), foto.alto / imagen:getHeight())
end

local function dibujar_mapa(fuente, fotos, arte)
  local lienzo = love.graphics.newCanvas(Plano.ancho, Plano.alto, { msaa = 4 })
  love.graphics.push("all")
  love.graphics.origin()
  love.graphics.setCanvas(lienzo)
  love.graphics.clear(PISO[1], PISO[2], PISO[3], 1)
  love.graphics.setFont(fuente)
  if arte then
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(arte, 0, 0, 0, Plano.ancho / arte:getWidth(), Plano.alto / arte:getHeight())
    love.graphics.pop()
    return lienzo
  end
  figura(Plano.suelo, PISO)
  for _, capa in ipairs(Plano.capas) do
    figura(capa.puntos, capa.color)
  end
  figura(Plano.puerta.marco, { 0.22, 0.22, 0.22 })
  for _, objeto in ipairs(Plano.objetos) do
    if not fotos[objeto] then
      figura(objeto.choque, FIGURA, true)
      rotulo(objeto.nombre, objeto.x, objeto.y, 240)
    end
  end
  love.graphics.pop()
  return lienzo
end

local function dibujar_jugador(jugador)
  local alto = Plano.jugador.alto
  love.graphics.setColor(BORDE)
  love.graphics.ellipse("fill", jugador.x, jugador.y, Plano.jugador.radio, Plano.jugador.radio / Plano.estiramiento)
  Characters.world(jugador.x - alto * 0.22, jugador.y - alto, alto, false)
end

local function dibujar_aviso(objeto, fuente)
  local texto = "Z  " .. objeto.etiqueta
  local ancho, alto = fuente:getWidth(texto) + 30, fuente:getHeight() + 14
  love.graphics.setColor(PERSONAJE)
  love.graphics.rectangle("fill", objeto.x - ancho / 2, objeto.y - ALTURA_AVISO - alto, ancho, alto)
  love.graphics.setColor(PISO)
  love.graphics.print(texto, objeto.x - ancho / 2 + 15, objeto.y - ALTURA_AVISO - alto + 7)
end

local function dibujar_marcador(fuente, dinero, jornada)
  local lineas = { "Dinero: " .. dinero .. " M", "Jugadas: " .. jornada.jugadas .. " de " .. jornada.maximo }
  local renglon = fuente:getHeight()
  local margen = renglon * 0.6
  local ancho = math.max(fuente:getWidth(lineas[1]), fuente:getWidth(lineas[2])) + margen * 2
  love.graphics.setFont(fuente)
  love.graphics.setColor(PERSONAJE)
  love.graphics.rectangle("fill", margen, margen, ancho, renglon * #lineas + margen * 2)
  love.graphics.setColor(PISO)
  for i, linea in ipairs(lineas) do
    love.graphics.print(linea, margen * 2, margen * 2 + renglon * (i - 1))
  end
end

function casino:encuadrar()
  local ancho, alto = love.graphics.getDimensions()
  -- Recortar y seguir al jugador, sin barras ni esquinas negras en ningun formato.
  local zoom = Encuadre.zoom(ancho, alto, Plano.vista.ancho, Plano.vista.alto)
  local x, y = Encuadre.centro(self.jugador.x, self.jugador.y - ALTURA_CAMARA,
    ancho, alto, zoom, Plano.ancho, Plano.alto)
  self.camara:zoomTo(zoom)
  self.camara:lookAt(x, y)
end

function casino:enter(context)
  self.context = context
  -- La historia conserva el capital inicial de main y las ganancias. Los
  -- estados aislados de pruebas mantienen el reinicio de saldo anterior.
  if not context.day_flow then context.economy:spend_money(context.economy:get_money()) end
  self.sub_estado = CasinoStateMachine.new({
    blackjack = Blackjack,
    poker = Poker,
    ruleta = Ruleta,
  })
  self.sub_estado:enter(context)
  self.fuente = love.graphics.newFont(TAMANO_LETRA)
  self.fuente_dialogo = love.graphics.newFont(math.max(16, math.floor(love.graphics.getHeight() * 0.032)))
  local ok, arte = pcall(love.graphics.newImage, Plano.arte.ruta)
  self.arte = ok and arte or nil
  self.fotos = cargar_fotos(self.arte ~= nil)
  self.mapa = dibujar_mapa(self.fuente, self.fotos, self.arte)
  self.interactuables = {}
  local poligonos = { Plano.suelo }
  for _, objeto in ipairs(Plano.objetos) do
    poligonos[#poligonos + 1] = objeto.choque
    if objeto.interaccion then
      self.interactuables[#self.interactuables + 1] = objeto
    end
  end
  self.jugador = Caminante.new({
    x = Plano.inicio.x,
    y = Plano.inicio.y,
    velocidad = Plano.jugador.velocidad,
    radio = Plano.jugador.radio,
    estiramiento = Plano.estiramiento,
    poligonos = poligonos,
  })
  self.camara = Camara(self.jugador.x, self.jugador.y, 1)
  local extra = context.progress:get_flag("casino_extra_games_accepted") == true
  self.jornada = Jornada.new({ maximo = JUGADAS_POR_BLOQUE * (extra and 2 or 1), cansancio = CANSANCIO })
  self.jornada.jugadas = context.progress:get_value("casino_games_today") or 0
  self.decision_tomada = context.progress:get_flag("casino_decision_made") == true
  self.limite_pendiente = self.jornada:completa() and not self.decision_tomada
  self.jugador.velocidad = Plano.jugador.velocidad * self.jornada:factor_velocidad()
  self.historial = {}
  self:encuadrar()
  self:anotar("entrar")
end

function casino:leave()
  if self.sub_estado then
    self.sub_estado:leave()
  end
  self.context, self.fuente, self.fuente_dialogo, self.mapa, self.jugador, self.camara = nil
  self.fotos, self.interactuables, self.cercano, self.dialogo, self.en_puerta, self.sub_estado = nil
  self.arte = nil
  self.jornada, self.historial = nil
  self.decision_tomada, self.limite_pendiente = nil, nil
end

function casino:anotar(...)
  self.historial[#self.historial + 1] = table.concat({ ... }, " ")
end

function casino:puede_salir()
  return self.jornada:completa() and self.decision_tomada and not self.limite_pendiente
end

function casino:abrir(nodo, al_terminar)
  local dialogo = Dialogue.new({ start = "inicio", nodes = { inicio = nodo } }, self.context)
  self.dialogo = VistaDialogo.new(dialogo, function(opcion)
    self.dialogo = nil
    if al_terminar then
      al_terminar(opcion)
    elseif opcion and opcion.salir and self:puede_salir() then
      local day_flow = self.context.day_flow
      if day_flow and day_flow:is_active() then
        local recorded, error_message = day_flow:record_games(self.jornada.jugadas)
        if not recorded then
          self:abrir({
            speaker = "Sistema",
            text = error_message,
            ending = true,
          })
          return
        end
      end
      self:anotar("salir")
      self.context.state_machine:switch("transicion")
    end
  end)
end

function casino:ofrecer_otro_bloque()
  self:abrir({ speaker = "Casino", text = "Ya jugaste 3 juegos. ¿Quieres jugar 3 más? Si aceptas, debes completarlos antes de salir.",
    choices = { { text = "Sí, jugar 3 más", continuar = true }, { text = "No, terminar por hoy" } },
  }, function(opcion)
    self.decision_tomada = true
    self.context.progress:set_flag("casino_decision_made", true)
    self.context.progress:set_flag("casino_extra_games_accepted", opcion and opcion.continuar == true or false)
    if opcion and opcion.continuar then
      self.jornada.maximo = JUGADAS_POR_BLOQUE * 2
      self.context.time_of_day = NOCHE
      self:anotar("continuar")
    else
      if self.context.story then self.context.time_of_day = 1 end
      self:anotar("terminar")
    end
    -- Permite volver a usar la puerta aunque la decision ocurra dentro de su zona.
    self.en_puerta = false
  end)
end

function casino:revisar_limite()
  if not self.limite_pendiente or self.dialogo then return end
  local mesa = self.sub_estado.current
  -- La ruleta cuenta al apostar: hay que esperar al resultado y al pago.
  if mesa and mesa.listo_para_salir and not mesa:listo_para_salir() then return end
  -- Blackjack ya muestra su aviso de fin; al limite ofrece solo volver al
  -- salon. La decision de otras tres jugadas se abre despues de esa salida.
  if mesa and mesa.gestiona_limite then return end
  if mesa then
    self:abrir({ speaker = "Casino", text = "Completaste " .. self.jornada.jugadas .. " juegos. Debes volver al salón.",
      choices = { { text = "Volver al salón" } },
    }, function()
      self.sub_estado:switch(nil)
      self.limite_pendiente = false
      if not self.decision_tomada then self:ofrecer_otro_bloque() end
    end)
  else
    self.limite_pendiente = false
    if not self.decision_tomada then self:ofrecer_otro_bloque() end
  end
end

function casino:jugada(mesa, monto)
  if self.jornada:completa() then return end
  self:anotar("apuesta", mesa, monto)
  self.jornada:registrar_jugada()
  self.context.progress:set_value("casino_games_today", self.jornada.jugadas)
  self.jugador.velocidad = Plano.jugador.velocidad * self.jornada:factor_velocidad()
  if self.jornada:completa() then self.limite_pendiente = true end
end

function casino:sentarse(mesa)
  if self.jornada:completa() then
    self:anotar("mesa_cerrada", mesa.interaccion)
    self:abrir({ speaker = mesa.etiqueta, text = "Ya no quedan jugadas por hoy.", ending = true })
    return
  end
  local minimo, dinero = MINIMOS[mesa.interaccion], self.context.economy:get_money()
  if dinero < minimo then
    self:anotar("rechazo", mesa.interaccion)
    self:abrir({ speaker = mesa.etiqueta, text = "El mínimo de esta mesa es " .. minimo .. " M y tienes " .. dinero .. " M.", ending = true })
    return
  end
  self:anotar("sentarse", mesa.interaccion)
  self.sub_estado:switch(mesa.interaccion, {
    minimo = minimo,
    puede_jugar = function()
      return not self.jornada:completa()
    end,
    al_jugar = function(monto)
      self:jugada(mesa.interaccion, monto)
    end,
  })
end

function casino:keypressed(tecla, scancode, isrepeat)
  self:revisar_limite()
  if self.dialogo then
    self.dialogo:keypressed(tecla)
    return
  end
  if self.sub_estado.current then
    self.sub_estado:keypressed(tecla, scancode, isrepeat)
    self:revisar_limite()
    return
  end
  if self.cercano and (tecla == "z" or tecla == "return") then
    self:sentarse(self.cercano)
  end
end

function casino:update(dt)
  self:revisar_limite()
  if self.dialogo then return end
  if self.sub_estado.current then
    self.sub_estado:update(dt)
    self:revisar_limite()
    return
  end
  if not self.dialogo then
    local tecla = love.keyboard.isDown
    local dx = (tecla("right", "d") and 1 or 0) - (tecla("left", "a") and 1 or 0)
    local dy = (tecla("down", "s") and 1 or 0) - (tecla("up", "w") and 1 or 0)
    self.jugador:mover(dx, dy, dt)
    self.cercano = self.jugador:mas_cercano(self.interactuables, Plano.jugador.alcance)
    local en_puerta = Colision.dentro(self.jugador.x, self.jugador.y, Plano.puerta.zona)
    if en_puerta and not self.en_puerta then
      if self:puede_salir() then
        self:abrir({ speaker = "Puerta", text = "¿Quieres salir del casino?", choices = { { text = "Sí", salir = true }, { text = "No" } } })
      else
        self:abrir({ speaker = "Puerta", text = "Debes completar " .. (self.jornada.maximo - self.jornada.jugadas) .. " juegos más antes de salir.", ending = true })
      end
    end
    self.en_puerta = en_puerta
  end
  self:encuadrar()
end

function casino:draw()
  if self.sub_estado.current then
    self.sub_estado:draw()
    if self.dialogo then
      local ancho, alto = love.graphics.getDimensions()
      self.dialogo:draw(ancho, alto, self.fuente_dialogo)
    end
    return
  end
  self:encuadrar()
  love.graphics.push("all")
  self.camara:attach()
  love.graphics.setFont(self.fuente)
  love.graphics.setColor(1, 1, 1)
  love.graphics.draw(self.mapa)
  for objeto, imagen in pairs(self.fotos) do
    if not self.jugador:detras_de(objeto) then
      dibujar_mesa(objeto, imagen, self.arte ~= nil)
    end
  end
  dibujar_jugador(self.jugador)
  for objeto, imagen in pairs(self.fotos) do
    if self.jugador:detras_de(objeto) then
      dibujar_mesa(objeto, imagen, self.arte ~= nil)
    end
  end
  if self.cercano and not self.dialogo then
    dibujar_aviso(self.cercano, self.fuente)
  end
  self.camara:detach()
  local ancho, alto = love.graphics.getDimensions()
  dibujar_marcador(self.fuente_dialogo, self.context.economy:get_money(), self.jornada)
  if self.dialogo then
    self.dialogo:draw(ancho, alto, self.fuente_dialogo)
  end
  love.graphics.pop()
end

function casino:keyreleased(tecla, scancode)
  if self.sub_estado.current and not self.dialogo then
    self.sub_estado:keyreleased(tecla, scancode)
  end
end

function casino:mousepressed(x, y, button, istouch, presses)
  self:revisar_limite()
  if self.dialogo then return end
  if self.sub_estado.current then
    self.sub_estado:mousepressed(x, y, button, istouch, presses)
    self:revisar_limite()
  end
end

return casino
