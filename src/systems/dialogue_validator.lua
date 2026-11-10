local Validator = {}

local function add_error(errors, location, message)
  errors[#errors + 1] = location .. ": " .. message
end

local function validate_condition_shape(condition, errors, location)
  if condition == nil then return end
  if type(condition) ~= "table" then
    add_error(errors, location, "condition must be a table")
    return
  end
  if type(condition.type) ~= "string" then
    add_error(errors, location, "condition requires a type")
  end
end

local function validate_effects_shape(effects, errors, location)
  if effects == nil then return end
  if type(effects) ~= "table" then
    add_error(errors, location, "effects must be a table")
    return
  end
  for index, effect in ipairs(effects) do
    local effect_location = string.format("%s.effects[%d]", location, index)
    if type(effect) ~= "table" or type(effect.type) ~= "string" then
      add_error(errors, effect_location, "effect requires a type")
    end
  end
end

function Validator.validate(data)
  local errors = {}

  if type(data) ~= "table" then
    return false, { "dialogue data must be a table" }
  end

  if data.lines then
    if type(data.lines) ~= "table" then
      add_error(errors, "lines", "must be a table")
    end
    return #errors == 0, errors
  end

  if type(data.nodes) ~= "table" then
    add_error(errors, "nodes", "must be a table")
    return false, errors
  end
  if type(data.start) ~= "string" then
    add_error(errors, "start", "must be a node id")
  elseif not data.nodes[data.start] then
    add_error(errors, "start", "references an unknown node '" .. data.start .. "'")
  end

  for node_id, node in pairs(data.nodes) do
    local location = "nodes." .. tostring(node_id)
    if type(node) ~= "table" then
      add_error(errors, location, "must be a table")
    else
      if node.next ~= nil then
        if type(node.next) ~= "string" then
          add_error(errors, location .. ".next", "must be a node id")
        elseif not data.nodes[node.next] then
          add_error(errors, location .. ".next", "references unknown node '" .. node.next .. "'")
        end
      end

      validate_condition_shape(node.condition, errors, location)

      if node.choices and node.routes then
        add_error(errors, location, "cannot contain both choices and routes")
      end

      if node.choices then
        if type(node.choices) ~= "table" then
          add_error(errors, location .. ".choices", "must be a table")
        else
          for index, choice in ipairs(node.choices) do
            local choice_location = string.format("%s.choices[%d]", location, index)
            if type(choice) ~= "table" then
              add_error(errors, choice_location, "must be a table")
            else
              if type(choice.text) ~= "string" then
                add_error(errors, choice_location .. ".text", "must be a string")
              end
              if choice.next ~= nil then
                if type(choice.next) ~= "string" then
                  add_error(errors, choice_location .. ".next", "must be a node id")
                elseif not data.nodes[choice.next] then
                  add_error(errors, choice_location .. ".next", "references unknown node '" .. choice.next .. "'")
                end
              end
              validate_condition_shape(choice.condition, errors, choice_location)
              validate_effects_shape(choice.effects, errors, choice_location)
            end
          end
        end
      end

      if node.routes then
        if type(node.routes) ~= "table" then
          add_error(errors, location .. ".routes", "must be a table")
        else
          for index, route in ipairs(node.routes) do
            local route_location = string.format("%s.routes[%d]", location, index)
            if type(route) ~= "table" then
              add_error(errors, route_location, "must be a table")
            else
              if type(route.next) ~= "string" then
                add_error(errors, route_location .. ".next", "must be a node id")
              elseif not data.nodes[route.next] then
                add_error(errors, route_location .. ".next", "references unknown node '" .. route.next .. "'")
              end
              validate_condition_shape(route.condition, errors, route_location)
            end
          end
        end
      end
    end
  end

  return #errors == 0, errors
end

return Validator
