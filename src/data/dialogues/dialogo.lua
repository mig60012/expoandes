return {
  id = "dialogo_demo",
  start = "inicio",
  nodes = {
    inicio = {
      speaker = "Guía",
      text = "¿Quieres conocer una decisión importante?",
      choices = {
        {
          text = "Escuchar",
          next = "explicacion",
          effects = {
            { type = "set_flag", key = "homeless_man_saw_player", value = true },
          },
        },
        {
          text = "Continuar sin escuchar",
          next = "despedida",
        },
      },
    },
    explicacion = {
      speaker = "Guía",
      text = "Tus decisiones pueden cambiar lo que ocurre después.",
      next = "resultado",
    },
    despedida = {
      speaker = "Guía",
      text = "La decisión queda registrada en el camino que elegiste.",
      next = "resultado",
    },
    resultado = {
      speaker = "Guía",
      text = "Esta conversación de prueba ha terminado.",
      ending = true,
    },
  },
}
