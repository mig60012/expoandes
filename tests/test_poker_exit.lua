local original_love = love
love = {
  graphics = {
    newImage = function() return {} end,
    getDimensions = function() return 1280, 720 end,
  },
}
local Poker = assert(loadfile("src/states/casino/poker/poker.lua"))()
local salidas, jugadas = 0, 0
local poker = setmetatable({
  machine = { switch = function(_, name) assert(name == nil); salidas = salidas + 1 end },
  opciones = { al_jugar = function() jugadas = jugadas + 1 end },
  jugada_registrada = false,
  session_finished = false,
  collecting_chips = false,
  input_lock = 0,
  botones = {},
  game = { status = "showdown", is_human_turn = function() return false end },
}, { __index = Poker })

for mano = 1, 3 do
  poker.game.hand_number = mano
  poker:keypressed("escape")
  assert(salidas == 0, "Esc no abandona una sesion incompleta, ni al empezar la tercera mano")
  assert(not poker:salir(), "la salida comun tambien esta bloqueada")
  poker:registrar_jugada_si_termino()
  poker:actualizar_botones()
  for _, boton in ipairs(poker.botones) do
    assert(boton.label ~= "LEAVE", "no ofrece LEAVE antes de completar tres manos")
  end
end
assert(jugadas == 0, "una sesion sin terminar no cuenta como juego")
poker.session_finished = true
poker.collecting_chips = true
poker:registrar_jugada_si_termino()
poker:registrar_jugada_si_termino()
assert(jugadas == 1, "la sesion de tres manos cuenta exactamente una vez")
poker:keypressed("escape")
assert(salidas == 0, "espera a terminar la recogida de fichas")
poker.collecting_chips = false
poker:keypressed("escape")
assert(salidas == 1, "Esc permite salir tras completar el juego")
poker:actualizar_botones()
assert(#poker.botones == 1 and poker.botones[1].label == "LEAVE")
local leave_button = poker.botones[1]
poker.session_finished, poker.jugada_registrada = false, false
leave_button.action()
assert(salidas == 1, "incluso una accion LEAVE antigua respeta el bloqueo de la nueva sesion")
poker.session_finished, poker.jugada_registrada = true, true
leave_button.action()
assert(salidas == 2, "LEAVE usa la misma salida validada que Esc")
love = original_love
print("poker exit lock: ok")
