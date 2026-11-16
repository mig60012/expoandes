local FinalEvaluation = {}

function FinalEvaluation.debt_percentage(context)
  local debt = (context.rules and context.rules.debt_total) or 125
  assert(debt > 0, "Debt total must be greater than zero")
  local money = context.economy and context.economy:get_money()
  if money == nil then
    -- Compatibilidad con escenas o pruebas antiguas sin sistema economico.
    return context.progress:get_value("debt_percentage") or 0
  end
  return math.min(100, math.max(0, money / debt * 100))
end

function FinalEvaluation.evaluate(context)
  local percentage = FinalEvaluation.debt_percentage(context)
  local threshold = (context.rules and context.rules.family_points_threshold) or 5
  local points = context.progress:get_value("family_points") or 0
  if context.progress:has_value("debt_percentage") then
    context.progress:set_value("debt_percentage", percentage)
  end

  if percentage >= 100 then
    return "final_4"
  elseif percentage < 50 then
    return "final_1"
  elseif points >= threshold then
    return "final_2"
  end
  return "final_3"
end

return FinalEvaluation
