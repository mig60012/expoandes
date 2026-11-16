local Characters = require("src/ui/characters")
local View = require("src/ui/story_dialogue")
local Progress = require("src/systems/progress")
local Plano = require("src/states/casino/plano")
local context = { progress = Progress.new({ flags = { car_sold = false } }) }
for _, height in ipairs({600,720,1080}) do
  local driving = Characters.travel_speed(context, height)
  context.progress:set_flag("car_sold", true)
  assert(not Characters.has_car(context))
  assert(driving == Characters.travel_speed(context, height) * 2, "el carro se mueve al doble de la velocidad a pie")
  context.progress:set_flag("car_sold", false)
end
local one = View.layout(1280, 720, 0, 1)
local two = View.layout(1280, 720, 0, 2)
local choice = View.layout(1280, 720, 3, 2)
assert(one.panel.h < 720 * 0.20, "un parlamento corto no reserva un tercio de la pantalla")
assert(one.panel.h < two.panel.h and two.panel.h < choice.panel.h, "el cuadro crece solo por texto u opciones reales")
assert(choice.hint_y > choice.choices[3].y + choice.choices[3].h, "la ayuda no tapa las opciones")

local original_love = love
local mx, my, switched, polygons, circles = 50, 200, nil, 0, 0
local loaded = {}
love = {
  graphics = setmetatable({
    getDimensions = function() return 1280,720 end,
    newFont = function() return { getHeight = function() return 18 end, getWidth = function() return 100 end,
      getWrap = function(_, text, width) return width, { text } end } end,
    newImage = function(path)
      loaded[path] = true
      return { getWidth = function() return 1920 end, getHeight = function() return 1080 end }
    end,
    polygon = function() polygons = polygons + 1 end,
    circle = function() circles = circles + 1 end,
  }, { __index = function() return function() end end }),
  filesystem = { getInfo = function() return true end },
  mouse = { getPosition = function() return mx,my end, setVisible = function() end, setGrabbed = function() end },
}
local selected
local options_view = View.new(context, { start = "choice", nodes = { choice = { speaker = "Protagonista",
  text = "Elige una respuesta.", choices = { {text="Primera", action="first"}, {text="Segunda", action="second"} } } } },
  function(_, choice) selected = choice.action end)
options_view:_refresh()
local rect = options_view:_layout(2).choices[2]
options_view:mousepressed(rect.x + 5, rect.y + rect.h / 2, 1)
assert(selected == "second" and not options_view.active, "los clics usan la misma geometria compacta que el dibujo")
local Casa = assert(loadfile("src/states/casa.lua"))()
Casa:enter({ time_of_day = 0, state_machine = { switch = function(_, name) switched = name end } })
local bag
for _, object in ipairs(Casa.objetos) do
  assert(object.id ~= "celular", "no queda un telefono ni su hotspot en la casa")
  if object.id == "maletin" then bag = object end
end
assert(bag and bag.activo == false and bag.accion, "el maletin conserva su codigo pero esta desactivado")
Casa:update(0)
assert(not Casa.hover, "el maletin desactivado no se resalta")
Casa.hover = bag
Casa:mousepressed(50,200,1)
assert(not switched and not Casa.dialogue, "ni un hover antiguo permite activar el maletin")
Casa:mousepressed(350,530,1)
assert(not Casa.panel and not switched, "el antiguo lugar del celular ya no hace nada")
for _, object in ipairs(Casa.objetos) do if object.id == "puerta" then Casa.hover = object end end
Casa:mousepressed(350,530,1)
Casa:mousepressed(50,200,1)
assert(not switched, "un hover antiguo sobre la puerta no vuelve activas las zonas eliminadas")
assert(not loaded["assets/casa/celular.png"], "no se carga el sprite eliminado")
Casa:leave()
Characters.world(0,0,100,true,1)
assert(polygons >= 4 and circles >= 6, "el carro tiene perfil, ventanillas y ruedas, no solo un rectangulo")
love = original_love

for _, path in ipairs({ Plano.arte.ruta, Plano.arte.multiplicar, Plano.arte.sumar[1], Plano.arte.sumar[2] }) do
  local file = assert(io.open(path,"rb"), path)
  local header = file:read(24); file:close()
  assert(header:sub(2,4) == "PNG", "el asset procesado es una imagen PNG")
  if path == Plano.arte.ruta then
    local function number(i)
      local a,b,c,d = header:byte(i,i+3)
      return ((a*256+b)*256+c)*256+d
    end
    assert(number(17) == Plano.ancho and number(21) == Plano.alto, "el fondo del salon tiene la resolucion del mundo")
  end
end
for _, object in ipairs(Plano.objetos) do assert(#object.choque >= 6, "las tres mesas tienen su capa de profundidad") end
print("presentation: car speed, compact boxes, disabled bag, removed phone and casino artwork: ok")
