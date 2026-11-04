--[[
-- El state machine es el encargado de cambiar el gamestate
--]]

local state_machine = {}

-- Aqui se cargan todos los States
function state_machine.load()
  state_machine.casa = require("src/casa")
  state_machine.casino = require("src/casino")
  state_machine.transicion = require("src/transicion")
  state_machine.animacion = require("src/animacion")
end

function state_machine.update()
end

return state_machine
