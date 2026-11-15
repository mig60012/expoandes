local FinalEvaluation = {}

function FinalEvaluation.evaluate(context)
  local percentage = context.progress:get_value("debt_percentage") or 0
  local threshold = (context.rules and context.rules.family_points_threshold) or 2
  local points = context.progress:get_value("family_points") or 0

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
