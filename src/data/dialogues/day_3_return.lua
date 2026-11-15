return {
  id = "day_3_return",
  start = "decision_route",
  nodes = {
    decision_route = {
      routes = {
        {
          condition = {
            type = "value",
            key = "casino_games_today",
            operator = "==",
            value = 3,
          },
          next = "three_games_decision",
        },
        {
          next = "six_games_decision",
        },
      },
    },
    three_games_decision = {
      speaker = "Protagonista",
      text = "¿Vender el carro para pagar la deuda?",
      choices = {
        {
          text = "Vender el carro",
          action = "sell_known",
        },
        {
          text = "Conservar el carro",
          action = "keep",
        },
      },
    },
    six_games_decision = {
      speaker = "Protagonista",
      text = "¿Vender el carro para pagar la deuda?",
      choices = {
        {
          text = "Vender el carro sin contárselo a mi esposa",
          action = "sell_unknown",
        },
        {
          text = "Conservar el carro",
          action = "keep",
        },
      },
    },
  },
}
