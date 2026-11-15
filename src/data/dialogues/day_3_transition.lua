return {
  id = "day_3_transition",
  start = "vagabond_route",
  nodes = {
    vagabond_route = {
      routes = {
        {
          condition = {
            type = "any",
            conditions = {
              { type = "outcome", key = "N2", value = "A" },
              { type = "outcome", key = "N2", value = "B" },
            },
          },
          next = "normal_greeting",
        },
        {
          condition = {
            type = "all",
            conditions = {
              { type = "outcome", key = "N1", value = "C" },
              { type = "outcome", key = "N2", value = "C" },
            },
          },
          next = "warning",
        },
        {
          next = "short_greeting",
        },
      },
    },
    normal_greeting = {
      speaker = "Vagabundo",
      text = "Buenos días, señor. ¿Cómo va el día?",
      next = "protagonist_response",
    },
    warning = {
      speaker = "Vagabundo",
      text = "No quiero entrometerme, pero tenga cuidado con las apuestas. Me costaron todo a mí.",
      next = "protagonist_response",
    },
    short_greeting = {
      speaker = "Vagabundo",
      text = "Buenos días, señor. Cuídese.",
      next = "protagonist_response",
    },
    protagonist_response = {
      speaker = "Protagonista",
      text = "Podría ir mejor.",
      ending = true,
    },
  },
}
