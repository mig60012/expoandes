-- Minimal pure-Lua bit operations used by the bundled Hold'em evaluator.
-- This keeps the legacy library working on Lua versions without LuaBitOp.
local MOD = 4294967296
local HALF = 2147483648

local function unsigned(value)
  value = value % MOD
  return value < 0 and value + MOD or value
end

local function binary_operation(a, b, operation)
  a, b = unsigned(a), unsigned(b)
  local result, place = 0, 1
  for _ = 1, 32 do
    local abit, bbit = a % 2, b % 2
    if operation(abit, bbit) then result = result + place end
    a, b = math.floor(a / 2), math.floor(b / 2)
    place = place * 2
  end
  return result
end

local bit = {}

function bit.band(a, b)
  return binary_operation(a, b, function(x, y) return x == 1 and y == 1 end)
end

function bit.bor(a, b)
  return binary_operation(a, b, function(x, y) return x == 1 or y == 1 end)
end

function bit.bxor(a, b)
  return binary_operation(a, b, function(x, y) return x ~= y end)
end

function bit.lshift(value, shift)
  return unsigned(unsigned(value) * (2 ^ shift))
end

function bit.rshift(value, shift)
  return math.floor(unsigned(value) / (2 ^ shift))
end

return { bit = bit }
