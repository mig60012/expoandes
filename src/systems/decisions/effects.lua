local Effects = {}

local function valid_amount(effect)
  return type(effect.amount) == "number" and effect.amount >= 0
end

local function validate(effect, context)
  if type(effect) ~= "table" then
    return false, "Effect must be a table"
  end

  local progress = context and context.progress
  if not progress then
    return false, "context.progress is required"
  end

  if effect.type == "set_flag" then
    if type(effect.key) ~= "string" or type(effect.value) ~= "boolean" then
      return false, "set_flag requires a string key and boolean value"
    end
    if not progress:has_flag(effect.key) then
      return false, "Unknown flag '" .. effect.key .. "'"
    end
  elseif effect.type == "set_value" then
    if type(effect.key) ~= "string" or type(effect.value) ~= "number" then
      return false, "set_value requires a string key and numeric value"
    end
    if not progress:has_value(effect.key) then
      return false, "Unknown value '" .. effect.key .. "'"
    end
  elseif effect.type == "add_value" then
    if type(effect.key) ~= "string" or type(effect.amount) ~= "number" then
      return false, "add_value requires a string key and numeric amount"
    end
    if not progress:has_value(effect.key) then
      return false, "Unknown value '" .. effect.key .. "'"
    end
  elseif effect.type == "add_money" or effect.type == "spend_money" then
    if not context.economy or not valid_amount(effect) then
      return false, effect.type .. " requires a non-negative numeric amount and economy"
    end
  else
    return false, "Unknown effect type '" .. tostring(effect.type) .. "'"
  end

  return true
end

function Effects.apply(effect, context)
  local valid, err = validate(effect, context)
  if not valid then
    return false, err
  end

  if effect.type == "set_flag" then
    context.progress:set_flag(effect.key, effect.value)
  elseif effect.type == "set_value" then
    context.progress:set_value(effect.key, effect.value)
  elseif effect.type == "add_value" then
    context.progress:add_value(effect.key, effect.amount)
  elseif effect.type == "add_money" then
    context.economy:add_money(effect.amount)
  elseif effect.type == "spend_money" then
    if not context.economy:spend_money(effect.amount) then
      return false, "Not enough money"
    end
  end

  return true
end

function Effects.apply_all(effects, context)
  if effects == nil then
    return true
  end
  if type(effects) ~= "table" then
    return false, "Effects must be a table"
  end

  local simulated_money = context.economy and context.economy:get_money() or nil
  for _, effect in ipairs(effects) do
    local valid, err = validate(effect, context)
    if not valid then
      return false, err
    end
    if effect.type == "spend_money" then
      simulated_money = simulated_money - effect.amount
      if simulated_money < 0 then
        return false, "Not enough money"
      end
    elseif effect.type == "add_money" then
      simulated_money = simulated_money + effect.amount
    end
  end

  for _, effect in ipairs(effects) do
    local applied, err = Effects.apply(effect, context)
    if not applied then
      return false, err
    end
  end
  return true
end

return Effects
