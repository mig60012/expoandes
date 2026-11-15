local transicion = {}
local player = love.graphics.newImage("assets/ugandan_knuckles.png")
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
-- Coordenadas sobre la imagen original; comparten la transformacion de la camara.
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

local function draw_scene(bg, w, h)
  local x, scale = get_scene_layout(bg, w, h)
  love.graphics.draw(bg, x, 0, 0, scale, scale)

  local ph = player:getHeight()
  love.graphics.draw(player, x + player_pos * scale, h * 0.73, 0, (h / ph) / 6)
end

local function door_label_rect(door, x, scale, w)
  local left, right = x + door.x * scale, x + (door.x + door.w) * scale
  if right < 0 or left > w then return nil end
  return math.max(8, math.min(w - 180, left)), (door.y + door.h) * scale + 8, 172, 32
end

function transicion:door_at(px, py)
  if self.dialogue:is_active() then return nil end
  local w, h = love.graphics.getDimensions()
  if px < 0 or px > w or py < 0 or py > h then return nil end
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
  local door = self:door_at(x, y)
  if door then self.context.state_machine:switch(door.state) end
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

function transicion:enter(context)
  self.context = context
  if context.state_machine.last == "casa" then
    player_pos = doors[1].x
  elseif context.state_machine.last == "casino" then
    player_pos = doors[2].x
  end
  self.dialogue = DialogueView.new(context, "dialogo.lua")
  self.shader = create_shader()
  self.vignette_shader = create_vignette_shader()
  --self.vignette_shader = vig_shader()
end

function transicion:update(dt)
  self.dialogue:update(dt)
  local dir = 0
  local _, h = love.graphics.getDimensions()
  if love.keyboard.isDown("a") then
    dir = dir - (h / 4) * dt
  end
  if love.keyboard.isDown("d") then
    dir = dir + (h / 4) * dt
  end
  local scale = h / manana_bg:getHeight()
  local player_width = player:getWidth() * (h / player:getHeight()) / 6 / scale
  if not self.dialogue:is_active() then
    player_pos = math.max(0, math.min(manana_bg:getWidth() - player_width,
      player_pos + dir / scale * (love.keyboard.isDown("h") and 20 or 1)))
  end
  if not light_flickering then
    if love.math.random() > 0.99 then
      light_flickering = true
    end
  else
    if love.math.random() > 0.95 then
      light_flickering = false
    end
  end
end

function transicion:keypressed(key)
  self.dialogue:keypressed(key)
  if key == "c" and not self.dialogue:is_active() then
    self.context.state_machine:switch("casino")
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
  draw_scene(bg, w, h)
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
  if not self.dialogue:is_active() then
    local hovered = self:door_at(love.mouse.getPosition())
    love.graphics.push("all")
    for _, door in ipairs(doors) do
      local lx, ly, lw, lh = door_label_rect(door, x, scale, w)
      if lx then
        if door == hovered then
          love.graphics.setColor(1, 1, 0.3, 1)
          love.graphics.setLineWidth(2)
          love.graphics.rectangle("line", x + door.x * scale, door.y * scale,
            door.w * scale, door.h * scale)
        end
        love.graphics.setColor(0, 0, 0, 0.85)
        love.graphics.rectangle("fill", lx, ly, lw, lh, 4, 4)
        love.graphics.setColor(1, 1, door == hovered and 0.3 or 1, 1)
        love.graphics.printf(door.label, lx, ly + 8, lw, "center")
      end
    end
    love.graphics.pop()
  end
  self.dialogue:draw()
end

return transicion
