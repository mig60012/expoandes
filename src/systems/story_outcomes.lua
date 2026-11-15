local StoryOutcomes = {}

local function resolve_standard_day(context, outcome_key, decisions)
  if not context or not context.progress then
    return false, "context.progress is required"
  end
  if type(decisions) ~= "table" then
    return false, "day decisions must be a table"
  end
  if type(decisions.games) ~= "number" then
    return false, "games must be numeric"
  end

  local outcome
  if decisions.games == 6 then
    outcome = "C"
  elseif decisions.games == 3 then
    local with_family = decisions.spent_time_with_family == true
    local worked = decisions.worked == true
    if with_family == worked then
      return false, "three games require exactly one final activity: family or work"
    end
    outcome = with_family and "A" or "B"
  else
    return false, "games must be either 3 or 6"
  end

  local ok, err = pcall(function()
    context.progress:set_outcome(outcome_key, outcome)
  end)
  if not ok then
    return false, err
  end
  return true, outcome
end

function StoryOutcomes.resolve_n1(context, decisions)
  return resolve_standard_day(context, "N1", decisions)
end

-- N2 follows the same rules as N1 and can use this function when that day is
-- implemented. Keeping the shared rule here avoids duplicating the mapping.
function StoryOutcomes.resolve_n2(context, decisions)
  return resolve_standard_day(context, "N2", decisions)
end

function StoryOutcomes.resolve_n3(context, decisions)
  if not context or not context.progress then
    return false, "context.progress is required"
  end
  if type(decisions) ~= "table" then
    return false, "day decisions must be a table"
  end
  if type(decisions.games) ~= "number" then
    return false, "games must be numeric"
  end
  if type(decisions.car_sold) ~= "boolean" then
    return false, "car_sold must be boolean"
  end

  local outcome
  if decisions.games == 3 then
    if decisions.car_sold then
      if decisions.wife_knows_about_car ~= true then
        return false, "N3 = A requires the wife to know about the car"
      end
      outcome = "A"
    else
      outcome = "B"
    end
  elseif decisions.games == 6 then
    if decisions.car_sold then
      if decisions.wife_knows_about_car == true then
        return false, "N3 = C requires the wife not to know about the car"
      end
      outcome = "C"
    else
      outcome = "D"
    end
  else
    return false, "games must be either 3 or 6"
  end

  local ok, err = pcall(function()
    context.progress:set_outcome("N3", outcome)
  end)
  if not ok then
    return false, err
  end
  return true, outcome
end

function StoryOutcomes.resolve_n5(context, decision)
  if not context or not context.progress then
    return false, "context.progress is required"
  end
  if type(decision) ~= "string" then
    return false, "economic decision must be a string"
  end

  local outcomes = {
    mortgage = "A",
    daughter_savings = "B",
    none = "C",
  }
  local outcome = outcomes[decision]
  if not outcome then
    return false, "Unknown economic decision: " .. decision
  end

  local ok, err = pcall(function()
    context.progress:set_outcome("N5", outcome)
  end)
  if not ok then
    return false, err
  end
  return true, outcome
end

return StoryOutcomes
