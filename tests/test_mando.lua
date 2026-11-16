local love_real = love
local raton = { x = 100, y = 100 }
local ejes = { leftx = 0, lefty = 0, rightx = 0, righty = 0 }
local teclado, botones_raton = {}, {}
local mando = {
  isGamepad = function() return true end,
  getGamepadAxis = function(_, eje) return ejes[eje] or 0 end,
}
love = {
  keyboard = { isDown = function(tecla) return teclado[tecla] == true end },
  mouse = {
    getPosition = function() return raton.x, raton.y end,
    setPosition = function(x, y) raton.x, raton.y = x, y end,
    isDown = function(boton) return botones_raton[boton] == true end,
  },
  graphics = { getDimensions = function() return 1280, 720 end },
  joystick = { getJoysticks = function() return { mando } end },
}

package.loaded["src/systems/mando"] = nil
local Mando = require("src/systems/mando")
local eventos = {}
local function anotar(...)
  eventos[#eventos + 1] = table.concat({ ... }, " ")
end
Mando.iniciar({
  tecla = function(tecla) anotar("tecla", tecla) end,
  soltar_tecla = function(tecla) anotar("soltar", tecla) end,
  clic = function(x, y, boton) anotar("clic", x, y, boton) end,
  soltar_clic = function(x, y, boton) anotar("soltar_clic", x, y, boton) end,
})
local function ultimo() return eventos[#eventos] end

assert(love.keyboard.isDown == Mando.isDown, "el juego lee el control con love.keyboard.isDown")
assert(love.mouse.isDown == Mando.raton_isDown, "el juego lee el clic del control con love.mouse.isDown")
Mando.iniciar({})
Mando.iniciar({
  tecla = function(tecla) anotar("tecla", tecla) end,
  soltar_tecla = function(tecla) anotar("soltar", tecla) end,
  clic = function(x, y, boton) anotar("clic", x, y, boton) end,
  soltar_clic = function(x, y, boton) anotar("soltar_clic", x, y, boton) end,
})
teclado.d = true
assert(love.keyboard.isDown("d"), "iniciar dos veces no pierde el teclado real")
teclado.d = nil

assert(Mando.boton("aceptar") == "Z" and Mando.boton("volver") == "Esc", "con teclado la ayuda muestra Z y Esc")
local sony = {
  getDeviceInfo = function() return 1356, 3302, 1 end,
  getName = function() return "Wireless Controller" end,
}
Mando.presionar(sony, "start", false)
Mando.soltar(sony, "start")
assert(Mando.boton("aceptar") == "X" and Mando.boton("volver") == "O", "con PlayStation la ayuda muestra X y O")
Mando.usar_teclado()
assert(Mando.boton("reiniciar") == "R", "al volver al teclado la ayuda vuelve a las teclas")
ejes.leftx = 0.9
Mando.actualizar(0.016, false)
ejes.leftx = 0
Mando.actualizar(0.016, false)
assert(Mando.boton("aceptar") == "A" and Mando.boton("volver") == "B", "mover el stick de Xbox cambia la ayuda a A y B")
Mando.usar_teclado()

Mando.presionar(mando, "a", false)
assert(ultimo() == "tecla return", "A confirma como Enter al caminar")
Mando.soltar(mando, "a")
assert(ultimo() == "soltar return", "soltar A suelta Enter")
local esperadas = { b = "escape", x = "return", y = "r", start = "return", back = "f1", leftshoulder = "c" }
for boton, tecla in pairs(esperadas) do
  Mando.presionar(mando, boton, false)
  assert(ultimo() == "tecla " .. tecla, boton .. " equivale a " .. tecla)
  Mando.soltar(mando, boton)
  assert(ultimo() == "soltar " .. tecla, "soltar " .. boton .. " suelta " .. tecla)
end
Mando.presionar(mando, "y", true)
assert(ultimo() == "tecla r", "Y manda R aunque haya puntero")

Mando.presionar(mando, "dpleft", false)
assert(ultimo() == "tecla left", "la cruceta manda flechas")
assert(love.keyboard.isDown("a") and love.keyboard.isDown("left"), "la cruceta sostenida camina como A y como la flecha")
local antes = #eventos
Mando.actualizar(0.3, false)
assert(#eventos == antes, "no repite antes de la espera")
Mando.actualizar(0.2, false)
assert(ultimo() == "tecla left", "repite la flecha si se mantiene")
Mando.soltar(mando, "dpleft")
assert(not love.keyboard.isDown("a"), "soltar la cruceta deja de caminar")

ejes.leftx = 0.4
Mando.actualizar(0.016, false)
assert(love.keyboard.isDown("right", "d"), "el stick camina pasada la zona muerta")
assert(ultimo() ~= "tecla right", "un toque suave del stick no mueve los menus")
ejes.leftx = 0.9
Mando.actualizar(0.016, false)
assert(ultimo() == "tecla right", "el stick a fondo mueve los menus")
ejes.leftx, ejes.lefty = 0.1, -0.1
Mando.actualizar(0.016, false)
assert(not love.keyboard.isDown("right", "up"), "la zona muerta ignora el temblor del stick")
ejes.leftx, ejes.lefty = 0, 0

ejes.rightx = 1
Mando.actualizar(0.1, false)
assert(raton.x == 100, "sin puntero el stick derecho no mueve el mouse")
ejes.rightx = 0
ejes.leftx = 1
for _ = 1, 30 do
  Mando.actualizar(1 / 60, true)
end
assert(raton.x > 500 and raton.y == 100, "en pantallas con mouse el stick mueve el puntero")
assert(not love.keyboard.isDown("right"), "con puntero el stick no camina")
ejes.leftx, ejes.righty = 0, 1
local y_antes = raton.y
for _ = 1, 10 do
  Mando.actualizar(1 / 60, true)
end
assert(raton.y > y_antes, "el stick derecho tambien mueve el puntero")
ejes.righty = 0
Mando.presionar(mando, "a", true)
assert(ultimo() == "clic " .. raton.x .. " " .. raton.y .. " 1", "A hace clic donde esta el puntero")
assert(love.mouse.isDown(1), "mantener A arrastra como el boton del mouse")
Mando.soltar(mando, "a")
assert(ultimo() == "soltar_clic " .. raton.x .. " " .. raton.y .. " 1", "soltar A suelta el clic")
assert(not love.mouse.isDown(1), "soltar A deja de arrastrar")
botones_raton[1] = true
assert(love.mouse.isDown(1), "el mouse real sigue funcionando")
botones_raton[1] = nil
ejes.leftx = -1
for _ = 1, 600 do
  Mando.actualizar(1 / 60, true)
end
assert(raton.x == 0, "el puntero no sale de la ventana")
ejes.leftx = 0

Mando.presionar(mando, "rightshoulder", false)
assert(love.keyboard.isDown("h"), "RB acelera como la tecla H")
Mando.soltar(mando, "rightshoulder")
assert(not love.keyboard.isDown("h"), "soltar RB deja de acelerar")

love = love_real
package.loaded["src/systems/mando"] = nil

local maquina = { current = nil }
local maquina_real = package.loaded["src/state_machine"]
package.loaded["src/state_machine"] = maquina
local Game = assert(loadfile("src/game.lua"))()
package.loaded["src/state_machine"] = maquina_real
local function nada() end
assert(Game.usa_cursor() == false, "sin pantalla no hay puntero")
maquina.current = { usa_cursor = true, keypressed = nada, mousepressed = nada }
assert(Game.usa_cursor(), "la casa pide puntero")
maquina.current = { keypressed = nada, mousepressed = nada }
assert(not Game.usa_cursor(), "una pantalla con teclado se juega con la cruceta y el stick")
maquina.current = { mousepressed = nada }
assert(Game.usa_cursor(), "una pantalla solo de mouse usa el puntero")
maquina.current = { usa_cursor = function(self) return self.mesa end, mesa = false }
assert(not Game.usa_cursor(), "el salon del casino se camina")
maquina.current.mesa = true
assert(Game.usa_cursor(), "las mesas del casino usan el puntero")

local casino = package.loaded["src/states/casino"]
if casino then
  assert(not casino.usa_cursor({ sub_estado = { current = nil } }), "en el salon no hay puntero")
  assert(casino.usa_cursor({ sub_estado = { current = {} } }), "en una mesa hay puntero")
  assert(not casino.usa_cursor({ sub_estado = { current = {} }, dialogo = {} }), "un aviso del casino se responde con A")
end

print("test_mando: ok")
