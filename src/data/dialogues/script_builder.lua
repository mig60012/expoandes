-- Solo construye datos: las condiciones y los efectos siguen perteneciendo
-- al motor Dialogue y a los servicios de decisiones existentes.
local Builder = {}
Builder.__index = Builder

function Builder.new(id)
  return setmetatable({ data = { id = id, nodes = {} } }, Builder)
end

function Builder:scene(id, lines, destination)
  for index, line in ipairs(lines) do
    local key = index == 1 and id or id .. "_" .. index
    local next_id = index < #lines and id .. "_" .. (index + 1) or destination
    self.data.nodes[key] = { speaker = line[1], text = line[2], partner = line[3],
      next = next_id, ending = next_id == nil }
  end
  return self
end

function Builder:choice(id, text, choices)
  self.data.nodes[id] = { speaker = "Protagonista", text = text, choices = choices }
  return self
end

function Builder:route(id, routes)
  self.data.nodes[id] = { routes = routes }
  return self
end

function Builder:build(start)
  self.data.start = start
  return self.data
end

return Builder
