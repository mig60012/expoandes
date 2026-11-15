local paths = { "src/state_machine", "src/states/casa", "src/states/trabajo",
  "src/states/casino", "src/states/transicion", "src/states/animacion" }
local originals = {}
for _, path in ipairs(paths) do originals[path] = package.loaded[path] end
local entered = {}
for i = 2, #paths do
  local name = paths[i]
  package.loaded[name] = { enter = function() entered[#entered + 1] = name end }
end
local machine = assert(loadfile("src/state_machine.lua"))()
package.loaded["src/state_machine"] = machine
local Game = assert(loadfile("src/game.lua"))()
Game.load()
assert(machine.current_name == "animacion" and entered[1] == "src/states/animacion" and #entered == 1,
  "la partida empieza con el prologo, sin abrir el casino ni blackjack")
assert(Game.context.time_of_day == 0, "la partida empieza de dia")
assert(Game.context.economy:get_money() == 10, "la partida entrega capital inicial jugable")
for _, path in ipairs(paths) do package.loaded[path] = originals[path] end
print("daytime house startup: ok")
