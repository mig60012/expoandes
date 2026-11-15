return {
  id = "day_2_transition",
  start = "vagabond_route",
  nodes = {
    vagabond_route = {
      routes = {
        {
          condition = {
            type = "any",
            conditions = {
              { type = "outcome", key = "N1", value = "A" },
              { type = "outcome", key = "N1", value = "B" },
            },
          },
          next = "vagabond_saw_player",
        },
        {
          next = "vagabond_did_not_see",
        },
      },
    },
    vagabond_saw_player = {
      speaker = "Vagabundo",
      text = "¿Otro día más para el casino? Esto se está volviendo un hábito.",
      next = "protagonist_ignores",
    },
    vagabond_did_not_see = {
      speaker = "Vagabundo",
      text = "Señor, no lo vi anoche. Tenga cuidado con esas noches de juego sin fin.",
      next = "protagonist_ignores",
    },
    protagonist_ignores = {
      speaker = "Protagonista",
      text = "Por favor, no se meta.",
      ending = true,
    },
  },
}
