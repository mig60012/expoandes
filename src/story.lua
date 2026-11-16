-- Coordinacion narrativa. Conserva DayFlow/StoryOutcomes como unica autoridad
-- para N1/N2/N3/N5 y los efectos del motor Dialogue para las elecciones.
local Data = require("src/data/dialogues/historia")
local View = require("src/ui/story_dialogue")
local Story = {}
Story.__index = Story

function Story.new(context)
  return setmetatable({ context = context, visited_street = {} }, Story)
end

function Story:play(house, source, callback)
  house.dialogue = View.new(self.context, source, function(view, choice)
    house.dialogue = nil
    if callback then callback(choice, view) end
  end, { portrait_mode = "house" })
  house.dialogue.width, house.dialogue.height = 1280, 720
end

function Story:finish_day()
  local context, flow = self.context, self.context.day_flow
  local ok, err = flow:finish_day()
  assert(ok, err)
  if flow:get_day() == 5 then
    context.state_machine:switch("finales")
  else
    assert(flow:advance_after_finished_day())
    context.time_of_day = 0
    context.state_machine:switch("casa")
  end
end

function Story:enter_house(house)
  local context, flow = self.context, self.context.day_flow
  if not flow:is_active() then return end
  local day, games = flow:get_day(), flow.decisions.games
  if not flow.decisions.morning_complete then
    self:play(house, Data.morning[day], function(choice)
      flow:mark_morning_complete()
      if day == 4 and context.progress:get_outcome("N3") == "C" then
        context.progress:add_value("family_points", -1)
      end
      if day == 5 and choice then
        if choice.action == "work" then context.state_machine:switch("trabajo")
        else context.state_machine:switch("transicion", true) end
      end
    end)
  elseif day == 5 and (games or flow.decisions.worked) then
    self:play(house, Data.economic, function(choice)
      local ok, err = flow:record_economic_decision(assert(choice and choice.action))
      assert(ok, err)
      self:finish_day()
    end)
  elseif day == 4 and games then
    self:play(house, Data.confrontation, function()
      context.progress:set_flag("wife_knows_about_bets", true)
      self:finish_day()
    end)
  elseif day == 3 and games then
    self:play(house, Data.car_return, function(choice)
      local decision = assert(choice and choice.action)
      local ok, err = flow:record_car_decision(decision)
      assert(ok, err)
      self:finish_day()
    end)
  elseif (day == 1 or day == 2) and games == 3 then
    self:play(house, Data.early_return, function(choice)
      if choice.action == "work" then context.state_machine:switch("trabajo")
      else flow:record_family_time(); self:finish_day() end
    end)
  elseif (day == 1 or day == 2) and games == 6 then
    self:play(house, Data.late_return, function() self:finish_day() end)
  end
end

function Story:street(from_house)
  local context, flow = self.context, self.context.day_flow
  if not flow:is_active() then return nil end
  local day, games = flow:get_day(), flow.decisions.games
  local key = day .. (from_house and ":out" or ":back")
  if self.visited_street[key] then return nil end
  self.visited_street[key] = true
  if from_house then return Data.street[day] end
  if day == 5 then return Data.returning[5] end
  if games == 6 then return Data.night_street end
  if games == 3 then
    context.progress:set_flag("homeless_man_saw_player", day <= 3)
    return Data.returning[day]
  end
end

function Story:work_complete()
  local context, flow = self.context, self.context.day_flow
  flow:record_work()
  context.economy:add_money(context.rules.work_income or 0)
  if flow:get_day() == 5 then
    context.time_of_day = 2
    context.state_machine:switch("casa")
  else self:finish_day() end
end

function Story:request_work(house)
  -- Los dias 1/2 ofrecen el trabajo al volver del casino; el dia 5 lo decide
  -- expresamente el dialogo de la hija. No permite saltarse esos encuentros.
  local source = { lines = { "Primero tengo que salir. El casino me espera; necesito pagar esta deuda." } }
  self:play(house, source)
end

function Story:inspect_photo(house)
  self:play(house, { start = "foto", nodes = { foto = { speaker = "Protagonista",
    text = "Es por ella que hago todo esto. No puedo seguir prometiendo cosas que no cumplo.", partner = false, ending = true } } })
end

return Story
