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
local function get_scene_layout(bg, w, h)
  local sw, sh = bg:getDimensions()
  local scale = h / sh
  local min_x = sw * scale - w
  local x = math.min(0, math.max(-min_x, -player_pos + w / 3))
  return x, scale
end

local function draw_scene(bg, w, h)
  local x, scale = get_scene_layout(bg, w, h)
  love.graphics.draw(bg, x, 0, 0, scale, scale)

  local bw = bg:getWidth()
  local ph = player:getHeight()
  if player_pos > w / 3 and player_pos < bw * scale - 2 * w / 3 then
    love.graphics.draw(player, w / 3, 655, 0, (h / ph) / 6)
  elseif player_pos < w / 3 then
    love.graphics.draw(player, player_pos, 655, 0, (h / ph) / 6)
  else
    love.graphics.draw(player, player_pos - bw * scale + w, 655, 0, (h / ph) / 6)
  end
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
  player_pos = player_pos + dir * (love.keyboard.isDown("h") and 20 or 1)
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
  self.dialogue:draw()
end

return transicion
