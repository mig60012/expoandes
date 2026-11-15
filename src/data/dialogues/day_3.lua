return {
  id = "day_3",
  start = "morning_route",
  nodes = {
    morning_route = {
      routes = {
        {
          condition = {
            type = "outcome",
            key = "N2",
            value = "A",
          },
          next = "family_morning",
        },
        {
          next = "absence_route",
        },
      },
    },
    family_morning = {
      speaker = "Esposa",
      text = "Me gusta que hayas llegado temprano. Voy a hacer el desayuno de la niña.",
      next = "daughter_event",
    },
    daughter_event = {
      speaker = "Hija",
      text = "Hoy tengo un evento en el colegio. Deséame suerte.",
      choices = {
        {
          text = "Que te vaya bien, hija. Me cuentas cómo te fue.",
          next = "morning_finished",
          effects = {
            { type = "add_value", key = "family_points", amount = 1 },
          },
        },
        {
          text = "Qué bueno, pero tengo que irme ya, voy tarde al trabajo.",
          next = "morning_finished",
        },
      },
    },
    absence_route = {
      routes = {
        {
          condition = {
            type = "all",
            conditions = {
              {
                type = "any",
                conditions = {
                  { type = "outcome", key = "N1", value = "B" },
                  { type = "outcome", key = "N1", value = "C" },
                },
              },
              {
                type = "any",
                conditions = {
                  { type = "outcome", key = "N2", value = "B" },
                  { type = "outcome", key = "N2", value = "C" },
                },
              },
            },
          },
          next = "two_days_absent",
        },
        {
          next = "one_day_absent",
        },
      },
    },
    two_days_absent = {
      speaker = "Esposa",
      text = "Me estoy cansando de que llegues tarde, ya no es normal. ¿Qué está pasando?",
      next = "daughter_confrontation",
    },
    daughter_confrontation = {
      speaker = "Hija",
      text = "¿Por qué sigues llegando tarde? ¿Qué te pasa?",
      choices = {
        {
          text = "¿Tú también estás brava conmigo? Ya tengo suficiente con tu madre.",
          next = "morning_finished",
          effects = {
            { type = "add_value", key = "family_points", amount = -1 },
          },
        },
        {
          text = "Lo sé, hija. Trataré de llegar más temprano hoy.",
          next = "morning_finished",
        },
      },
    },
    one_day_absent = {
      speaker = "Esposa",
      text = "Sé que solo fue ayer, pero por favor llega temprano hoy.",
      next = "one_day_daughter",
    },
    one_day_daughter = {
      speaker = "Hija",
      text = "¿Mucho trabajo anoche?",
      next = "morning_finished",
    },
    morning_finished = {
      text = "",
      ending = true,
    },
  },
}
