local Economy = {}
Economy.__index = Economy

function Economy.new(initial_money)
  return setmetatable({ money = initial_money or 0 }, Economy)
end

function Economy:get_money()
  return self.money
end

function Economy:add_money(amount)
  assert(amount >= 0, "Amount must not be negative")
  self.money = self.money + amount
end

function Economy:spend_money(amount)
  assert(amount >= 0, "Amount must not be negative")
  if self.money < amount then
    return false
  end

  self.money = self.money - amount
  return true
end

return Economy
