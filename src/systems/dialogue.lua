Dialogue = OBJECT:extend()

function Dialogue:new(filename)
  local content = io.open("data/dialogues/" .. filename)
  --TODO
end

return Dialogue
