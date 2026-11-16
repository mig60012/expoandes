# Historia y presentación

Adaptación de `Historia.docx`, sin reemplazar el motor `Dialogue`, sus condiciones/efectos ni `DayFlow` / `StoryOutcomes` / `FinalEvaluation`.

## Escenas

- Prólogo: apuestas en línea con la esposa, salto de un año, préstamo, amenaza cinco días antes del plazo. Pantalla negra; luego comienza la mañana del día 1.
- Días 1–2: encuentros matutinos con esposa/hija, advertencias del vagabundo, casino, regreso temprano con trabajo/familia o regreso nocturno. Las respuestas dependen de N1.
- Día 3: las ausencias de N1/N2 deciden el diálogo matutino; advertencias en la calle; cena temprana o casa dormida y venta/conservación del carro. N3 distingue si la esposa conoce la venta. El protagonista pasa de un carro provisional a caminar cuando lo vende.
- Día 4: reacción a N3; conversación con el vagabundo; la esposa confronta al protagonista sobre las apuestas tanto si regresa temprano como si vuelve de noche.
- Día 5: la hija lo confronta; elección de trabajo/casino; hipoteca, ahorros universitarios o ninguna medida, con la conversación correspondiente. Se registra N5 antes de evaluar el final.
- Cuatro epílogos completos en pantalla negra. Final 4 ofrece elegir una última apuesta de ruleta, blackjack o póker y representa su pérdida como una secuencia guionizada; las mesas normales no cambian de reglas o probabilidades.

## Interfaz

`Enter`, `Espacio` y `Z` avanzan. Mantener una tecla no salta fragmentos. `Arriba/Abajo` o `W/S` seleccionan una respuesta; también se puede hacer clic en sus botones. Las decisiones no se aplican hasta haber leído todas las páginas del parlamento. Cada página tiene como máximo dos líneas ajustadas al ancho real de la fuente.

En interacciones hay como máximo dos modelos: protagonista a la izquierda y el interlocutor actual a la derecha. Al cambiar entre esposa e hija, se reemplaza el modelo derecho. Las zonas de retratos terminan antes de que empiece el cuadro de texto. Las cinemáticas inicial/final no muestran personajes y tienen fondo negro. Después del epílogo, `R` inicia una partida limpia (dinero, decisiones, encuentros y hora incluidos).

El cuadro se ajusta al número de líneas de la página actual y solo reserva botones cuando las opciones son visibles. No conserva el antiguo tercio inferior vacío. La detección de clics usa exactamente la misma geometría que el dibujo.

En la calle, `Characters.has_car` consulta `car_sold` para escoger modelo y velocidad en conjunto. El carro tiene perfil de sedán, dos ruedas, ventanas, puertas y luces; avanza al doble de la velocidad base. Tras la venta se muestra el modelo a pie a velocidad base. En la casa se retiró el celular y el maletín tiene `activo = false`, conservando su acción para futuras iteraciones. Las opciones de trabajo del guion no se desactivan.

## Reglas conservadas y balance

Se conservan los umbrales de `FinalEvaluation`: menos de 50% lleva al final 1; de 50% a menos de 100% se distingue por puntos familiares; 100% lleva al final 4. El guion no define el caso exactamente 50%, por eso se conserva la regla de main.

Los importes no están fijados en el documento. `Game.context.rules` mantiene los porcentajes existentes de trabajo (20), hipoteca (80), ahorros (40) y umbral familiar (2). Añade valores editables para venta del carro (20% de deuda) e ingreso de trabajo (5 M). El capital inicial de main (10 M) y las ganancias se conservan entre entradas al casino durante la historia; no se restaura el antiguo reinicio a cero. Estos valores son de balance provisional, no cantidades atribuidas al guion.

Los encuentros no se repiten al volver a entrar en la misma escena. Cada nuevo día reinicia solamente su cuota y su elección de tres/seis juegos; las relaciones, las consecuencias y los resultados de días anteriores se conservan. Los datos abreviados `day_*.lua` se conservan para compatibilidad, mientras la partida narrativa usa `historia.lua`.

## Pruebas

`lua tests/run.lua` incluye los tests de decisiones ya presentes y `test_historia.lua`: valida los grafos, recorre cinco planes completos de cinco días, alcanza los cuatro finales, comprueba efectos de una sola aplicación, paginación y separación retratos/texto en varias proporciones de ventana.
