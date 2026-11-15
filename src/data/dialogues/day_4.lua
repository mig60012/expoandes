return {
  id = "day_4",
  start = "morning_route",
  nodes = {
    morning_route = {
      routes = {
        {
          condition = {
            type = "outcome",
            key = "N3",
            value = "A",
          },
          next = "car_known",
        },
        {
          condition = {
            type = "outcome",
            key = "N3",
            value = "C",
          },
          next = "car_unknown",
        },
        {
          next = "car_kept",
        },
      },
    },
    car_known = {
      speaker = "Esposa",
      text = "No estoy de acuerdo con lo que vas a hacer, pero espero que te den buen dinero.",
      next = "daughter_knows",
    },
    daughter_knows = {
      speaker = "Hija",
      text = "Escuché que vas a vender el carro. ¿Para qué necesitas tanta plata?",
      next = "protagonist_explains",
    },
    protagonist_explains = {
      speaker = "Protagonista",
      text = "Es una deuda vieja. Todo mejorará.",
      next = "morning_finished",
    },
    car_unknown = {
      speaker = "Protagonista",
      text = "He decidido vender el carro. Necesito pagar una deuda vieja que no te había contado.",
      next = "wife_angry",
    },
    wife_angry = {
      speaker = "Esposa",
      text = "Mentiroso, debiste decírmelo. Si esto sigue así, tendré que dejarte.",
      next = "morning_finished",
    },
    car_kept = {
      speaker = "Esposa",
      text = "Voy al mercado a comprar unas cosas que nos faltan.",
      next = "daughter_leaves",
    },
    daughter_leaves = {
      speaker = "Hija",
      text = "Tengo que salir rápido, voy tarde y me va a dejar el bus.",
      next = "morning_finished",
    },
    morning_finished = {
      text = "",
      ending = true,
    },
  },
}
