local Progress = require("src/systems/progress")
local Economy = require("src/systems/economy")
local DayFlow = require("src/systems/day_flow")
local Story = require("src/story")
local Data = require("src/data/dialogues/historia")
local View = require("src/ui/story_dialogue")
local Validator = require("src/systems/dialogue_validator")
local Evaluate = require("src/systems/final_evaluation")
local original_love = love
local font = {
  getHeight = function() return 20 end,
  getWrap = function(_, text, width)
    local lines, line = {}, ""
    for word in text:gmatch("%S+") do
      if #line + #word > width / 10 and line ~= "" then lines[#lines + 1], line = line, "" end
      line = line == "" and word or line .. " " .. word
    end
    lines[#lines + 1] = line
    return width, lines
  end,
}
love = { graphics = { getDimensions = function() return 1280, 720 end, newFont = function() return font end } }
local function context()
  local c = { economy = Economy.new(10), time_of_day = 0,
    progress = Progress.new({ flags = { car_sold = false, house_mortgaged = false,
      daughter_savings_used = false, wife_knows_about_bets = false, homeless_man_saw_player = false },
      values = { current_day = 1, casino_games_today = 0, family_points = 0, debt_percentage = 0 },
      outcome_options = { N1 = {"A", "B", "C"}, N2 = {"A", "B", "C"}, N3 = {"A", "B", "C", "D"}, N5 = {"A", "B", "C"} } }),
    rules = { family_points_threshold = 5, debt_total = 125, house_sale_value = 15,
      daughter_savings_value = 10, car_sale_value = 10, work_income = 5 },
    state_machine = { switch = function(self, name) self.current_name = name end },
  }
  c.day_flow = DayFlow.new(c)
  c.day_flow:start_day(1)
  c.story = Story.new(c)
  return c
end
local function exhaust(view, select)
  local ticks = 0
  while view.active do
    ticks = ticks + 1
    assert(ticks < 1000, "un dialogo no puede atascarse")
    view:_refresh()
    assert(not view.pages[view.page]:match("\n.*\n"), "cada fragmento ocupa como maximo dos lineas")
    local choices = view.dialogue:get_choices() or {}
    if #choices > 0 and view.page == #view.pages then
      if type(select) == "number" then view.selected = select
      elseif select then
        local found
        for i, entry in ipairs(choices) do
          if entry.choice.action == select then view.selected, found = i, true end
        end
        assert(found, "opcion del guion inexistente: " .. tostring(select))
      end
    end
    view:keypressed("return")
    assert(not view.error, view.error)
  end
end
for _, group in ipairs({ Data.morning, Data.street, Data.returning, Data.endings }) do
  for _, source in pairs(group) do local ok, errors = Validator.validate(source); assert(ok, table.concat(errors, "; ")) end
end
for _, source in ipairs({Data.opening, Data.car_return, Data.confrontation, Data.economic, Data.early_return, Data.late_return, Data.work}) do
  local ok, errors = Validator.validate(source); assert(ok, table.concat(errors, "; "))
end
local plans = {
  { games = {6,6,6,6,6}, car = "keep", economic = "none", money = 10, morning = 2 },
  { games = {3,3,3,3}, activity = "family", car = "keep", economic = "daughter_savings", money = 25, morning = 1, last_work = true },
  { games = {3,6,6,6,3}, activity = "work", car = "sell_unknown", economic = "daughter_savings", money = 35, morning = 2 },
  { games = {3,3,3,3}, activity = "work", car = "sell_known", economic = "mortgage", money = 50, morning = 2, last_work = true },
  { games = {3,3,3,6,3}, activities = {"family", "work"}, car = "keep", economic = "none", money = 15, morning = 1 },
}
for _, plan in ipairs(plans) do
  local c, house = context(), {}
  for day = 1, 5 do
    assert(c.day_flow:get_day() == day)
    assert(c.progress:get_value("casino_games_today") == 0, "cada dia reinicia la cuota, no la historia")
    assert(not c.progress:get_flag("casino_extra_games_accepted"))
    c.story:enter_house(house)
    exhaust(house.dialogue, day == 5 and (plan.last_work and "work" or "casino") or plan.morning)
    assert(c.day_flow.decisions.morning_complete)
    if day == 5 and plan.last_work then c.story:work_complete()
    else
      exhaust(View.new(c, c.story:street(true)))
      assert(c.story:street(true) == nil, "el paseo no repite encuentros ni elecciones")
      assert(c.day_flow:record_games(plan.games[day]), "record_games confirma su resultado al casino")
      c.time_of_day = plan.games[day] == 6 and 2 or 1
      exhaust(View.new(c, c.story:street(false)))
    end
    c.story:enter_house(house)
    local option = day <= 2 and (plan.activities and plan.activities[day] or plan.activity)
      or day == 3 and plan.car or day == 4 and 2 or plan.economic
    exhaust(house.dialogue, option)
    if day <= 2 and plan.games[day] == 3 and option == "work" then c.story:work_complete() end
  end
  assert(c.state_machine.current_name == "finales" and c.day_flow.finished)
  assert(c.economy:get_money() == plan.money, "saldo esperado " .. plan.money .. ", obtenido " .. c.economy:get_money())
  assert(Evaluate.evaluate(c) == "final_1", "menos de la mitad de 125 M mantiene el primer final")
  assert(c.progress:get_flag("car_sold") == (plan.car ~= "keep"))
  assert(c.progress:get_flag("wife_knows_about_bets"), "la esposa descubre las apuestas el dia cuatro")
  exhaust(View.new(c, Data.endings.final_1, nil, { black = true }))
end
local c = context()
local source = { start = "texto", nodes = { texto = { speaker = "Hija", text = ("Una frase muy larga. "):rep(80),
  choices = { { text = "Responder", effects = { {type="add_value", key="family_points", amount=1} } } } } } }
local view = View.new(c, source)
view:_refresh()
assert(#view.pages > 1)
view:keypressed("return", nil, true)
assert(view.page == 1, "mantener una tecla no salta paginas")
view:keypressed("space")
assert(c.progress:get_value("family_points") == 0, "no aplica una eleccion antes de leer el texto")
exhaust(view, 1)
view:keypressed("return")
assert(c.progress:get_value("family_points") == 1, "no duplica efectos al terminar")
for _, size in ipairs({{800,600}, {1280,720}, {1920,1080}, {720,1280}}) do
  local layout = View.layout(size[1], size[2], 3)
  for _, rect in ipairs(layout.portraits) do
    assert(math.abs(rect.y + rect.h - layout.panel.y) < 0.001, "los personajes se apoyan sobre el cuadro de texto")
  end
  assert(layout.portraits[1].x + layout.portraits[1].w < layout.portraits[2].x, "los personajes ocupan lados diferentes")
  local last = layout.choices[3]
  assert(last.y + last.h <= layout.panel.y + layout.panel.h, "tres opciones caben dentro del cuadro")
end
love = original_love
print("Historia: five days, all endings, decisions, two-line pages and unobstructed pairs: ok")
