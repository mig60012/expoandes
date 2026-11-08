local Progress = {}
Progress.__index = Progress

local function copy_values(values)
  local copy = {}
  for key, value in pairs(values or {}) do
    copy[key] = value
  end
  return copy
end

function Progress.new(defaults)
  defaults = defaults or {}

  return setmetatable({
    flags = copy_values(defaults.flags),
    values = copy_values(defaults.values),
  }, Progress)
end

function Progress:has_flag(key)
  return self.flags[key] ~= nil
end

function Progress:get_flag(key)
  return self.flags[key]
end

function Progress:set_flag(key, value)
  assert(type(value) == "boolean", "Flag must be boolean: " .. tostring(key))
  self.flags[key] = value
end

function Progress:has_value(key)
  return self.values[key] ~= nil
end

function Progress:get_value(key)
  return self.values[key]
end

function Progress:set_value(key, value)
  assert(type(value) == "number", "Value must be numeric: " .. tostring(key))
  self.values[key] = value
end

function Progress:add_value(key, amount)
  assert(type(amount) == "number", "Amount must be numeric: " .. tostring(key))
  assert(self:has_value(key), "Unknown progress value: " .. tostring(key))
  self.values[key] = self.values[key] + amount
end

return Progress
