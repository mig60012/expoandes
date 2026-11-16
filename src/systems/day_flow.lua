local StoryOutcomes = require("src/systems/story_outcomes")

local DayFlow = {}
DayFlow.__index = DayFlow

local LAST_DAY = 5

function DayFlow.new(context)
  assert(context and context.progress, "DayFlow requires context.progress")
  return setmetatable({
    context = context,
    day = nil,
    decisions = {},
    finished = false,
  }, DayFlow)
end

function DayFlow:start_day(day)
  assert(type(day) == "number" and day >= 1 and day <= LAST_DAY,
    "Day must be between 1 and " .. LAST_DAY)

  self.day = day
  self.decisions = {}
  self.finished = false
  self.context.progress:set_value("current_day", day)
  self.context.progress:set_value("casino_games_today", 0)
  self.context.progress:set_flag("casino_decision_made", false)
  self.context.progress:set_flag("casino_extra_games_accepted", false)
end

function DayFlow:is_active()
  return self.day ~= nil and not self.finished
end

function DayFlow:get_day()
  return self.day
end

function DayFlow:record(key, value)
  assert(self:is_active(), "There is no active day")
  assert(type(key) == "string", "Decision key must be a string")
  self.decisions[key] = value
end

function DayFlow:record_games(games)
  assert(self:is_active(), "There is no active day")
  assert(games == 3 or games == 6, "Games must be either 3 or 6")
  self.decisions.games = games
  -- Con tres partidas todavía existe tiempo para la familia. La elección de
  -- trabajar puede sobrescribirlo mediante record_work(). Con seis partidas
  -- el protagonista pasa todo el día en el casino.
  self.decisions.spent_time_with_family = games == 3
  self.decisions.worked = false
  self.context.progress:set_value("casino_games_today", games)
  return true, games
end

function DayFlow:record_work()
  assert(self:is_active(), "There is no active day")
  if self.decisions.worked then
    return
  end
  self.decisions.worked = true
  self.decisions.spent_time_with_family = false
end

function DayFlow:record_family_time()
  assert(self:is_active(), "There is no active day")
  self.decisions.spent_time_with_family = true
  self.decisions.worked = false
end

function DayFlow:mark_morning_complete()
  assert(self:is_active(), "There is no active day")
  self.decisions.morning_complete = true
end

function DayFlow:record_return_home()
  assert(self:is_active(), "There is no active day")
  self:record_family_time()
  return self:finish_day()
end

function DayFlow:record_economic_decision(decision)
  assert(self.day == 5, "Economic decision belongs to day 5")
  if self.decisions.economic_decision then
    return false, "Economic decision was already recorded"
  end
  local ok, result = StoryOutcomes.resolve_n5(self.context, decision)
  if not ok then
    return false, result
  end
  self.decisions.economic_decision = decision
  local rules = self.context.rules or {}
  local proceeds = {
    mortgage = rules.house_sale_value or 15,
    daughter_savings = rules.daughter_savings_value or 10,
    none = 0,
  }
  if decision == "mortgage" then self.context.progress:set_flag("house_mortgaged", true) end
  if decision == "daughter_savings" then self.context.progress:set_flag("daughter_savings_used", true) end
  if self.context.economy then self.context.economy:add_money(proceeds[decision]) end
  return true, result
end

function DayFlow:record_car_decision(decision)
  assert(self.day == 3, "Car decision belongs to day 3")
  if self.decisions.car_decision then return false, "Car decision was already recorded" end
  assert(decision == "sell_known" or decision == "sell_unknown" or decision == "keep",
    "Unknown car decision: " .. tostring(decision))

  local games = self.decisions.games or self.context.progress:get_value("casino_games_today")
  local sold = decision ~= "keep"
  local wife_knows = decision == "sell_known"
  if decision == "sell_known" and games ~= 3 then
    return false, "Selling with an informed wife requires 3 games"
  end
  if decision == "sell_unknown" and games ~= 6 then
    return false, "Selling without telling the wife requires 6 games"
  end

  self.decisions.car_sold = sold
  self.decisions.wife_knows_about_car = wife_knows
  local ok, result = StoryOutcomes.resolve_n3(self.context, self.decisions)
  if not ok then
    return false, result
  end
  self.decisions.car_decision = decision
  self.context.progress:set_flag("car_sold", sold)
  if sold and self.context.economy then
    self.context.economy:add_money((self.context.rules or {}).car_sale_value or 10)
  end
  return true, result
end

function DayFlow:finish_day()
  assert(self:is_active(), "There is no active day")

  local ok, result
  if self.day == 1 then
    ok, result = StoryOutcomes.resolve_n1(self.context, self.decisions)
  elseif self.day == 2 then
    ok, result = StoryOutcomes.resolve_n2(self.context, self.decisions)
  elseif self.day == 3 then
    ok, result = StoryOutcomes.resolve_n3(self.context, self.decisions)
  elseif self.day == 5 and not self.context.progress:get_outcome("N5") then
    return false, "Day 5 requires an economic decision before finishing"
  else
    ok, result = true, nil
  end

  if not ok then
    return false, result
  end

  self.finished = true
  return true, result
end

function DayFlow:start_next_day()
  assert(self.finished, "The current day must be finished first")
  assert(self.day < LAST_DAY, "There are no more days")
  self:start_day(self.day + 1)
end

function DayFlow:advance_after_finished_day()
  assert(self.finished, "The current day must be finished first")
  if self.day == LAST_DAY then
    return false, "The story has reached its last day"
  end
  self:start_next_day()
  return true, self.day
end

return DayFlow
