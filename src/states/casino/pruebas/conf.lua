local function pidieron_modo_auto()
  for _, valor in pairs(arg or {}) do
    if valor == "--auto" then return true end
  end
  return false
end

function love.conf(t)
  t.identity = "easy_to_fall_casino_pruebas"
  t.version = "11.5"

  t.window.title = "Pruebas del casino"
  t.window.width = 800
  t.window.height = 600

  t.modules.audio = false
  t.modules.sound = false
  t.modules.joystick = false
  t.modules.physics = false
  t.modules.video = false

  if pidieron_modo_auto() then
    t.modules.window = false
    t.modules.graphics = false
  end
end
