local transicion = {}
local SPRITE_FOLDER = "assets/transicion/sprites personaje transicion/"
local function load_walk_animation(filename, frame_bounds)
  local image = love.graphics.newImage(SPRITE_FOLDER .. filename)
  local image_width, image_height = image:getDimensions()
  local frames = {}
  for index, bounds in ipairs(frame_bounds) do
    local x, y, width, height = bounds[1], bounds[2], bounds[3], bounds[4]
    frames[index] = {
      quad = love.graphics.newQuad(x, y, width, height, image_width, image_height),
      width = width,
      height = height,
      aspect = width / height,
    }
  end
  return {
    image = image,
    frames = frames,
    source_height = image_height,
  }
end

-- Cada cuadro recorta la silueta para que no aparezcan partes de poses vecinas.
local walk_animations = {
  front = load_walk_animation("caminando_frente.png", {
    { 85, 3, 246, 748 }, { 520, 4, 256, 749 },
  }),
  back = load_walk_animation("caminando_atras.png", {
    { 91, 9, 245, 748 }, { 516, 8, 242, 752 },
  }),
  left = load_walk_animation("caminando_izquierda.png", {
    { 6, 150, 262, 509 }, { 284, 150, 159, 509 }, { 483, 149, 207, 510 },
    { 720, 150, 219, 511 }, { 948, 150, 228, 509 }, { 1206, 150, 158, 511 },
  }),
  right = load_walk_animation("caminando_derecha.png", {
    { 26, 153, 152, 473 }, { 238, 154, 184, 471 }, { 439, 155, 213, 471 },
    { 651, 155, 277, 471 }, { 957, 156, 133, 470 }, { 1129, 155, 236, 471 },
  }),
}
local PLAYER_REFERENCE_HEIGHT = 0
local PLAYER_MAX_FRAME_ASPECT = 0
for _, direction in ipairs({ "left", "right" }) do
  for _, frame in ipairs(walk_animations[direction].frames) do
    PLAYER_REFERENCE_HEIGHT = math.max(PLAYER_REFERENCE_HEIGHT, frame.height)
    PLAYER_MAX_FRAME_ASPECT = math.max(PLAYER_MAX_FRAME_ASPECT, frame.aspect)
  end
end
walk_animations.left.idle_frame = #walk_animations.left.frames
walk_animations.right.idle_frame = 1
local filtro_add_tarde = love.graphics.newImage("assets/transicion/Filtro_add(tarde).PNG")
local filtro_add_siempre = love.graphics.newImage("assets/transicion/filtro_add_siempre.PNG")
local filtro_color_burn = love.graphics.newImage("assets/transicion/Filtro_color_burn.PNG")
local filtro_luces_add = love.graphics.newImage("assets/transicion/filtro_luces_add.PNG")
local manana_bg = love.graphics.newImage("assets/transicion/manana_tarde.PNG")
local noche_bg = love.graphics.newImage("assets/transicion/noche.PNG")
local filtro_overlay = love.graphics.newImage("assets/transicion/Filtro_overlay.PNG")
local player_pos = 0
local player_animation = "front"
local player_frame, player_frame_time = 1, 0
local intro_walk_time = 0
local last_walk_direction, turn_time = nil, 0
local exit_walk_direction = nil
local enter_destination, enter_walk_time = nil, 0
local FRAME_DURATION = 0.12
local PLAYER_HEIGHT_RATIO = 0.504
local PLAYER_FLOOR_RATIO = 0.80
local TURN_DURATION = FRAME_DURATION * 2
local FRONT_ONCE_DURATION = FRAME_DURATION * #walk_animations.front.frames
local BACK_ONCE_DURATION = FRAME_DURATION * #walk_animations.back.frames
local DialogueView = require("src/states/transicion/dialogue")
local Audio = require("src/systems/audio")
local light_flickering = false
local footstep_source
local ambience_source

local function stop_footsteps()
  if footstep_source then
    Audio.detener(footstep_source)
    footstep_source = nil
  end
end

local function stop_ambience()
  if ambience_source then
    Audio.detener(ambience_source)
    ambience_source = nil
  end
end

local function update_footsteps(is_walking)
  if is_walking and not footstep_source then
    footstep_source = Audio.reproducir("footsteps", { bucle = true })
  elseif not is_walking then
    stop_footsteps()
  end
end

local function set_player_animation(animation_name)
  if player_animation ~= animation_name then
    player_animation = animation_name
    player_frame, player_frame_time = 1, 0
  end
end

local function set_idle_pose()
  local direction = last_walk_direction
  if direction then
    local animation = walk_animations[direction < 0 and "left" or "right"]
    set_player_animation(direction < 0 and "left" or "right")
    player_frame = animation.idle_frame
  elseif exit_walk_direction then
    local direction = exit_walk_direction
    local animation = walk_animations[direction < 0 and "left" or "right"]
    set_player_animation(direction < 0 and "left" or "right")
    player_frame = animation.idle_frame
  else
    set_player_animation("front")
    player_frame = 1
  end
  player_frame_time = 0
end

-- Coordenadas sobre la imagen original; comparten la transformacion de la camara.
local doors = {
  { x = 24, y = 388, w = 184, h = 342, spawn_ratio = 0.5, state = "casa", label = "Entrar a casa" },
  { x = 8530, y = 298, w = 470, h = 427, spawn_ratio = 0.75, state = "casino", label = "Entrar al casino" },
}
local function get_scene_layout(bg, w, h)
  local sw, sh = bg:getDimensions()
  local scale = h / sh
  local min_x = math.max(0, sw * scale - w)
  local x = math.min(0, math.max(-min_x, -player_pos * scale + w / 3))
  return x, scale
end

local function player_half_width(height, scene_scale)
  return height * PLAYER_HEIGHT_RATIO * PLAYER_REFERENCE_HEIGHT
    * PLAYER_MAX_FRAME_ASPECT / (walk_animations.left.source_height * scene_scale * 2)
end

local function player_inside_door(door, height)
  local scene_scale = height / manana_bg:getHeight()
  local margin = player_half_width(height, scene_scale)
  return player_pos >= door.x + margin and player_pos <= door.x + door.w - margin
end

local function draw_scene(bg, w, h)
  local x, scale = get_scene_layout(bg, w, h)
  love.graphics.draw(bg, x, 0, 0, scale, scale)

  local animation = walk_animations[player_animation]
  local frame = animation.frames[math.min(player_frame, #animation.frames)]
  local player_scale = h * PLAYER_HEIGHT_RATIO * PLAYER_REFERENCE_HEIGHT
    / (animation.source_height * frame.height)
  local center_x = x + player_pos * scale
  local floor_y = h * PLAYER_FLOOR_RATIO
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(animation.image, frame.quad,
    center_x - frame.width * player_scale / 2, floor_y - frame.height * player_scale,
    0, player_scale, player_scale)
end

local function door_label_rect(door, x, scale, w)
  local left, right = x + door.x * scale, x + (door.x + door.w) * scale
  if right < 0 or left > w then return nil end
  return math.max(8, math.min(w - 180, left)), math.max(8, door.y * scale - 40), 172, 32
end

function transicion:door_at(px, py)
  if self.dialogue:is_active() or enter_destination then return nil end
  local w, h = love.graphics.getDimensions()
  if px < 0 or px > w or py < 0 or py > h then return nil end
  local x, scale = get_scene_layout(manana_bg, w, h)
  local sx, sy = (px - x) / scale, py / scale
  for _, door in ipairs(doors) do
    local lx, ly, lw, lh = door_label_rect(door, x, scale, w)
    local player_can_enter = door.state ~= "casino" or player_inside_door(door, h)
    if sx >= door.x and sx <= door.x + door.w
        and sy >= door.y and sy <= door.y + door.h and player_can_enter then
      return door
    end
    if lx and px >= lx and px <= lx + lw and py >= ly and py <= ly + lh
        and player_can_enter then
      return door
    end
  end
end

function transicion:mousepressed(x, y, button)
  if button ~= 1 then return end
  local door = self:door_at(x, y)
  if door then
    stop_footsteps()
    enter_destination, enter_walk_time = door.state, BACK_ONCE_DURATION
    set_player_animation("back")
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
  stop_footsteps()
  stop_ambience()
  ambience_source = Audio.reproducir("transition_ambience", { bucle = true })
  self.context = context
  if context.state_machine.last == "casa" then
    player_pos = doors[1].x + doors[1].w * doors[1].spawn_ratio
  elseif context.state_machine.last == "casino" then
    player_pos = doors[2].x + doors[2].w * doors[2].spawn_ratio
  end
  local _, height = love.graphics.getDimensions()
  local scene_scale = height / manana_bg:getHeight()
  local half_player = player_half_width(height, scene_scale)
  player_pos = math.max(half_player, math.min(manana_bg:getWidth() - half_player, player_pos))
  player_animation, player_frame, player_frame_time = "front", 1, 0
  last_walk_direction, turn_time = nil, 0
  exit_walk_direction = context.state_machine.last == "casa" and 1
    or context.state_machine.last == "casino" and -1
  intro_walk_time = FRONT_ONCE_DURATION
  enter_destination, enter_walk_time = nil, 0
  self.dialogue = DialogueView.new(context, "dialogo.lua")
  self.shader = create_shader()
  self.vignette_shader = create_vignette_shader()
  --self.vignette_shader = vig_shader()
end

function transicion:leave()
  stop_footsteps()
  stop_ambience()
end

function transicion:update(dt)
  self.dialogue:update(dt)
  local dir = 0
  local is_walking = false
  local is_turning = false
  local _, h = love.graphics.getDimensions()
  if love.keyboard.isDown("a") then dir = dir - 1 end
  if love.keyboard.isDown("d") then dir = dir + 1 end
  if intro_walk_time > 0 and not enter_destination then dir = 0 end
  local scale = h / manana_bg:getHeight()
  local half_player = player_half_width(h, scale)
  local previous_player_pos = player_pos
  if enter_destination then
    enter_walk_time = enter_walk_time - dt
    if enter_walk_time <= 0 then
      local destination = enter_destination
      stop_footsteps()
      enter_destination, enter_walk_time = nil, 0
      self.context.state_machine:switch(destination)
      return
    end
  elseif not self.dialogue:is_active() then
    if dir ~= 0 then
      is_walking = true
      if last_walk_direction and dir ~= last_walk_direction and turn_time <= 0 then
        turn_time = TURN_DURATION
      end
      last_walk_direction = dir
      exit_walk_direction = nil
      intro_walk_time = 0
      player_pos = math.max(half_player, math.min(manana_bg:getWidth() - half_player,
        player_pos + dir * (h / 4) * dt / scale * (love.keyboard.isDown("h") and 20 or 1)))
      is_walking = player_pos ~= previous_player_pos
    end
    if turn_time > 0 and dir ~= 0 and is_walking then
      is_turning = true
      set_player_animation("front")
      turn_time = math.max(0, turn_time - dt)
    elseif turn_time > 0 then
      turn_time = 0
      set_idle_pose()
    elseif dir ~= 0 then
      set_player_animation(dir < 0 and "left" or "right")
    elseif intro_walk_time > 0 then
      intro_walk_time = math.max(0, intro_walk_time - dt)
      if intro_walk_time > 0 or not exit_walk_direction then
        set_player_animation("front")
      else
        last_walk_direction = exit_walk_direction
        set_idle_pose()
      end
    elseif exit_walk_direction then
      last_walk_direction = exit_walk_direction
      set_idle_pose()
    elseif dir == 0 then
      set_idle_pose()
    end
  end
  if enter_destination then
    set_player_animation("back")
  end
  update_footsteps(is_walking and not enter_destination)
  if enter_destination or player_animation == "front" and intro_walk_time > 0
      or is_walking or is_turning then
    player_frame_time = player_frame_time + dt
    local frames = walk_animations[player_animation].frames
    while player_frame_time >= FRAME_DURATION do
      player_frame_time = player_frame_time - FRAME_DURATION
      if enter_destination or player_animation == "front" and intro_walk_time > 0 then
        player_frame = math.min(player_frame + 1, #frames)
      else
        player_frame = player_frame % #frames + 1
      end
    end
  else
    player_frame_time = 0
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
  local _, height = love.graphics.getDimensions()
  if key == "c" and not self.dialogue:is_active() and not enter_destination
      and player_inside_door(doors[2], height) then
    stop_footsteps()
    enter_destination, enter_walk_time = "casino", BACK_ONCE_DURATION
    set_player_animation("back")
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
