return {
  id = "day_5",
  start = "morning",
  nodes = {
    morning = {
      speaker = "Hija",
      text = "¿Y vas a volver a estar con nosotras?",
      next = "answer",
    },
    answer = {
      speaker = "Protagonista",
      text = "Claro.",
      next = "daughter",
    },
    daughter = {
      speaker = "Hija",
      text = "No me prometas cosas si no estás seguro.",
      next = "decision",
    },
    decision = {
      speaker = "Protagonista",
      text = "Hoy tengo que decidir qué hacer.",
      choices = {
        { text = "Trabajar durante el día", action = "work", ending = true },
        { text = "Ir al casino", action = "casino", ending = true },
      },
    },
  },
}
