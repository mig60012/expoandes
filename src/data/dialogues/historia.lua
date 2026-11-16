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
  { "Esposa", "Cariño, llevas 2 horas apostando, ¿no crees que es tiempo de dejarlo por hoy?" },
  { "Protagonista", "No, cariño, ¿no ves cuánto dinero estoy haciendo? Es increíble. Haciendo esto podré pagar la universidad de nuestra hija." },
  { "Esposa", "No, cariño, en serio creo que esto se está volviendo un problema. ¿Qué pasa cuando empieces a perder? Porque créeme, lo harás, la casa siempre gana." },
  { "Protagonista", "Ya, no digas ridiculeces, no tengo ningún problema, y soy bueno apostando, no puedo perder. Me sé controlar yo solo, no necesito que me lo recuerdes todo el tiempo. Por favor, confía en mí, es imposible que me vuelva adicto o lo pierda todo." },
  { "Esposa", "Esto no me está gustando." },
  { "Protagonista", "Tranquila." },
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
  { "Esposa", "Buenos días, cariño, qué bueno que llegaste temprano anoche, disfrutamos de tu compañía." },
  { "Protagonista", "Buenos días, cariño, sí, yo también disfruté estar con ustedes." },
  { "Hija", "Sí, papá, te extraño cuando no estás." },
  { "Protagonista", "Debo hacer un esfuerzo por ser bueno con ellas, o me van a odiar.", "Hija" },
}, "respuesta")
g:choice("respuesta", "¿Qué le digo a mi hija?", {
  { text = "Disculparme y valorar el tiempo juntos", next = "perdon", effects = points(1) },
  { text = "No prometer que pueda hacerlo seguido", next = "trabajo" },
})
g:scene("perdon", {
  { "Protagonista", "Yo también, pequeña, ya era hora de que compartiéramos. Lo siento por no estar tan presente a veces.", "Hija" },
  { "Hija", "Gracias." },
})
g:scene("trabajo", {
  { "Protagonista", "Lo sé, pero no prometo poder hacerlo seguido, tengo mucho trabajo.", "Hija" },
  { "Hija", "Okay." },
})
g:scene("ausente", {
  { "Esposa", "Buenos días, ¿mucho trabajo anoche?" },
  { "Protagonista", "Sí, cariño, lo siento de nuevo." },
  { "Hija", "Ya se está volviendo costumbre." },
})
H.morning[2] = g:build("ruta")

g = B.new("historia_day_3")
g:route("ruta", { { condition = outcome("N2", "A"), next = "familia" }, { next = "ausencias" } })
g:scene("familia", {
  { "Esposa", "Hola, cariño, me gusta que hayas llegado temprano. Voy a hacer el desayuno de la niña." },
  { "Protagonista", "Que te vaya bien, cariño." },
  { "Esposa", "Gracias." },
  { "Hija", "Hola, papá, ¿cómo dormiste?" },
  { "Protagonista", "Hola, pequeña, muy bien, ¿y tú?" },
  { "Hija", "Bien, papá, hoy tengo un evento en el colegio. Deséame suerte." },
}, "colegio")
g:choice("colegio", "¿Le presto atención?", {
  { text = "Desearle suerte y escucharla", next = "suerte", effects = points(1) },
  { text = "Despedirme rápidamente", next = "prisa" },
})
g:scene("suerte", {
  { "Protagonista", "Que te vaya bien, hija, me cuentas cómo te fue.", "Hija" }, { "Hija", "Gracias, papá." },
})
g:scene("prisa", { { "Protagonista", "Qué bueno, pero tengo que irme ya, voy tarde al trabajo.", "Hija" } })
g:scene("ausencias", { { "Protagonista", "Debo tratarlas bien, les va a parecer raro mi comportamiento si no lo hago.", false } }, "ruta_ausencia")
g:route("ruta_ausencia", {
  { condition = both(any(outcome("N1", "B"), outcome("N1", "C")), any(outcome("N2", "B"), outcome("N2", "C"))), next = "dos_noches" },
  { next = "una_noche" },
})
g:scene("dos_noches", {
  { "Esposa", "Buenos días, mira, me estoy cansando de que llegues tarde, esto ya no es normal. ¿Qué está pasando?" },
  { "Protagonista", "Nada, cariño, en serio tengo mucho trabajo, nada más. Lo siento, trataré de mejorar." },
  { "Esposa", "Pues más te vale. Voy a hacerle el desayuno a la niña, y espero verte aquí temprano." },
  { "Protagonista", "Dale, cariño, que te vaya bien." },
  { "Hija", "Hola, ¿por qué sigues llegando tarde? ¿Qué te pasa?" },
}, "conflicto")
g:choice("conflicto", "¿Cómo respondo?", {
  { text = "Reclamarle también a ella", next = "enfado", effects = points(-1) },
  { text = "Disculparme y desearle suerte", next = "disculpa" },
})
g:scene("enfado", {
  { "Protagonista", "¿Tú también estás brava conmigo? Mira, ya tengo suficiente con tu madre, no tengo tiempo, debo salir ya.", "Hija" },
  { "Hija", "Ush, esto ya no es normal." },
})
g:scene("disculpa", {
  { "Protagonista", "Lo sé, hija, sé que prometí llegar más temprano, pero tengo mucho trabajo, trataré de llegar más temprano hoy.", "Hija" },
  { "Hija", "Eso espero, pero bueno, deséame suerte, tengo algo importante hoy." },
  { "Protagonista", "Que te vaya bien entonces, me cuentas cómo te va luego." },
})
g:scene("una_noche", {
  { "Esposa", "Hola, cariño, sé que solo fue ayer, pero por favor llega temprano hoy." },
  { "Protagonista", "Está bien, cariño, haré el mejor esfuerzo." },
  { "Esposa", "Eso espero, pero bueno, voy a hacer el desayuno de la niña." },
  { "Protagonista", "Que te vaya bien." },
  { "Hija", "Hola, papá, ¿mucho trabajo anoche?" },
  { "Protagonista", "Sí, hija, lo siento, trataré de llegar más temprano hoy." },
  { "Hija", "Está bien, pero deséame suerte, tengo algo importante hoy en el colegio." },
  { "Protagonista", "Entonces suerte, hija, nos vemos más tarde." },
  { "Hija", "Gracias, papá, así será." },
})
H.morning[3] = g:build("ruta")

g = B.new("historia_day_4")
g:route("ruta", {
  { condition = outcome("N3", "A"), next = "carro_conocido" },
  { condition = outcome("N3", "C"), next = "carro_oculto" }, { next = "conservado" },
})
g:scene("carro_conocido", {
  { "Esposa", "Hola. Mira, no estoy de acuerdo con lo que vas a hacer, pero espero te den buen dinero por ese carro." },
  { "Protagonista", "Lo mismo espero yo, lo siento, todo mejorará, cariño." },
  { "Esposa", "Más te vale. Pero bueno, voy para el mercado." },
  { "Protagonista", "Que te vaya bien." },
  { "Hija", "Hola, escuché de mi mamá que vas a vender el carro. ¿Qué te pasa? Ya me preocupa la manera en la que te estás comportando." },
  { "Protagonista", "Lo sé, pero lo siento. No había nada más que hacer, necesito el dinero." },
  { "Hija", "Y, ¿cómo para qué necesitas tanta plata?" },
  { "Protagonista", "Tenía una deuda vieja que pagar, pero todo mejorará, te lo prometo." },
  { "Hija", "Más te vale." },
})
g:scene("carro_oculto", {
  { "Esposa", "Hola, cariño, ¿qué tal la noche?" },
  { "Protagonista", "Bien, cariño, tengo algo que comentarte. He decidido vender el carro, necesito el dinero." },
  { "Esposa", "¿Para qué?" },
  { "Protagonista", "Necesito el dinero para pagar una deuda vieja, no te había contado sobre ella, pero es verdad." },
  { "Esposa", "¿Qué te pasa? Mentiroso, debiste haberme dicho que tenías deudas grandes." },
  { "Protagonista", "Lo sé, cariño, lo siento. Ahora lo sabes, y necesito que me dejes venderlo." },
  { "Esposa", "Pues claro que no, es tu deuda, y no vas a vender NUESTRO carro para pagarla." },
  { "Protagonista", "Bueno, pues lo lamento, pero no estaba pidiendo permiso. Haré lo que quiera con nuestro carro." },
  { "Esposa", "Bueno, pues nada que hacer, pero quiero que sepas que no me gusta esto. Cada vez estás más raro. Si esto sigue así, tendré que dejarte. Voy al mercado." },
  { "Protagonista", "Está brava conmigo, y tiene razón, pero no me quedaba de otra. Si no consigo esa plata a tiempo, nadie sabe qué puede pasar.", false },
})
g:scene("conservado", {
  { "Esposa", "Hola, cariño, voy al mercado a comprar unas cosas que nos faltan." },
  { "Protagonista", "Está bien, cariño, que te vaya bien." },
  { "Hija", "Hola, papá, tengo que salir rápido, voy tarde y me va a dejar el bus." },
  { "Protagonista", "Está bien, hija, que te vaya bien hoy." }, { "Hija", "Gracias." },
})
H.morning[4] = g:build("ruta")

g = B.new("historia_day_5")
g:scene("hija", {
  { "Hija", "Mi mamá me contó todo lo que pasó anoche. Eres un mentiroso, no te importa nada ni nadie." },
  { "Protagonista", "Lo siento, hija, no debí hacer todo esto, es mi culpa." },
  { "Hija", "Más te vale sacarnos de esta, todo es tu culpa." },
  { "Protagonista", "Lo sé, y nos sacaré de esta." },
  { "Protagonista", "Tengo que solucionar esto, necesito mucha plata, y rápido.", false },
}, "decision")
g:choice("decision", "¿Qué hago en el último día?", {
  { text = "Ir a trabajar", action = "work" }, { text = "Ir al casino", action = "casino" },
})
H.morning[5] = g:build("hija")

g = B.new("historia_street_1")
g:scene("vagabundo", { { "Vagabundo", "No puede ser, ¿usted de nuevo? ¿Por qué va todos los días al casino?" } })
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
  { "Vagabundo", "Buenos días, señor. Mire, no quiero entrometerme, pero tenga cuidado con las apuestas. Me costó todo a mí, no quiero que lo mismo le ocurra." },
  { "Protagonista", "Creo que ya es muy tarde para eso, tengo muchas deudas, no sé qué hacer. Esta es mi única salida, tengo que hacer dinero para ya." },
})
g:scene("una_noche", { { "Vagabundo", "Buenos días, señor. Cuídese." } })
H.street[3] = g:build("ruta")
g = B.new("historia_street_4")
g:route("ruta", {
  { condition = any(outcome("N3", "C"), outcome("N3", "D")), next = "tarde" }, { next = "temprano" },
})
g:scene("tarde", { { "Vagabundo", "Hola, señor, me está preocupando. Anoche pasó mucho tiempo en ese casino. Así terminé yo, y ya puede ver las consecuencias." } }, "carro")
g:route("carro", { { condition = outcome("N3", "C"), next = "vendido" }, { next = "conservado" } })
g:scene("vendido", {
  { "Protagonista", "Creo que ya es muy tarde para cambiar la situación, tuve que vender mi carro para pagarle una deuda a un gota a gota.", "Vagabundo" },
  { "Vagabundo", "Algo parecido me pasó, tenía un buen trabajo, una buena familia, y todo lo perdí por las apuestas. Por eso estoy aquí, una advertencia para personas perdidas como usted." },
})
g:scene("conservado", {
  { "Protagonista", "Lo sé, pero no me queda de otra, tengo que pagar una deuda.", "Vagabundo" },
  { "Vagabundo", "Así les pasa a muchos, pero si no cambia, terminará como yo." },
})
g:scene("temprano", {
  { "Vagabundo", "Hola, señor, me preocupa verlo todos los días en el casino." },
  { "Protagonista", "Lo sé, pero no me queda otra opción. Tengo que pagar una deuda muy, muy grande." },
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
  { "Protagonista", "Cariño, tengo que decirte algo. Creo que deberíamos vender el carro. No estamos tan bien de dinero, y lo necesitamos.", "Esposa" },
  { "Esposa", "¿Qué? No estoy de acuerdo, cariño, todo mejora, y luego extrañaremos la comodidad del carro." },
  { "Protagonista", "Bueno, pues no hay nada que hacer. Lo voy a vender, te guste o no. Lo siento, no lo discutiré más." },
  { "Esposa", "¿Qué te pasa? Cada día me preocupa más tu comportamiento, esto no está bien." },
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
  { "Protagonista", "Hola, cariño, tengo que ser honesto. No más mentiras. La realidad es que sí, estoy endeudado por el juego, y la deuda es mucho más grande que el carro. Tengo que hipotecar la casa para ayudarme a pagarla. Lo siento, de verdad, todo esto es mi culpa, y entiendo si quieres dejarme y llevarte a la niña.", "Esposa" },
  { "Esposa", "Lo sabía, te lo dije 20 mil veces, NO apuestes. Todos terminan así, perdiendo todo el dinero que se han ganado en su vida." },
  { "Protagonista", "Lo sé." },
  { "Esposa", "Cállate, ya no quiero oírte más. Mañana mismo empiezo a empacar mis cosas para irme a donde mi madre. No quiero verte la cara, eres lo peor que me ha pasado en mi vida." },
  { "Protagonista", "Está bien, lo entiendo. Espero algún día puedas perdonarme." },
  { "Esposa", "No creo que eso sea posible." },
})
g:scene("ahorros", {
  { "Hija", "Hola, papá." }, { "Protagonista", "Hola, hija, tenemos que hablar." }, { "Hija", "¿Qué pasó?" },
  { "Protagonista", "Voy a serte sincero, tengo una adicción a las apuestas. Tu madre me advirtió de esto cuando empecé a apostar en línea. No le hice caso, pensé que mi calidad jugando y mi autocontrol me permitirían mantener el control, y no volverme adicto. Pero la verdad es que es imposible, la casa siempre gana, y la mayoría termina como yo, perdiéndolo todo. Me endeudé gracias al juego, y ahora tengo que usar el dinero de tu universidad para pagar la deuda. Si no lo hago, cosas muy malas van a pasar." },
  { "Hija", "Eres un idiota, mentiroso, y bueno para nada. ¿En serio creíste que podías salirte con las tuyas, ganar apostando? Eso nunca pasa, mamá tenía razón, nunca debiste meterte en las apuestas." },
  { "Protagonista", "Lo sé, todo esto es mi culpa. No sé qué hará tu madre ahora, pero quiero que sepas que te quiero, para siempre, y espero algún día me perdones." },
  { "Hija", "Es imperdonable todo lo que has hecho. Nunca, pero nunca, te voy a perdonar. Estás sacrificando MI futuro por culpa de TU egoísmo e ingenuidad. Espero termines en la calle, como te lo mereces." },
})
H.economic = g:build("decision")
g = B.new("historia_work")
g:scene("trabajo", { { "Narrador", "Tomas tu maletín y trabajas. El tiempo pasa mientras reúnes dinero para pagar la deuda." },
  { "Narrador", "Regresas a casa al terminar la jornada." } })
H.work = g:build("trabajo")

H.endings = {}
g = B.new("historia_final_1")
g:scene("final", {
  { "Narrador", "Un día después. La casa está a oscuras. No se escucha ningún ruido." },
  { "Protagonista", "¿Cariño? ¿Hija?" }, { "Narrador", "No hay respuesta." },
  { "Protagonista", "¿Hola?" }, { "Narrador", "No hay respuesta. Su esposa y su hija han desaparecido." },
  { "Protagonista", "No puede ser, el gota a gota se las llevó. Todo es mi culpa, soy un egoísta y un mentiroso. Debí hacerle caso a mi esposa, nada de esto habría pasado. Pero ahora están desaparecidas, y quién sabe qué están haciendo con ellas. Soy un imbécil." },
  { "Narrador", "Un mes después. Sucio y con la ropa rota, el protagonista está en la calle, al lado del vagabundo." },
  { "Protagonista", "Debí hacerle caso a usted y a mi esposa, lo perdí todo, como usted." },
  { "Vagabundo", "Traté de advertirle, pero no me hizo caso. Y ahora está aquí, conmigo, en las mismas circunstancias que yo." },
  { "Protagonista", "Lo sé, lo tenía todo. Un negocio propio, una familia que me amaba. Y ahora no tengo mi negocio, y mi familia me odia, si es que están vivas." },
})
H.endings.final_1 = g:build("final")
local final_shared = "Ojalá le hubiera hecho caso a mi esposa desde el principio, nada de esto habría pasado. Pensé que podía apostar sin consecuencias, pero la realidad es que es muy fácil caer. La casa siempre gana, y la mayoría terminan como yo, perdiéndolo absolutamente todo y casi solos."
for _, id in ipairs({ "final_2", "final_3" }) do
  g = B.new("historia_" .. id)
  local relacion = id == "final_2" and "mi familia me dejó y mi ex-esposa me odia hasta el fondo de su corazón. Perdí mi negocio porque se quebró por mi culpa, y ahora trabajo en un McDonalds, miserable y arrepentido de todas las decisiones que tomé. Lo único bueno es que mi hija no me odia completamente, a veces hablo con ella o nos encontramos para hablar."
    or "mi familia me dejó y mi ex-esposa y mi hija me odian hasta el fondo de su corazón. Perdí mi negocio porque se quebró por mi culpa, y ahora trabajo en un McDonalds, miserable y arrepentido de todas las decisiones que tomé."
  g:scene("final", {
    { "Narrador", "Un año después. El protagonista cuenta el final de su historia." },
    { "Protagonista", "Y después de todo esto, logré pagar gran parte de la deuda, pero igualmente hubo consecuencias. El gota a gota me sacó un riñón para cobrarme la parte que me faltaba, " .. relacion },
    { "Protagonista", final_shared },
  })
  H.endings[id] = g:build("final")
end
g = B.new("historia_final_4")
g:scene("final", {
  { "Protagonista", "Al final, pude pagar mi deuda, pero ni siquiera importó, lo perdí todo otra vez. Tal como en el principio, pensé que podía ganar, y recuperar mi situación apostando. Pero como me dijo mi ex-esposa al principio de toda esta historia, la casa siempre gana. Debí hacerle caso desde el principio, nada de esto habría pasado, y probablemente seríamos felices juntos criando a nuestra maravillosa hija. Pero no, no le hice caso. Le hice caso a mi cabeza, que me decía que lo que me decía mi ex-esposa no me iba a pasar a mí, que era bueno jugando y que la adicción era un caso extremo. Pero la realidad es diferente, y terminé exactamente como ella creyó que lo haría si seguía apostando." },
  { "Protagonista", "Ahora mi familia me odia y ni siquiera sé qué pasó con sus vidas, pues no me quieren ver la cara ni en pintura. Además, mi negocio se quebró pues lo descuidé y empezó a ir cabeza abajo. Ahora trabajo en un McDonalds, triste y miserable, arrepentido de mis decisiones." },
})
H.endings.final_4 = g:build("final")
return H
