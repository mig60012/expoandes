return {
  id = "day_4_night",
  start = "confrontation",
  nodes = {
    confrontation = {
      speaker = "Esposa",
      text = "¿Dónde estabas? Ya no sé cuándo me dices la verdad.",
      next = "debt",
    },
    debt = {
      speaker = "Protagonista",
      text = "Tengo una deuda y estoy intentando pagarla.",
      next = "casino",
    },
    casino = {
      speaker = "Esposa",
      text = "¿En el casino? ¿Cuánto has perdido?",
      next = "response",
    },
    response = {
      speaker = "Protagonista",
      text = "No sé cómo llegué hasta aquí.",
      choices = {
        {
          text = "No hay marcha atrás. Puedo recuperar el dinero.",
          next = "justify",
          effects = { { type = "add_value", key = "family_points", amount = -1 } },
        },
        {
          text = "Perdí el control. Mañana buscaré otra solución.",
          next = "recognize",
        },
      },
    },
    justify = {
      speaker = "Esposa",
      text = "Eso es lo que me preocupa.",
      ending = true,
    },
    recognize = {
      speaker = "Esposa",
      text = "Necesito que mañana me digas toda la verdad.",
      ending = true,
    },
  },
}
