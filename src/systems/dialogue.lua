local Dialogue = {}
Dialogue.__index = Dialogue

function Dialogue.new(filename)
  local dialogue = setmetatable({ lines = {}, current = 1 }, Dialogue)

  if filename then
    local content = love.filesystem.read("src/data/dialogues/" .. filename)
    if content then
      for line in content:gmatch("[^\r\n]+") do
        dialogue.lines[#dialogue.lines + 1] = line
      end
    end
  end

  return dialogue
end

function Dialogue:current_line()
  return self.lines[self.current]
end

function Dialogue:next()
  if self.current >= #self.lines then
    return false
  end

  self.current = self.current + 1
  return true
end

return Dialogue
