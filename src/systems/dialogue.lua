local Conditions = require("src/systems/decisions/conditions")
local Effects = require("src/systems/decisions/effects")

local Dialogue = {}
Dialogue.__index = Dialogue

local function read_text(filename)
  if love and love.filesystem then
    return love.filesystem.read(filename)
  end

  local file = io.open(filename, "r")
  if not file then
    return nil, "Could not read dialogue file: " .. filename
  end
  local content = file:read("*a")
  file:close()
  return content
end

local function load_data(source)
  if type(source) == "table" then
    return source
  end
  if type(source) ~= "string" then
    return nil, "Dialogue source must be a table or filename"
  end

  if source:match("%.lua$") then
    local filename = "src/data/dialogues/" .. source
    local chunk, load_error
    if love and love.filesystem then
      chunk, load_error = love.filesystem.load(filename)
    else
      chunk, load_error = loadfile(filename)
    end
    if not chunk then
      return nil, load_error
    end
    local ok, data = pcall(chunk)
    if not ok or type(data) ~= "table" then
      return nil, "Dialogue file must return a table: " .. source
    end
    return data
  end

  local content, err = read_text("src/data/dialogues/" .. source)
  if not content then
    return nil, err
  end
  local lines = {}
  for line in content:gmatch("[^\r\n]+") do
    lines[#lines + 1] = line
  end
  return { lines = lines }
end

function Dialogue.new(source, context)
  local data, err = load_data(source)
  assert(data, err)

  local dialogue = setmetatable({
    data = data,
    context = context,
    current = 1,
    current_id = data.start,
    finished = false,
    error = nil,
  }, Dialogue)

  if data.nodes then
    assert(type(data.start) == "string", "Dialogue requires a start node")
    assert(data.nodes[data.start], "Dialogue start node does not exist: " .. data.start)
    local entered, enter_error = dialogue:_can_enter(data.start)
    assert(entered, enter_error)
  elseif not data.lines then
    error("Dialogue requires nodes or lines")
  end

  return dialogue
end

function Dialogue:is_branching()
  return self.data.nodes ~= nil
end

function Dialogue:_can_enter(node_id)
  local node = self.data.nodes[node_id]
  if not node then
    return false, "Unknown dialogue node: " .. tostring(node_id)
  end
  local matches, err = Conditions.evaluate(node.condition, self.context)
  if err then
    return false, err
  end
  if not matches then
    return false, "Condition not met for dialogue node: " .. node_id
  end
  return true
end

function Dialogue:_enter(node_id)
  local can_enter, err = self:_can_enter(node_id)
  if not can_enter then
    return false, err
  end
  self.current_id = node_id
  self.finished = false
  return true
end

function Dialogue:current_node()
  if not self:is_branching() then
    return nil
  end
  return self.data.nodes[self.current_id]
end

function Dialogue:current_line()
  if self:is_branching() then
    local node = self:current_node()
    return node and node.text or nil
  end
  return self.data.lines[self.current]
end

function Dialogue:current_speaker()
  local node = self:current_node()
  return node and node.speaker or nil
end

function Dialogue:get_choices()
  if not self:is_branching() then
    return {}
  end

  local node = self:current_node()
  local choices = {}
  for index, choice in ipairs(node.choices or {}) do
    local available, err = Conditions.evaluate(choice.condition, self.context)
    if err then
      return nil, err
    end
    if available then
      choices[#choices + 1] = { index = index, choice = choice }
    end
  end
  return choices
end

function Dialogue:advance()
  if self.finished then
    return false
  end

  if not self:is_branching() then
    if self.current >= #self.data.lines then
      self.finished = true
      return false
    end
    self.current = self.current + 1
    return true
  end

  local node = self:current_node()
  if node.choices and #node.choices > 0 then
    return false, "The current dialogue node requires a choice"
  end
  if node.ending or not node.next then
    self.finished = true
    return false
  end
  return self:_enter(node.next)
end

function Dialogue:choose(visible_index)
  if self.finished or not self:is_branching() then
    return false, "There are no choices available"
  end

  local choices, choices_error = self:get_choices()
  if not choices then
    return false, choices_error
  end
  local selected = choices[visible_index]
  if not selected then
    return false, "Unknown dialogue choice: " .. tostring(visible_index)
  end

  local choice = selected.choice
  if choice.next then
    local can_enter, enter_error = self:_can_enter(choice.next)
    if not can_enter then
      return false, enter_error
    end
  end

  local applied, effect_error = Effects.apply_all(choice.effects, self.context)
  if not applied then
    return false, effect_error
  end

  if choice.next then
    return self:_enter(choice.next)
  end
  self.finished = true
  return true
end

function Dialogue:is_finished()
  return self.finished
end

return Dialogue
