local original_love = love
local dialogue_module = "src/states/transicion/dialogue"
local original_dialogue = package.loaded[dialogue_module]
local width, height = 1280, 720
local drawn = {}

local function image(path)
  return {
    path = path,
    getDimensions = function() return 9600, 1080 end,
    getWidth = function() return 9600 end,
    getHeight = function() return 1080 end,
  }
end

love = {
  graphics = setmetatable({
    newImage = image,
    getDimensions = function() return width, height end,
    newShader = function() return { send = function() end } end,
    newCanvas = function(w, h)
      return { getWidth = function() return w end, getHeight = function() return h end }
    end,
    draw = function(sprite)
      if sprite and sprite.path then drawn[#drawn + 1] = sprite.path end
    end,
  }, { __index = function() return function() end end }),
  filesystem = { getInfo = function() return true end },
  keyboard = { isDown = function() return false end },
  mouse = { getPosition = function() return 0, 0 end },
  math = { random = function() return 0 end },
}

package.loaded[dialogue_module] = {
  new = function()
    return {
      is_active = function() return false end,
      update = function() end,
      keypressed = function() end,
      draw = function() end,
    }
  end,
}

local transition = assert(loadfile("src/states/transicion.lua"))()
local car_sold = false
local context = {
  time_of_day = 0,
  state_machine = { last = "casa" },
  progress = { get_flag = function(_, flag)
    if flag == "car_sold" then return car_sold end
  end },
}

local function draw_transition()
  drawn = {}
  transition:enter(context)
  transition:draw()
  local walking_sprites, car_sprites = 0, 0
  for _, path in ipairs(drawn) do
    if path:find("sprites personaje transicion", 1, true) then
      walking_sprites = walking_sprites + 1
    end
    if path:find("assets/transicion/carro_", 1, true) then car_sprites = car_sprites + 1 end
  end
  return walking_sprites, car_sprites
end

local walking_sprites, cars = draw_transition()
assert(walking_sprites == 0 and cars == 1,
  "the car is the transition transport while it has not been sold")

car_sold = true
walking_sprites, cars = draw_transition()
assert(walking_sprites == 1 and cars == 0,
  "selling the car switches the transition to the walking character")

love = original_love
package.loaded[dialogue_module] = original_dialogue
print("test_transition_vehicle: ok")
