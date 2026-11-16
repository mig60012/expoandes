local transicion = {}
local Characters = require("src/ui/characters")
local StoryView = require("src/ui/story_dialogue")
local Mando = require("src/systems/mando")
local Audio = require("src/systems/audio")
local filtro_add_tarde = love.graphics.newImage("assets/transicion/Filtro_add(tarde).PNG")
local filtro_add_siempre = love.graphics.newImage("assets/transicion/filtro_add_siempre.PNG")
local filtro_color_burn = love.graphics.newImage("assets/transicion/Filtro_color_burn.PNG")
local filtro_luces_add = love.graphics.newImage("assets/transicion/filtro_luces_add.PNG")
local manana_bg = love.graphics.newImage("assets/transicion/manana_tarde.PNG")
local noche_bg = love.graphics.newImage("assets/transicion/noche.PNG")
local filtro_overlay = love.graphics.newImage("assets/transicion/Filtro_overlay.PNG")
local player_pos = 0
local DialogueView = require("src/states/transicion/dialogue")
local light_flickering = false
local doors = {
  { x = 24, y = 388, w = 184, h = 342, state = "casa", label = "Entrar a casa" },
  { x = 8530, y = 298, w = 470, h = 427, state = "casino", label = "Entrar al casino" },
}
local function get_scene_layout(bg, w, h)
  local sw, sh = bg:getDimensions()
  local scale = h / sh
  local min_x = math.max(0, sw * scale - w)
  local x = math.min(0, math.max(-min_x, -player_pos * scale + w / 3))
  return x, scale
end

local function draw_scene(bg, w, h, context, facing)
  local x, scale = get_scene_layout(bg, w, h)
  love.graphics.draw(bg, x, 0, 0, scale, scale)

  Characters.world(x + player_pos * scale, h * 0.73, h / 6, Characters.has_car(context), facing)
end

local function door_label_rect(door, x, scale, w)
  local left, right = x + door.x * scale, x + (door.x + door.w) * scale
  if right < 0 or left > w then return nil end
  return math.max(8, math.min(w - 180, left)), (door.y + door.h) * scale + 8, 172, 32
end

local function create_shader()
  return love.graphics.newShader([[
    extern Image canvas_base;
    extern vec2 resolucion;
    extern float modo; // 0.0 = Add, 1.0 = Overlay, 2.0 = Color Burn

    vec4 effect(vec4 color, Image textura_filtro,
                vec2 coords_textura, vec2 coords_pantalla) {
      vec2 uv = coords_pantalla / resolucion;
      vec4 base = Texel(canvas_base, uv);
      vec4 blend = Texel(textura_filtro, coords_textura) * color;
      vec3 resultado;

      if (modo == 0.0) {
        resultado = min(base.rgb + blend.rgb, 1.0);
      } else if (modo == 1.0) {
        for (int i = 0; i < 3; i++) {
          if (base[i] < 0.5) {
            resultado[i] = 2.0 * base[i] * blend[i];
          } else {
            resultado[i] = 1.0 - 2.0 * (1.0 - base[i]) * (1.0 - blend[i]);
          }
        }
      } else {
        for (int i = 0; i < 3; i++) {
          if (blend[i] <= 0.00001) {
            resultado[i] = 0.0;
          } else {
            resultado[i] = max(1.0 - (1.0 - base[i]) / blend[i], 0.0);
          }
        }
      }

      // La composición ya está completa. El destino se escribe con replace.
      return vec4(mix(base.rgb, resultado, blend.a), base.a);
    }
  ]])
end

local function create_vignette_shader()
  return love.graphics.newShader([[
    extern vec2 resolucion;

    vec4 effect(vec4 color, Image textura,
                vec2 coords_textura, vec2 coords_pantalla) {
      vec2 uv = coords_pantalla / resolucion;
      vec2 original_uv = uv;

      // Misma fórmula base del ejemplo de Shadertoy.
      uv *= 1.0 - uv.yx;
      float vig = uv.x * uv.y * 15.0;
      vig = pow(vig, 0.5);

      vec4 escena = Texel(textura, original_uv) * color;
      return vec4(escena.rgb * vig, escena.a);
    }
  ]])
end

--[[local function vig_shader()
  primeroturn love.graphics.newShader([[
  vec4 effect(vec4 color, Image image, vec2 coords_textura, vec2 coords_pantalla) {
    vec2 uv = coords_pantalla / resolucion;

    uv *=  1.0 - uv.yx;   //vec2(1.0)- uv.yx; -> 1.-u.yx; Thanks FabriceNeyret !

    float vig = uv.x*uv.y * 15.0; // multiply with sth for intensity

    vig = pow(vig, .5); // change pow for modifying the extend of the  vignette


    return vig*Texel(image, coords_textura);
    }) TODO
end
]]

local function ensure_canvas(state, w, h)
  if not state.canvas_a
      or state.canvas_a:getWidth() ~= w
      or state.canvas_a:getHeight() ~= h then
    state.canvas_a = love.graphics.newCanvas(w, h)
    state.canvas_b = love.graphics.newCanvas(w, h)
  end
end

local function apply_filter(state, image, x, scale, mode, w, h)
  local src = state.current
  local dst = src == state.canvas_a and state.canvas_b or state.canvas_a

  -- Copiar primero la composición anterior para conservar las zonas
  -- transparentes de la textura del filtro.
  love.graphics.setCanvas(dst)
  love.graphics.clear(0, 0, 0, 0)
  love.graphics.setShader()
  love.graphics.setBlendMode("replace")
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(src, 0, 0)

  state.shader:send("canvas_base", src)
  state.shader:send("resolucion", { w, h })
  state.shader:send("modo", mode)
  love.graphics.setShader(state.shader)
  love.graphics.setBlendMode("replace")
  love.graphics.draw(image, x, 0, 0, scale, scale)

  love.graphics.setShader()
  love.graphics.setCanvas()
  love.graphics.setBlendMode("alpha")
  state.current = dst
end

local function apply_add_filter(state, image, x, scale)
  local src = state.current
  local dst = src == state.canvas_a and state.canvas_b or state.canvas_a

  -- Partimos de la composición acumulada y aplicamos la luz con el blending
  -- nativo de LÖVE, que es el modo indicado para estas capas.
  love.graphics.setCanvas(dst)
  love.graphics.clear(0, 0, 0, 0)
  love.graphics.setShader()
  love.graphics.setBlendMode("replace")
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(src, 0, 0)

  love.graphics.setBlendMode("add")
  love.graphics.draw(image, x, 0, 0, scale, scale)

  love.graphics.setBlendMode("alpha")
  love.graphics.setCanvas()
  state.current = dst
end

function transicion:enter(context, from_casa)
  self.context = context
  Audio.iniciar_bucle("calle_ambiente")
  self.paso_reloj = 0
  self.transition_error = nil
  local from_house = from_casa or context.state_machine.last == "casa"
  self.facing = from_house and 1 or -1
  if from_house then
    player_pos = 100
  elseif context.state_machine.last == "casa" then
    player_pos = doors[1].x
  else
    player_pos = 8550
  end
  local filename = "dialogo.lua"
  if from_casa and context.progress then
    local day = context.progress:get_value("current_day")
    if day == 2 then
      filename = "day_2_transition.lua"
    elseif day == 3 then
      filename = "day_3_transition.lua"
    elseif day == 4 then
      filename = "day_4_transition.lua"
    end
  end
  if context.story then
    self.dialogue = StoryView.new(context, context.story:street(from_house), nil, { portrait_mode = "transition" })
  else
    self.dialogue = DialogueView.new(context, filename)
  end
  self.shader = create_shader()
  self.vignette_shader = create_vignette_shader()
  --self.vignette_shader = vig_shader()
end

function transicion:update(dt)
  self.dialogue:update(dt)
  if self.dialogue:is_active() then return end
  local dir = 0
  local _, h = love.graphics.getDimensions()
  local speed = Characters.travel_speed(self.context, h)
  if love.keyboard.isDown("a") then
    dir = dir - speed * dt
  end
  if love.keyboard.isDown("d") then
    dir = dir + speed * dt
  end
  if dir ~= 0 then
    self.facing = dir < 0 and -1 or 1
    self.paso_reloj = self.paso_reloj - dt
    if self.paso_reloj <= 0 then
      Audio.reproducir("footstep_" .. love.math.random(1, 3))
      self.paso_reloj = 0.36
    end
  else
    self.paso_reloj = 0
  end
  player_pos = math.max(0, math.min(manana_bg:getWidth() - 50,
    player_pos + dir * (love.keyboard.isDown("h") and 20 or 1)))
  if not light_flickering then
    if love.math.random() > 0.99 then
      light_flickering = true
    end
  else
    if love.math.random() > 0.95 then
      light_flickering = false
    end
  end
  if player_pos < 60 then
    local day_flow = self.context.day_flow
    if day_flow and day_flow:is_active() then
      local games = self.context.progress:get_value("casino_games_today")
      local finished, error_message
      if games == 0 then
        -- La primera entrada al juego también llega desde esta transición,
        -- pero todavía no representa el regreso de una jornada.
        finished = true
      elseif games == 3 then
        -- La decisión entre trabajar y quedarse con la familia se presenta
        -- al llegar a casa.
        finished = true
      elseif games == 6 then
        -- El regreso nocturno se resuelve en casa para los días 4 y 5.
        finished = true
      else
        finished = false
        error_message = "La jornada requiere 3 o 6 partidas antes de volver a casa."
      end

      if not finished then
        self.transition_error = error_message
        return
      end
    end
    Audio.reproducir("door_open")
    self.context.state_machine:switch("casa")
  elseif player_pos > 8600 then
    Audio.reproducir("door_open")
    self.context.state_machine:switch("casino")
  end
end

function transicion:keypressed(key, scancode, isrepeat)
  self.dialogue:keypressed(key, scancode, isrepeat)
  if key == "c" and not self.dialogue:is_active() then
    self.context.state_machine:switch("casino")
  end
end

function transicion:door_at(px, py)
  if self.dialogue:is_active() then return nil end
  local w, h = love.graphics.getDimensions()
  local x, scale = get_scene_layout(manana_bg, w, h)
  local sx, sy = (px - x) / scale, py / scale
  for _, door in ipairs(doors) do
    local lx, ly, lw, lh = door_label_rect(door, x, scale, w)
    if sx >= door.x and sx <= door.x + door.w
        and sy >= door.y and sy <= door.y + door.h then
      return door
    end
    if lx and px >= lx and px <= lx + lw and py >= ly and py <= ly + lh then
      return door
    end
  end
end

function transicion:mousepressed(x, y, button)
  if button ~= 1 then return end
  if self.context.story and self.dialogue:is_active() then
    self.dialogue:mousepressed(x, y, button)
    return
  end
  local door = self:door_at(x, y)
  if door then
    Audio.reproducir("door_open")
    self.context.state_machine:switch(door.state)
  end
end

function transicion:draw()
  local w, h = love.graphics.getDimensions()
  local bg = self.context.time_of_day < 2 and manana_bg or noche_bg
  local x, scale = get_scene_layout(bg, w, h)
  ensure_canvas(self, w, h)

  love.graphics.push("all")
  love.graphics.setCanvas(self.canvas_a)
  love.graphics.clear(0, 0, 0, 0)
  love.graphics.setBlendMode("alpha")
  love.graphics.setShader()
  love.graphics.setColor(1, 1, 1, 1)
  draw_scene(bg, w, h, self.context, self.facing)
  love.graphics.setCanvas()
  self.current = self.canvas_a

  if self.context.time_of_day == 0 then
    apply_filter(self, filtro_color_burn, x, scale, 2.0, w, h)
    apply_add_filter(self, filtro_luces_add, x, scale)
    apply_add_filter(self, filtro_add_siempre, x, scale)
  elseif self.context.time_of_day == 1 then
    apply_add_filter(self, filtro_add_tarde, x, scale)
    apply_add_filter(self, filtro_add_siempre, x, scale)
  else
    if not light_flickering then apply_add_filter(self, filtro_luces_add, x, scale) end
    apply_filter(self, filtro_overlay, x, scale, 1.0, w, h)
    apply_filter(self, filtro_color_burn, x, scale, 2.0, w, h)
    apply_filter(self, filtro_overlay, x, scale, 1.0, w, h)
    if not light_flickering then apply_add_filter(self, filtro_luces_add, x, scale) end
    apply_add_filter(self, filtro_add_siempre, x, scale)
  end

  love.graphics.setCanvas()
  self.vignette_shader:send("resolucion", { w, h })
  love.graphics.setShader(self.vignette_shader)
  love.graphics.setBlendMode("replace")
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(self.current, 0, 0)
  love.graphics.setShader()
  love.graphics.setBlendMode("alpha")
  love.graphics.pop()
  self.dialogue:draw()
  if not self.dialogue:is_active() then
    self.fuente_ayuda = self.fuente_ayuda or love.graphics.newFont(math.max(16, math.floor(h * 0.028)))
    local texto = Mando.boton("correr") .. " · " .. (Characters.has_car(self.context) and "Acelerar" or "Correr")
    local ancho, alto = self.fuente_ayuda:getWidth(texto) + 32, self.fuente_ayuda:getHeight() + 14
    love.graphics.setColor(0, 0, 0, 0.55)
    love.graphics.rectangle("fill", (w - ancho) / 2, h - alto - 24, ancho, alto, 8)
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.setFont(self.fuente_ayuda)
    love.graphics.printf(texto, 0, h - alto - 17, w, "center")
    love.graphics.setColor(1, 1, 1, 1)
  end
  if self.transition_error then
    love.graphics.setColor(1, 0.35, 0.35, 1)
    love.graphics.print(self.transition_error, 20, h - 30)
    love.graphics.setColor(1, 1, 1, 1)
  end
end

return transicion
