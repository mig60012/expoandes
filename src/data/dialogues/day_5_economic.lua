return {
  id = "day_5_economic",
  start = "decision",
  nodes = {
    decision = {
      speaker = "Protagonista",
      text = "¿Qué recurso utilizo para completar el pago?",
      choices = {
        { text = "Hipotecar la casa", action = "mortgage", ending = true },
        { text = "Usar los ahorros universitarios", action = "daughter_savings", ending = true },
        { text = "No utilizar ninguno", action = "none", ending = true },
      },
    },
  },
}
