local original_love = love
local dialogue_module = "src/states/transicion/dialogue"
local original_dialogue = package.loaded[dialogue_module]
local audio_module = "src/systems/audio"
local original_audio = package.loaded[audio_module]
local footstep_starts, footstep_stops, footstep_source = 0, 0, nil
local ambience_starts, ambience_stops, ambience_source = 0, 0, nil
package.loaded[audio_module] = {
  reproducir = function(name, options)
    assert(options.bucle, name .. " plays in a loop")
    local source = { active = true }
    if name == "footsteps" then
      footstep_starts = footstep_starts + 1
      footstep_source = source
    elseif name == "transition_ambience" then
      ambience_starts = ambience_starts + 1
      ambience_source = source
    else
      error("unexpected audio effect: " .. tostring(name))
    end
    return source
  end,
  detener = function(source)
    if source and source.active then
      source.active = false
      if source == footstep_source then
        footstep_stops = footstep_stops + 1
      elseif source == ambience_source then
        ambience_stops = ambience_stops + 1
      end
    end
  end,
}
local width, height = 1280, 720
local keys, drawn, draw_calls, sprite_quads = {}, {}, {}, {}
local function image(path)
  local w, h = 1920, 1080
  if path:find("sprites personaje transicion", 1, true) then
    w, h = 1368, 768
    if path:find("caminando_frente.png", 1, true) then w, h = 872, 768 end
    if path:find("caminando_atras.png", 1, true) then w, h = 863, 768 end
  elseif path:find("transicion/") then
    w, h = 9600, 1080
  end
  return {
    path = path,
    getDimensions = function() return w, h end,
    getWidth = function() return w end,
    getHeight = function() return h end,
  }
end
love = {
  graphics = setmetatable({
    newImage = image,
    getDimensions = function() return width, height end,
    newShader = function() return { send = function() end } end,
    newQuad = function(x, y, w, h, source_width, source_height)
      local quad = { x = x, y = y, w = w, h = h, source_width = source_width, source_height = source_height }
      sprite_quads[#sprite_quads + 1] = quad
      return quad
    end,
    newCanvas = function() return image("canvas") end,
    newFont = function()
      return { getWidth = function() return 100 end, getHeight = function() return 18 end }
    end,
    draw = function(sprite, quad, x, y, rotation, scale_x, scale_y)
      if sprite and sprite.path then
        drawn[#drawn + 1] = sprite.path
        draw_calls[#draw_calls + 1] = {
          path = sprite.path,
          quad = quad,
          x = x,
          y = y,
          scale_x = scale_x,
          scale_y = scale_y,
        }
      end
    end,
  }, { __index = function() return function() end end }),
  filesystem = { getInfo = function() return true end },
  keyboard = { isDown = function(key) return keys[key] end },
  mouse = {
    getPosition = function() return 0, 0 end,
    setVisible = function() end,
    setGrabbed = function() end,
  },
  math = { random = function() return 0 end },
}
package.loaded[dialogue_module] = {
  new = function()
    return {
      active = false,
      is_active = function(self) return self.active end,
      update = function() end,
      keypressed = function() end,
      draw = function() end,
    }
  end,
}
local transition = assert(loadfile("src/states/transicion.lua"))()
assert(#sprite_quads == 16, "all animation poses have a dedicated crop")
assert(sprite_quads[5].x == 6 and sprite_quads[5].w == 262,
  "left-walk first pose is cropped to its own visible bounds")
assert(sprite_quads[10].x == 1206 and sprite_quads[10].w == 158,
  "left-walk last pose excludes the neighboring sprite")
assert(sprite_quads[15].x == 957 and sprite_quads[15].w == 133,
  "right-walk fifth pose excludes the neighboring sprite")
local house = assert(loadfile("src/states/casa.lua"))()
local destination
local context = {
  time_of_day = 2,
  state_machine = {
    last = "casa",
    switch = function(_, name) destination = name end,
  },
}

local function click_left()
  transition:mousepressed(60 * height / 1080, 500 * height / 1080, 1)
end
transition:enter(context)
assert(ambience_starts == 1 and ambience_source.active,
  "wind and rain ambience starts looping when entering the transition")
transition:update(0.8)
draw_calls = {}
transition:draw()
assert(draw_calls[2].path:find("caminando_derecha.png", 1, true),
  "leaving the house exits facing right")
click_left()
assert(destination == nil, "door entry waits for the walk animation")
transition:update(1)
assert(destination == "casa", "left door enters the house")
assert(context.time_of_day == 2, "entering a door preserves nighttime")
destination = nil
transition:mousepressed(40, 333, 2)
assert(destination == nil, "right clicks do not enter")
transition:mousepressed(400, 100, 1)
assert(destination == nil, "clicks outside doors do not enter")
transition.dialogue.active = true
click_left()
assert(destination == nil, "dialogue blocks door clicks")
transition.dialogue.active = false

-- Returning from the casino frames its door, using the same camera as drawing.
context.state_machine.last = "casino"
transition:enter(context)
transition:update(0.25)
draw_calls = {}
transition:draw()
assert(draw_calls[2].path:find("caminando_izquierda.png", 1, true),
  "leaving the casino exits facing left after the front animation")
local scale = height / 1080
local offset = width - 9600 * scale
assert(transition:door_at(offset + 8700 * scale, 500 * scale).state == "casino",
  "returning from the casino starts on the sidewalk at the marked position")
transition:mousepressed(offset + 8700 * scale, 500 * scale, 1)
assert(destination == nil, "casino entry waits for the walk animation")
transition:update(1)
assert(destination == "casino", "right door enters the casino after scrolling")
assert(transition:door_at(60 * scale, 500 * scale) == nil, "offscreen house cannot be clicked")

-- Walking cannot move beyond either end of the street.
keys = { a = true, h = true }
transition:update(100)
click_left()
transition:update(1)
assert(destination == "casa", "left boundary remains accessible")
keys = { d = true, h = true }
transition:update(100)
destination = nil
transition:mousepressed(offset + 8700 * scale, 500 * scale, 1)
assert(destination == nil, "casino door cannot be used from beyond its margin")
transition:keypressed("c")
transition:update(1)
assert(destination == nil, "casino shortcut also requires the player to be near its door")
keys = { a = true, h = true }
transition:update(0.14)
assert(transition:door_at(offset + 8700 * scale, 500 * scale).state == "casino",
  "walking back inside the casino-door margin enables entry")
transition:mousepressed(offset + 8700 * scale, 500 * scale, 1)
transition:update(1)
assert(destination == "casino", "casino door enters when the player is within its margin")
keys = {}

-- Hit testing follows changes in window size, not fixed screen coordinates.
width, height = 1920, 1080
context.state_machine.last = "casa"
transition:enter(context)
assert(transition:door_at(60, 500).state == "casa")
width, height = 10000, 720
assert(transition:door_at(60 * height / 1080, 500 * height / 1080).state == "casa",
  "a window wider than the scene keeps its origin at zero")

width, height = 1280, 720
for _, time in ipairs({ 0, 1, 2, 2, 0 }) do
  context.time_of_day = time
  house:enter(context)
  local expected = time >= 2 and "assets/casa/fondo_noche.png" or "assets/casa/fondo.png"
  assert(house.sprites.fondo.path == expected, "house selects the correct time-of-day asset")
  drawn = {}
  house:draw()
  assert(drawn[1] == expected, "house draws the selected background")
  for _, object in ipairs(house.objetos) do
    if object.id == "puerta" then
      object.accion(house)
      assert(destination == "transicion", "house exit leads back to the street")
    end
  end
  house:leave()
end

-- Exercise actual state-machine dispatch, not just a destination-name stub.
local machine = assert(loadfile("src/state_machine.lua"))()
machine.states = { casa = house, transicion = transition }
context.state_machine = machine
machine.context = context
context.time_of_day = 0
machine:switch("casa")
machine:mousepressed(800, 180, 1) -- Interior door, without a prior hover/update.
assert(machine.current_name == "transicion", "house door really exits to the street")
machine:mousepressed(60 * height / 1080, 500 * height / 1080, 1)
assert(machine.current_name == "transicion", "street entry plays its walk animation")
machine:update(1)
assert(machine.current_name == "casa", "street house door really enters the house")
assert(house.sprites.fondo.path == "assets/casa/fondo.png")
machine:mousepressed(800, 180, 1)
context.time_of_day = 2
machine:mousepressed(30, 388 * height / 1080 - 24, 1) -- Visible label above the house door.
assert(machine.current_name == "transicion", "visible entrance label plays its walk animation")
machine:update(1)
assert(machine.current_name == "casa", "visible house entrance label is also clickable")
assert(house.sprites.fondo.path == "assets/casa/fondo_noche.png", "round trip preserves night")
house:leave()

transition:enter(context)
local function draw_player()
  draw_calls = {}
  transition:draw()
  return draw_calls[2]
end
local front_pose = draw_player()
local door_height = height * 342 / 1080
assert(math.abs(front_pose.quad.h * front_pose.scale_y - door_height * 1.05) <= 3,
  "character height is scaled to 0.7 of its previous size")
transition:update(0.13)
local front_second_frame = draw_player()
assert(front_second_frame.path:find("caminando_frente.png", 1, true)
    and front_second_frame.quad.x ~= front_pose.quad.x,
  "front-facing exit animation advances to its second pose")
transition:update(0.13)
local after_front_cycle = draw_player()
assert(after_front_cycle.path:find("caminando_derecha.png", 1, true),
  "leaving the house exits facing right after the front animation")
transition:update(0.8)
local idle_frame = draw_player()
transition:update(1)
local stopped_frame = draw_player()
assert(idle_frame.quad == stopped_frame.quad and idle_frame.x == stopped_frame.x,
  "idle character stops animating and moving")

local starts_before_walk, stops_before_walk = footstep_starts, footstep_stops
keys = { a = true }
transition:update(0.14)
local left_walk_frame = draw_player()
assert(footstep_starts == starts_before_walk + 1 and footstep_source.active,
  "walking starts the looping footstep sound")
assert(left_walk_frame.path:find("caminando_izquierda.png", 1, true),
  "holding left selects the left-walk animation")
assert(left_walk_frame.quad ~= idle_frame.quad, "moving advances the walk cycle")
keys = {}
transition:update(1)
assert(footstep_stops == stops_before_walk + 1 and not footstep_source.active,
  "stopping movement stops the footstep sound")
local left_stopped_frame = draw_player()
assert(left_stopped_frame.path:find("caminando_izquierda.png", 1, true)
    and left_stopped_frame.quad.x == 1206,
  "stopping after moving left keeps the left-facing idle pose")
assert(math.abs(front_pose.quad.h * front_pose.scale_y
    - left_stopped_frame.quad.h * left_stopped_frame.scale_y) < 1,
  "front and side poses render at the same height")
assert(math.abs(left_stopped_frame.y + left_stopped_frame.quad.h * left_stopped_frame.scale_y
    - height * 0.80) < 1,
  "shoes rest on the sidewalk at the arrow's ground level")

keys = { d = true }
transition:update(0.01)
local turn_frame = draw_player()
assert(turn_frame.path:find("caminando_frente.png", 1, true),
  "changing direction turns through the front sprite")
transition:update(0.3)
transition:update(0.01)
local right_walk_frame = draw_player()
assert(right_walk_frame.path:find("caminando_derecha.png", 1, true),
  "right-walk starts on a valid frame after turning")
keys = {}
transition:update(1)
local right_stopped_frame = draw_player()
assert(right_stopped_frame.path:find("caminando_derecha.png", 1, true)
    and right_stopped_frame.quad.x == 26,
  "stopping after moving right keeps the right-facing idle pose")

transition:enter(context)
click_left()
local back_pose = draw_player()
assert(math.abs(back_pose.quad.h * back_pose.scale_y
    - right_stopped_frame.quad.h * right_stopped_frame.scale_y) < 1,
  "back pose renders at the same height as the side poses")
transition:update(0.13)
local back_second_frame = draw_player()
assert(back_second_frame.path:find("caminando_atras.png", 1, true)
    and back_second_frame.quad.x ~= back_pose.quad.x,
  "back-facing entry animation advances to its second pose")
destination = nil
transition:update(0.13)
assert(destination == "casa", "back-facing entry animation plays once before switching states")
transition:leave()
assert(not ambience_source.active and ambience_stops > 0,
  "wind and rain ambience stops when leaving the transition")

love = original_love
package.loaded[dialogue_module] = original_dialogue
package.loaded[audio_module] = original_audio
print("transition doors and house time of day: ok")
