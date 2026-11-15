return {
  id = "day_4_transition",
  start = "route",
  nodes = {
    route = {
      routes = {
        { condition = { type = "outcome", key = "N3", value = "C" }, next = "late" },
        { condition = { type = "outcome", key = "N3", value = "D" }, next = "late" },
        { condition = { type = "outcome", key = "N3", value = "A" }, next = "sold" },
        { next = "kept" },
      },
    },
    late = {
      speaker = "Vagabundo",
      text = "¿Durmió algo anoche?",
      next = "late_reply",
    },
    late_reply = {
      speaker = "Protagonista",
      text = "Tengo demasiadas cosas en la cabeza.",
      ending = true,
    },
    sold = {
      speaker = "Protagonista",
      text = "Tuve que vender el carro. Tengo una deuda con un prestamista.",
      next = "sold_reply",
    },
    sold_reply = {
      speaker = "Vagabundo",
      text = "Eso pensaba yo cuando vendí mis cosas.",
      ending = true,
    },
    kept = {
      speaker = "Vagabundo",
      text = "Cuídese, señor.",
      ending = true,
    },
  },
}
