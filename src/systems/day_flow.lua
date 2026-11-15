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
end

function DayFlow:record_work()
  assert(self:is_active(), "There is no active day")
  self.decisions.worked = true
  self.decisions.spent_time_with_family = false
end

function DayFlow:record_family_time()
  assert(self:is_active(), "There is no active day")
  self.decisions.spent_time_with_family = true
  self.decisions.worked = false
end

function DayFlow:record_return_home()
  assert(self:is_active(), "There is no active day")
  self:record_family_time()
  return self:finish_day()
end

function DayFlow:record_economic_decision(decision)
  assert(self.day == 5, "Economic decision belongs to day 5")
  local ok, result = StoryOutcomes.resolve_n5(self.context, decision)
  if not ok then
    return false, result
  end
  self.decisions.economic_decision = decision
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
