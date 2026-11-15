local Progress = {}
Progress.__index = Progress

local function copy_values(values)
  local copy = {}
  for key, value in pairs(values or {}) do
    copy[key] = value
  end
  return copy
end

local function copy_options(options)
  local copy = {}
  for key, values in pairs(options or {}) do
    copy[key] = copy_values(values)
  end
  return copy
end

function Progress.new(defaults)
  defaults = defaults or {}

  local progress = setmetatable({
    defaults = {
      flags = copy_values(defaults.flags),
      values = copy_values(defaults.values),
      outcome_options = copy_options(defaults.outcome_options),
    },
    flags = {},
    values = {},
    outcomes = {},
  }, Progress)
  progress:reset()
  return progress
end

function Progress:reset()
  self.flags = copy_values(self.defaults.flags)
  self.values = copy_values(self.defaults.values)
  self.outcomes = {}
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

function Progress:has_outcome(key)
  return self.defaults.outcome_options[key] ~= nil
end

function Progress:get_outcome(key)
  assert(self:has_outcome(key), "Unknown progress outcome: " .. tostring(key))
  return self.outcomes[key]
end

function Progress:set_outcome(key, value)
  assert(self:has_outcome(key), "Unknown progress outcome: " .. tostring(key))

  local allowed_values = self.defaults.outcome_options[key]
  local allowed = false
  for _, allowed_value in ipairs(allowed_values) do
    if allowed_value == value then
      allowed = true
      break
    end
  end

  assert(allowed, "Invalid value for " .. tostring(key) .. ": " .. tostring(value))
  self.outcomes[key] = value
end

return Progress
