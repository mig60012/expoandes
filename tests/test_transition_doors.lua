local original_love = love
local dialogue_module = "src/states/transicion/dialogue"
local original_dialogue = package.loaded[dialogue_module]
local width, height = 1280, 720
local keys, drawn = {}, {}
local function image(path)
  local w, h = 1920, 1080
  if path:find("transicion/") then w, h = 9600, 1080 end
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
    newFont = function()
      return { getWidth = function() return 100 end, getHeight = function() return 18 end }
    end,
    draw = function(sprite) drawn[#drawn + 1] = sprite.path end,
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
    }
  end,
}
local transition = assert(loadfile("src/states/transicion.lua"))()
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
click_left()
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
local scale = height / 1080
local offset = width - 9600 * scale
transition:mousepressed(offset + 8700 * scale, 500 * scale, 1)
assert(destination == "casino", "right door enters the casino after scrolling")
assert(transition:door_at(60 * scale, 500 * scale) == nil, "offscreen house cannot be clicked")

-- Walking cannot move beyond either end of the street.
keys = { a = true, h = true }
transition:update(100)
click_left()
assert(destination == "casa", "left boundary remains accessible")
keys = { d = true, h = true }
transition:update(100)
transition:mousepressed(offset + 8700 * scale, 500 * scale, 1)
assert(destination == "casino", "right boundary remains accessible")
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
assert(machine.current_name == "casa", "street house door really enters the house")
assert(house.sprites.fondo.path == "assets/casa/fondo.png")
machine:mousepressed(800, 180, 1)
context.time_of_day = 2
machine:mousepressed(30, 730 * height / 1080 + 24, 1) -- Visible entrance label.
assert(machine.current_name == "casa", "visible house entrance label is also clickable")
assert(house.sprites.fondo.path == "assets/casa/fondo_noche.png", "round trip preserves night")
house:leave()

love = original_love
package.loaded[dialogue_module] = original_dialogue
print("transition doors and house time of day: ok")
