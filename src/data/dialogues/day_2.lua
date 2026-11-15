return {
  id = "day_2",
  start = "morning_route",
  nodes = {
    morning_route = {
      routes = {
        {
          condition = {
            type = "outcome",
            key = "N1",
            value = "A",
          },
          next = "family_morning",
        },
        {
          next = "absence_morning",
        },
      },
    },
    family_morning = {
      speaker = "Esposa",
      text = "Qué bueno que llegaste temprano anoche.",
      next = "daughter_morning",
    },
    daughter_morning = {
      speaker = "Hija",
      text = "Te extraño cuando no estás.",
      next = "daughter_response",
    },
    daughter_response = {
      speaker = "Hija",
      text = "¿Qué piensas, papá?",
      choices = {
        {
          text = "Yo también, pequeña. Ya era hora de compartir. Lo siento por no estar tan presente.",
          next = "family_response",
          effects = {
            { type = "add_value", key = "family_points", amount = 1 },
          },
        },
        {
          text = "No prometo poder hacerlo seguido, tengo mucho trabajo.",
          next = "family_response",
        },
      },
    },
    family_response = {
      speaker = "Hija",
      text = "Gracias por hablar conmigo.",
      next = "morning_finished",
    },
    absence_morning = {
      speaker = "Esposa",
      text = "¿Mucho trabajo anoche?",
      next = "absence_response",
    },
    absence_response = {
      speaker = "Protagonista",
      text = "Sí, lo siento de nuevo.",
      next = "absence_finished",
    },
    absence_finished = {
      speaker = "Hija",
      text = "Ya se está volviendo costumbre.",
      next = "morning_finished",
    },
    morning_finished = {
      text = "",
      ending = true,
    },
  },
}
