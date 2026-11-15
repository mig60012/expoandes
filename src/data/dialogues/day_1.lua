return {
  id = "day_1",
  start = "daughter_greeting",
  nodes = {
    daughter_greeting = {
      speaker = "Hija",
      text = "Hola papá, ¿cómo estás?",
      choices = {
        {
          text = "Preguntar por el colegio",
          next = "ask_school",
          effects = {
            { type = "add_value", key = "family_points", amount = 1 },
          },
        },
        {
          text = "Tengo que salir ya, voy muy tarde",
          next = "leave_quickly",
        },
      },
    },
    ask_school = {
      speaker = "Hija",
      text = "Ya casi termino y puedo entrar a la universidad. Ya me cansé de que trabajes hasta tan tarde.",
      next = "conversation_finished",
    },
    leave_quickly = {
      speaker = "Hija",
      text = "Mi papá está actuando muy raro.",
      next = "conversation_finished",
    },
    conversation_finished = {
      text = "",
      ending = true,
    },
  },
}
