-- Adaptacion de Historia.docx. Los importes no fijados en el guion se configuran
-- en Game.context.rules. No se cambia el significado de N1/N2/N3/N5.
local B = require("src/data/dialogues/script_builder")
local H = { morning = {}, street = {}, returning = {} }
local function outcome(key, value) return { type = "outcome", key = key, value = value } end
local function any(...)
  return { type = "any", conditions = { ... } }
end
local function both(...)
  return { type = "all", conditions = { ... } }
end
local function points(amount)
  return { { type = "add_value", key = "family_points", amount = amount } }
end

local g = B.new("historia_opening")
g:scene("inicio", {
  { "Narrador", "En la sala de su casa, un hombre apuesta en línea desde su teléfono." },
  { "Esposa", "¿Otra vez?" },
  { "Protagonista", "Ya casi termino." },
  { "Esposa", "Eso dijiste ayer." },
  { "Protagonista", "Estoy intentando recuperar lo que perdí." },
  { "Esposa", "¿Y si lo dejas por hoy?" },
  { "Protagonista", "No es tan sencillo." },
  { "Narrador", "La conversación queda sin resolver." },
  { "Narrador", "Un año después. Las apuestas en línea ya no le hacen sentir lo mismo. Ahora pasa sus días en el casino." },
  { "Narrador", "Una noche, en la calle, negocia un préstamo con un gota a gota." },
  { "Protagonista", "Le debo mucho dinero al casino, entonces necesito toda esa cantidad, si es posible." },
  { "Gota a gota", "¡Claro que es posible! Enviaré a uno de mis empleados con el dinero mañana mismo." },
  { "Protagonista", "Excelente, ¿y cuándo debo pagarte el dinero?" },
  { "Gota a gota", "En dos meses está bien." },
  { "Protagonista", "Listo, hecho." },
  { "Narrador", "Pasa el tiempo. Faltan cinco días para que se cumpla el plazo. Los dos vuelven a encontrarse en la misma calle." },
  { "Gota a gota", "Te quedan 5 días para pagarme." },
  { "Protagonista", "Ya lo sé, solo estoy reuniendo el dinero, no te preocupes, tendrás el dinero a tiempo." },
  { "Gota a gota", "Pues eso espero, o si no, no respondo por lo que le pueda pasar a tu bella familia." },
  { "Protagonista", "¡Ni se te ocurra meterte con ellas! Es lo único bueno que me queda después de todo lo que me ha pasado." },
  { "Gota a gota", "¿Y por qué debería importarme eso a mí? Solo paga a tiempo, y todo estará bien." },
  { "Narrador", "Día 1. De vuelta en la sala de su casa, el protagonista se prepara para salir a «trabajar»." },
})
H.opening = g:build("inicio")

g = B.new("historia_day_1")
g:scene("esposa", {
  { "Esposa", "Hola, cariño, que te vaya bien en el trabajo, trata de llegar temprano." },
  { "Protagonista", "Gracias, cariño, no sé a qué hora podré llegar, pero te prometo que haré un esfuerzo por salir temprano." },
  { "Esposa", "Eso espero." },
  { "Hija", "Hola, papá, ¿cómo estás?" },
}, "respuesta")
g:choice("respuesta", "¿Qué le respondo a mi hija?", {
  { text = "Preguntarle por el colegio", next = "colegio", effects = points(1) },
  { text = "Salir rápido al trabajo", next = "prisa" },
})
g:scene("colegio", {
  { "Protagonista", "Hola, hija, bien. ¿Cómo te ha ido en el colegio?", "Hija" },
  { "Hija", "Bien, papá, estoy emocionada porque ya casi lo termino y puedo entrar a la universidad." },
  { "Protagonista", "Eso está muy bien, con suerte nos vemos esta noche." },
  { "Hija", "Eso espero, ya me estoy cansando de que trabajes hasta tan tarde." },
})
g:scene("prisa", {
  { "Protagonista", "Hola, bien, tengo que salir ya a trabajar, voy muy tarde, lo siento.", "Hija" },
  { "Hija", "Mi papá está actuando muy raro, de pronto solo tiene mucho que hacer en el trabajo." },
})
H.morning[1] = g:build("esposa")

g = B.new("historia_day_2")
g:route("ruta", { { condition = outcome("N1", "A"), next = "familia" }, { next = "ausente" } })
g:scene("familia", {
  { "Esposa", "Anoche la niña estuvo muy contenta de que llegaras." },
  { "Hija", "¿Hoy también vas a estar?" },
  { "Protagonista", "Voy a intentar terminar temprano.", "Hija" },
}, "respuesta")
g:choice("respuesta", "¿Qué le digo a mi hija?", {
  { text = "Disculparme y valorar el tiempo juntos", next = "perdon", effects = points(1) },
  { text = "No prometer que pueda hacerlo seguido", next = "trabajo" },
})
g:scene("perdon", {
  { "Protagonista", "Yo también te extrañé. Me gustó estar con ustedes ayer.", "Hija" },
  { "Hija", "Entonces intenta llegar temprano hoy." },
  { "Protagonista", "Voy a intentarlo." },
})
g:scene("trabajo", {
  { "Protagonista", "No puedo prometer que vaya a ser seguido. Tengo mucho trabajo.", "Hija" },
  { "Hija", "Bueno…" },
})
g:scene("ausente", {
  { "Esposa", "Buenos días, ¿mucho trabajo anoche?" },
  { "Protagonista", "Sí. Se me hizo tarde." },
  { "Hija", "Últimamente siempre se te hace tarde." },
  { "Esposa", "Deja que desayune, hija.", false },
})
H.morning[2] = g:build("ruta")

g = B.new("historia_day_3")
g:route("ruta", { { condition = outcome("N2", "A"), next = "familia" }, { next = "ausencias" } })
g:scene("familia", {
  { "Esposa", "Me alegra que ayer llegaras temprano." },
  { "Hija", "Hoy tengo un evento en el colegio. Estoy un poco nerviosa." },
  { "Protagonista", "¿Qué vas a presentar?", "Hija" },
  { "Hija", "Una presentación. Después te cuento cómo me fue." },
}, "colegio")
g:choice("colegio", "¿Le presto atención?", {
  { text = "Desearle suerte y escucharla", next = "suerte", effects = points(1) },
  { text = "Despedirme rápidamente", next = "prisa" },
})
g:scene("suerte", {
  { "Protagonista", "Que te vaya bien. Después me cuentas cómo te fue.", "Hija" },
  { "Hija", "¿De verdad vas a escuchar todo?" },
  { "Protagonista", "Todo." },
  { "Hija", "Entonces te guardo los detalles.", false },
})
g:scene("prisa", {
  { "Protagonista", "Qué bueno. Tengo que salir ya, voy tarde.", "Hija" },
  { "Hija", "Ah, bueno. Suerte entonces.", false },
})
g:scene("ausencias", { { "Protagonista", "Debo tratarlas bien, les va a parecer raro mi comportamiento si no lo hago.", false } }, "ruta_ausencia")
g:route("ruta_ausencia", {
  { condition = both(any(outcome("N1", "B"), outcome("N1", "C")), any(outcome("N2", "B"), outcome("N2", "C"))), next = "dos_noches" },
  { next = "una_noche" },
})
g:scene("dos_noches", {
  { "Esposa", "Necesito preguntarte algo. ¿Está pasando algo en el trabajo?" },
  { "Protagonista", "No. ¿Por qué?" },
  { "Esposa", "No sé. Últimamente estás distinto." },
  { "Protagonista", "Estoy cansado, nada más.", false },
})
g:scene("una_noche", {
  { "Narrador", "La conversación no ocurre. La mañana continúa.", false },
})
H.morning[3] = g:build("ruta")

g = B.new("historia_day_4")
g:route("ruta", {
  { condition = outcome("N3", "A"), next = "carro_conocido" },
  { condition = outcome("N3", "C"), next = "carro_oculto" }, { next = "conservado" },
})
g:scene("carro_conocido", {
  { "Esposa", "No estaba de acuerdo con vender el carro, pero ya está hecho. Necesito que me expliques qué está pasando." },
  { "Protagonista", "Es una deuda vieja. Voy a solucionarlo." },
  { "Esposa", "¿Qué deuda? Nunca me hablaste de esto." },
  { "Protagonista", "No quería preocuparte." },
  { "Esposa", "No puedes decidir eso por mí.", false },
})
g:scene("carro_oculto", {
  { "Esposa", "¿Dónde está el carro?" },
  { "Protagonista", "Tuve que venderlo. Necesitaba el dinero." },
  { "Esposa", "¿Lo vendiste sin decirme nada?" },
  { "Protagonista", "No tenía tiempo para discutirlo." },
  { "Esposa", "No es una discusión. Es nuestro carro." },
  { "Protagonista", "Lo sé." },
  { "Esposa", "No parece que lo sepas.", false },
})
g:scene("conservado", {
  { "Esposa", "¿Vas a llegar temprano hoy?" },
  { "Protagonista", "No lo sé." },
  { "Esposa", "La niña tiene cosas que contarte." },
  { "Protagonista", "Voy a intentar estar.", false },
})
H.morning[4] = g:build("ruta")

g = B.new("historia_day_5")
g:scene("hija", {
  { "Narrador", "La esposa está distante. No inicia una discusión." },
  { "Hija", "Papá, mamá me dijo que están pasando por un problema." },
  { "Protagonista", "Lo siento. No quería que te preocuparas." },
  { "Hija", "¿Por eso casi nunca estás?" },
  { "Protagonista", "He estado intentando resolver unas cosas." },
  { "Hija", "¿Y vas a volver a estar con nosotras?" },
  { "Protagonista", "Claro." },
  { "Hija", "No me prometas cosas si no estás seguro.", false },
}, "decision")
g:choice("decision", "¿Qué hago en el último día?", {
  { text = "Ir a trabajar", action = "work" }, { text = "Ir al casino", action = "casino" },
})
H.morning[5] = g:build("hija")

g = B.new("historia_street_1")
g:scene("vagabundo", {
  { "Vagabundo", "Buenos días." },
  { "Protagonista", "Buenos días." },
  { "Vagabundo", "Que tenga buen día.", false },
})
H.street[1] = g:build("vagabundo")
g = B.new("historia_street_2")
g:route("ruta", {
  { condition = any(outcome("N1", "A"), outcome("N1", "B")), next = "visto" }, { next = "tarde" },
})
g:scene("visto", {
  { "Vagabundo", "¿Otro día más para el casino? Esto se está volviendo un hábito para usted." },
  { "Protagonista", "Por favor, no se meta." },
  { "Protagonista", "Si supiera que el casino es mi única salida en este punto.", false },
})
g:scene("tarde", {
  { "Vagabundo", "Señor, no lo vi anoche, cuidado con esas noches de juego sin fin." },
  { "Protagonista", "Por favor, no se meta." },
  { "Protagonista", "Si supiera que no tengo opción, tengo que ganar dinero rápido. Trabajar ya no es suficiente.", false },
})
H.street[2] = g:build("ruta")
g = B.new("historia_street_3")
g:route("ruta", {
  { condition = any(outcome("N2", "A"), outcome("N2", "B")), next = "visto" },
  { condition = both(outcome("N1", "C"), outcome("N2", "C")), next = "dos_noches" }, { next = "una_noche" },
})
g:scene("visto", { { "Vagabundo", "Buenos días, señor, ¿cómo va el día?" }, { "Protagonista", "Podría ir mejor." } })
g:scene("dos_noches", {
  { "Vagabundo", "Hace tiempo que no lo veo salir temprano." },
  { "Protagonista", "Tengo asuntos pendientes." },
  { "Vagabundo", "No tiene que explicarme nada." },
  { "Protagonista", "Tengo una deuda. No puedo simplemente dejar de ir." },
  { "Vagabundo", "Yo también tuve una deuda." },
  { "Protagonista", "¿Y qué hizo?" },
  { "Vagabundo", "Seguí jugando.", false },
})
g:scene("una_noche", { { "Vagabundo", "El vagabundo lo saluda brevemente. No hay advertencia.", false } })
H.street[3] = g:build("ruta")
g = B.new("historia_street_4")
g:route("ruta", {
  { condition = any(outcome("N3", "C"), outcome("N3", "D")), next = "tarde" },
  { condition = outcome("N3", "A"), next = "vendido" }, { next = "temprano" },
})
g:scene("tarde", {
  { "Vagabundo", "¿Durmió algo anoche?" },
  { "Protagonista", "¿Ahora también va a preguntarme eso?" },
  { "Vagabundo", "No tiene que contestarme." },
  { "Protagonista", "Tengo demasiadas cosas en la cabeza." },
  { "Vagabundo", "Lo imagino.", false },
})
g:scene("vendido", {
  { "Protagonista", "Creo que ya es muy tarde para cambiar la situación, tuve que vender mi carro para pagarle una deuda a un gota a gota.", "Vagabundo" },
  { "Vagabundo", "Yo también tuve que vender cosas." },
  { "Protagonista", "No es lo mismo." },
  { "Vagabundo", "Eso pensaba yo.", false },
})
g:scene("conservado", {
  { "Vagabundo", "Cuídese, señor." },
  { "Protagonista", "Gracias.", false },
})
g:scene("temprano", {
  { "Vagabundo", "El vagabundo lo saluda brevemente o no está presente.", false },
})
H.street[4] = g:build("ruta")
g = B.new("historia_street_5")
g:scene("ausente", { { "Protagonista", "El vagabundo no está. Debo seguir.", false } })
H.street[5] = g:build("ausente")

g = B.new("historia_return_street")
g:scene("aviso", {
  { "Vagabundo", "Tenga cuidado, por favor, las apuestas son peligrosas." },
  { "Protagonista", "Necesito dinero ya, el trabajo no es suficiente para pagar esta deuda.", false },
})
H.returning[1] = g:build("aviso")
g = B.new("historia_silent_return")
g:scene("regreso", { { "Protagonista", "El vagabundo me ve pasar, pero no dice nada. Sigo hacia casa.", false } })
H.returning[2], H.returning[3] = g:build("regreso"), g.data
g = B.new("historia_absent_return")
g:scene("regreso", { { "Protagonista", "El vagabundo no está. Regreso a casa.", false } })
H.returning[4], H.returning[5] = g:build("regreso"), g.data
g = B.new("historia_night_street")
g:scene("noche", { { "Narrador", "La calle está oscura. El vagabundo ya está dormido y no ve al protagonista regresar." } })
H.night_street = g:build("noche")

g = B.new("historia_early_return")
g:choice("actividad", "Todavía tengo tiempo. ¿Trabajo o me quedo con mi familia?", {
  { text = "Trabajar", action = "work", next = "trabajo" },
  { text = "Pasar tiempo en familia", action = "family", next = "familia", effects = points(1) },
})
g:scene("trabajo", { { "Protagonista", "Necesito seguir trabajando para pagar la deuda.", false } })
g:scene("familia", {
  { "Esposa", "Hola, cariño, qué bueno que llegaste temprano, te estábamos esperando." },
  { "Hija", "Sí, papá, ya era hora." },
  { "Protagonista", "Lo sé, por eso hice el esfuerzo de salir temprano del trabajo.", "Hija" },
})
H.early_return = g:build("actividad")
g = B.new("historia_late_return")
g:scene("noche", {
  { "Protagonista", "Tuve que quedarme hasta tarde, necesito ganar dinero rápido. Creo que entre más apueste, más dinero puedo ganar.", false },
  { "Narrador", "La familia ya está dormida. El día termina." },
})
H.late_return = g:build("noche")

g = B.new("historia_car")
g:route("ruta", { { condition = { type = "value", key = "casino_games_today", operator = "==", value = 3 }, next = "cena" }, { next = "venta_tarde" } })
g:scene("cena", {
  { "Hija", "¡Papá, qué bueno que ya llegaste! Ya casi está la comida." },
  { "Esposa", "Hola, cariño, ¿cómo te fue hoy?" },
  { "Protagonista", "Hola, ¿cómo están? ¿Qué es de comer?" },
  { "Esposa", "Tu plato favorito, pasta bolognesa." }, { "Protagonista", "¡Estupendo!" },
}, "venta_temprano")
g:choice("venta_temprano", "¿Vendo el carro para pagar la deuda?", {
  { text = "Vender el carro", action = "sell_known", next = "discusion", effects = points(-1) },
  { text = "Conservarlo", action = "keep" },
})
g:choice("venta_tarde", "Todos están dormidos. ¿Vendo el carro para pagar la deuda?", {
  { text = "Vender el carro sin contárselo a mi esposa", action = "sell_unknown" },
  { text = "Conservarlo", action = "keep" },
})
g:scene("discusion", {
  { "Protagonista", "He estado pensando que podríamos vender el carro. Necesito dinero para una deuda.", "Esposa" },
  { "Esposa", "¿Para qué?" },
  { "Protagonista", "Necesito dinero para una deuda. No quería preocuparte." },
  { "Esposa", "No puedes decidir qué cosas tengo derecho a saber." },
})
H.car_return = g:build("ruta")

g = B.new("historia_confrontation")
g:scene("esposa", {
  { "Esposa", "¿Qué te pasa?" }, { "Protagonista", "¿Cómo así qué te pasa?" },
  { "Esposa", "¡Lo que oíste! Eres un cobarde y mentiroso. Cuando empezaste a apostar en línea te dije que así empezaban todos los adictos. Y tú no me hiciste caso." },
  { "Protagonista", "¿De qué estás hablando?" },
  { "Esposa", "Iba de camino al mercado, y el vagabundo que siempre se hace al lado del casino me dijo que todos los días vas al casino a jugar." },
  { "Protagonista", "Está bien, sí, ¿y qué pasa?" },
}, "carro")
g:route("carro", { { condition = { type = "flag", key = "car_sold", value = true }, next = "vendido" }, { next = "conservado" } })
g:scene("vendido", {
  { "Esposa", "¿Cómo qué pasa? Pues pasa de todo. Estoy segura de que esa deuda de la que hablabas es por esto. Te endeudaste por andar perdiendo plata apostando, ¿cierto?" },
  { "Protagonista", "No, cariño, esa fue una deuda que saqué para empezar mi negocio, y me tenía hasta el cuello. Te lo prometo." },
  { "Esposa", "Más te vale." },
}, "advertencia")
g:scene("conservado", {
  { "Esposa", "¿Cómo qué pasa? Pues obviamente está mal. Estás adicto a las apuestas." },
  { "Protagonista", "Mira, cariño, voy a serte sincero. Tengo una gran deuda, más grande de lo que te puedas imaginar. Sin ella, mi negocio no existiría, pero se acerca el límite de pago con el banco. Voy al casino a recuperar dinero." },
}, "advertencia")
g:scene("advertencia", {
  { "Esposa", "Esa no es la manera de ganar dinero, la casa siempre, siempre gana. Tienes que trabajar más, hacer otras cosas. Si no, lo único que vas a lograr es más pérdida, más deuda." },
}, "respuesta")
g:choice("respuesta", "¿Qué le digo?", {
  { text = "Insistir en que puedo recuperar el dinero", next = "negar", effects = points(-1) },
  { text = "Prometer que mañana iré a trabajar", next = "promesa" },
})
g:scene("negar", {
  { "Protagonista", "No, cariño, créeme que no hay marcha atrás, es la única manera. Soy buen jugador, y puedo ganar el dinero de vuelta de esa manera.", "Esposa" },
  { "Esposa", "Ya para con tu ingenuidad, obviamente no puedes ganar. Eso era lo que decías cuando empezaste a apostar en línea: «Soy muy bueno, no puedo perder». ¿No puedes ver que eso es mentira? No importa qué tan bueno sea alguien, o cuánto autocontrol tenga, el resultado siempre es el mismo: adicción y deudas." },
  { "Protagonista", "Te equivocas, pero no hay nada que pueda hacer para convencerte." },
})
g:scene("promesa", {
  { "Protagonista", "Tienes razón, cariño, mañana iré a trabajar todo el día, a ver qué negocios puedo hacer para ganar más dinero.", "Esposa" },
  { "Esposa", "Más te vale, mañana iré donde el vagabundo de nuevo, y si vas al casino, lo sabré de nuevo." },
  { "Protagonista", "Te lo prometo." },
})
H.confrontation = g:build("esposa")

g = B.new("historia_economic")
g:choice("decision", "¿Cómo intento completar el pago de la deuda?", {
  { text = "Hipotecar la casa", action = "mortgage", next = "casa", effects = {
    { type = "add_value", key = "family_points", amount = -1 }, { type = "set_flag", key = "house_mortgaged", value = true } } },
  { text = "Usar los ahorros universitarios de mi hija", action = "daughter_savings", next = "ahorros", effects = {
    { type = "add_value", key = "family_points", amount = -1 }, { type = "set_flag", key = "daughter_savings_used", value = true } } },
  { text = "No utilizar ninguno", action = "none" },
})
g:scene("casa", {
  { "Protagonista", "Tengo que contarte algo. La deuda es mucho más grande de lo que te dije. He estado apostando.", "Esposa" },
  { "Esposa", "¿Cuánto tiempo llevas así?" },
  { "Protagonista", "No sé exactamente." },
  { "Esposa", "No puedo seguir viviendo sin saber qué va a pasar. Mañana me voy con la niña a casa de mi madre.", false },
})
g:scene("ahorros", {
  { "Protagonista", "Usé el dinero que teníamos guardado para la universidad.", "Hija" },
  { "Hija", "¿Qué dinero?" },
  { "Protagonista", "El que teníamos ahorrado." },
  { "Hija", "¿El mío?" },
  { "Protagonista", "Lo voy a recuperar." },
  { "Hija", "Ese dinero era para estudiar.", false },
})
H.economic = g:build("decision")
g = B.new("historia_work")
g:scene("trabajo", { { "Narrador", "Tomas tu maletín y trabajas. El tiempo pasa mientras reúnes dinero para pagar la deuda." },
  { "Narrador", "Regresas a casa al terminar la jornada." } })
H.work = g:build("trabajo")

H.endings = {}
g = B.new("historia_final_1")
g:scene("final", {
  { "Narrador", "Un día después. La casa está vacía. La puerta está abierta. No hay nadie." },
  { "Protagonista", "¿Amor?" }, { "Narrador", "No obtiene respuesta." },
  { "Narrador", "Sobre la mesa quedan algunas pertenencias." },
  { "Narrador", "Un mes después, el protagonista está sentado en la calle, cerca del vagabundo." },
  { "Protagonista", "¿Usted cree que alguna vez se puede volver a empezar?" },
  { "Vagabundo", "No lo sé.", false },
})
H.endings.final_1 = g:build("final")
for _, id in ipairs({ "final_2", "final_3" }) do
  g = B.new("historia_" .. id)
    local relacion = id == "final_2"
      and "A veces hablo con mi hija. No es como antes. Ya no me cuenta todo y tampoco sé cómo preguntarle. Mi esposa no quiere verme. No la culpo."
      or "Hace meses que no hablo con ellas. A veces pienso en llamarlas. Después recuerdo todo lo que les dije y todo lo que les oculté. No sé si todavía quieren escucharme."
  g:scene("final", {
    { "Narrador", "Un año después. El protagonista cuenta el final de su historia." },
    { "Protagonista", "El negocio quebró y tuve que aceptar otro empleo. Estoy separado de mi esposa. Mi situación económica sigue siendo difícil." },
    { "Protagonista", relacion },
  })
  H.endings[id] = g:build("final")
end
g = B.new("historia_final_4")
g:scene("final", {
  { "Narrador", "Después de pagar la deuda, el protagonista vuelve al casino. Ya no tiene la misma presión económica que lo llevó allí, pero entra y decide apostar otra vez." },
  { "Protagonista", "La deuda ya estaba pagada." },
  { "Protagonista", "Podría haberme ido." },
  { "Protagonista", "Pero seguía pensando que podía ganar un poco más.", false },
})
H.endings.final_4 = g:build("final")
return H
