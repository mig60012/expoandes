local Conditions = {}

local operators = {
  ["=="] = function(left, right) return left == right end,
  ["~="] = function(left, right) return left ~= right end,
  [">"] = function(left, right) return left > right end,
  [">="] = function(left, right) return left >= right end,
  ["<"] = function(left, right) return left < right end,
  ["<="] = function(left, right) return left <= right end,
}

local function invalid(message)
  return false, "Invalid condition: " .. message
end

function Conditions.evaluate(condition, context)
  if condition == nil then
    return true
  end

  if type(condition) ~= "table" then
    return invalid("expected a table")
  end

  local progress = context and context.progress
  if not progress then
    return invalid("context.progress is required")
  end

  if condition.type == "flag" then
    if type(condition.key) ~= "string" or type(condition.value) ~= "boolean" then
      return invalid("flag requires a string key and boolean value")
    end
    if not progress:has_flag(condition.key) then
      return invalid("unknown flag '" .. condition.key .. "'")
    end
    return progress:get_flag(condition.key) == condition.value
  end

  if condition.type == "value" then
    local compare = operators[condition.operator]
    if type(condition.key) ~= "string" or not compare or type(condition.value) ~= "number" then
      return invalid("value requires a key, supported operator and numeric value")
    end
    if not progress:has_value(condition.key) then
      return invalid("unknown value '" .. condition.key .. "'")
    end
    return compare(progress:get_value(condition.key), condition.value)
  end

  if condition.type == "all" or condition.type == "any" then
    if type(condition.conditions) ~= "table" then
      return invalid(condition.type .. " requires a conditions table")
    end

    local expected = condition.type == "all"
    local result = condition.type == "all"
    for _, child in ipairs(condition.conditions) do
      local matches, err = Conditions.evaluate(child, context)
      if err then
        return false, err
      end
      if condition.type == "all" then
        result = result and matches
      else
        result = result or matches
      end
    end
    return result
  end

  return invalid("unknown type '" .. tostring(condition.type) .. "'")
end

return Conditions
