local transicion = {}
local Characters = require("src/ui/characters")
local StoryView = require("src/ui/story_dialogue")
local Mando = require("src/systems/mando")
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
local function load_car_sprites(filename, moving_y, moving_height, idle_y, idle_height)
  local image = love.graphics.newImage("assets/transicion/" .. filename)
  local image_width, image_height = image:getDimensions()
  return {
    moving = { image = image, height = moving_height, width = image_width,
      quad = love.graphics.newQuad(0, moving_y, image_width, moving_height, image_width, image_height) },
    idle = { image = image, height = idle_height, width = image_width,
      quad = love.graphics.newQuad(0, idle_y, image_width, idle_height, image_width, image_height) },
  }
end
local car_animations = {
  left = load_car_sprites("carro_izquierda.png", 0, 385, 391, 377),
  right = load_car_sprites("carro_derecha.png", 0, 386, 389, 379),
}
local CAR_HEIGHT_RATIO = 0.18 * 1.25 * 1.5
local CAR_ENGINE_SOUND = "assets/transicion/sonido_carro.mp3"
local car_moving = false
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
local step_timer = 0
local car_engine_source

local function stop_footsteps()
  step_timer = 0
end

local function update_footsteps(is_walking, dt)
  if not is_walking then
    step_timer = 0
    return
  end
  step_timer = step_timer - dt
  if step_timer <= 0 then
    Audio.reproducir("footstep_" .. love.math.random(1, 3))
    step_timer = 0.36
  end
end

local function stop_car_engine()
  if car_engine_source then car_engine_source:stop() end
end

local function update_car_engine(is_moving)
  if not is_moving then
    stop_car_engine()
    return
  end
  if not car_engine_source then
    if not (love.audio and love.audio.newSource) then return end
    local ok, source = pcall(love.audio.newSource, CAR_ENGINE_SOUND, "stream")
    if not ok then return end
    car_engine_source = source
    car_engine_source:setLooping(true)
    car_engine_source:setVolume(0.65)
  end
  if not car_engine_source:isPlaying() then car_engine_source:play() end
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

local function door_in_front(height)
  local margin = player_half_width(height, height / manana_bg:getHeight())
  for _, door in ipairs(doors) do
    if player_pos >= door.x - margin and player_pos <= door.x + door.w + margin then return door end
  end
end

local function draw_scene(bg, w, h, context, facing)
  local x, scale = get_scene_layout(bg, w, h)
  love.graphics.draw(bg, x, 0, 0, scale, scale)

  local center_x = x + player_pos * scale
  local floor_y = h * PLAYER_FLOOR_RATIO
  if Characters.has_car(context) then
    local car_height = h * CAR_HEIGHT_RATIO
    local sprite = car_animations[(facing or 1) < 0 and "left" or "right"][car_moving and "moving" or "idle"]
    local car_scale = car_height / sprite.height
    local car_width = sprite.width * car_scale
    center_x = math.max(car_width / 2, math.min(w - car_width / 2, center_x))
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(sprite.image, sprite.quad, center_x - car_width / 2, floor_y - car_height,
      0, car_scale, car_scale)
    return
  end
  local animation = walk_animations[player_animation]
  local frame = animation.frames[math.min(player_frame, #animation.frames)]
  local player_scale = h * PLAYER_HEIGHT_RATIO * PLAYER_REFERENCE_HEIGHT
    / (animation.source_height * frame.height)
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

function transicion:can_go_home()
  local day_flow = self.context.day_flow
  if not (day_flow and day_flow:is_active()) then return true end
  local games = self.context.progress:get_value("casino_games_today")
  if games == 0 or games == 3 or games == 6 then return true end
  self.transition_error = "La jornada requiere 3 o 6 partidas antes de volver a casa."
  return false
end

function transicion:enter_door(door)
  if door.state == "casa" and not self:can_go_home() then return end
  stop_footsteps()
  stop_car_engine()
  car_moving = false
  Audio.reproducir("door_open")
  enter_destination, enter_walk_time = door.state, BACK_ONCE_DURATION
  set_player_animation("back")
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
  if self.context.story and self.dialogue:is_active() then
    self.dialogue:mousepressed(x, y, button)
    return
  end
  local door = self:door_at(x, y)
  if door then self:enter_door(door) end
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
  stop_footsteps()
  stop_car_engine()
  car_moving = false
  Audio.iniciar_bucle("calle_ambiente")
  self.context = context
  self.transition_error = nil
  local from_house = from_casa or context.state_machine.last == "casa"
  self.facing = from_house and 1 or -1
  if from_house then
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
  exit_walk_direction = from_house and 1 or context.state_machine.last == "casino" and -1 or nil
  intro_walk_time = Characters.has_car(context) and 0 or FRONT_ONCE_DURATION
  enter_destination, enter_walk_time = nil, 0
  if context.story then
    self.dialogue = StoryView.new(context, context.story:street(from_house), nil, { portrait_mode = "transition" })
  else
    self.dialogue = DialogueView.new(context, "dialogo.lua")
  end
  self.shader = create_shader()
  self.vignette_shader = create_vignette_shader()
end

function transicion:leave()
  stop_footsteps()
  stop_car_engine()
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
  local speed = Characters.travel_speed(self.context, h)
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
      self.facing = dir
      self.transition_error = nil
      if last_walk_direction and dir ~= last_walk_direction and turn_time <= 0 then
        turn_time = TURN_DURATION
      end
      last_walk_direction = dir
      exit_walk_direction = nil
      intro_walk_time = 0
      player_pos = math.max(half_player, math.min(manana_bg:getWidth() - half_player,
        player_pos + dir * speed * dt / scale * (love.keyboard.isDown("h") and 20 or 1)))
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
  local has_car = Characters.has_car(self.context)
  car_moving = has_car and is_walking and not enter_destination
  update_footsteps(is_walking and not enter_destination and not has_car, dt)
  update_car_engine(car_moving)
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

function transicion:keypressed(key, scancode, isrepeat)
  local was_active = self.dialogue:is_active()
  self.dialogue:keypressed(key, scancode, isrepeat)
  if was_active or self.dialogue:is_active() or enter_destination then return end
  local _, height = love.graphics.getDimensions()
  local door = door_in_front(height)
  if not door then return end
  if key == "return" or key == "z" or (key == "c" and door.state == "casino") then
    self:enter_door(door)
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
  local in_front = door_in_front(h)
  if not self.dialogue:is_active() then
    local hovered = self:door_at(love.mouse.getPosition())
    love.graphics.push("all")
    for _, door in ipairs(doors) do
      local lx, ly, lw, lh = door_label_rect(door, x, scale, w)
      if lx then
        local marked = door == hovered or door == in_front
        if marked then
          love.graphics.setColor(1, 1, 0.3, 1)
          love.graphics.setLineWidth(2)
          love.graphics.rectangle("line", x + door.x * scale, door.y * scale,
            door.w * scale, door.h * scale)
        end
        love.graphics.setColor(0, 0, 0, 0.85)
        love.graphics.rectangle("fill", lx, ly, lw, lh, 4, 4)
        love.graphics.setColor(1, 1, marked and 0.3 or 1, 1)
        love.graphics.printf(door.label, lx, ly + 8, lw, "center")
      end
    end
    love.graphics.pop()
  end
  self.dialogue:draw()
  self.fuente_ayuda = self.fuente_ayuda or love.graphics.newFont(math.max(16, math.floor(h * 0.028)))
  if self.fuente_ayuda and not self.dialogue:is_active() and not enter_destination then
    local texto = in_front and (Mando.boton("aceptar") .. " · " .. in_front.label)
      or (Mando.boton("correr") .. " · " .. (Characters.has_car(self.context) and "Acelerar" or "Correr"))
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
