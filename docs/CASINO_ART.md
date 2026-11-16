# Arte del salón del casino

El fondo se adaptó de la captura suministrada (`WhatsApp Image 2026-11-14 at 11.56.55 PM (1).jpeg`, 736 × 1600). El archivo original no se modifica ni se incluye en el juego.

## Archivos usados

- `assets/casino/sala.png`: imagen de 736 × 414. Se recortó la región `(0, 592, 736, 414)` para eliminar los controles del teléfono y las franjas negras. Se enmascaró el borde ajedrezado, prolongando las texturas de alfombra y pared hasta los límites rectangulares. El centro del dibujo conserva el arte suministrado.
- `sala_blackjack.png`, `sala_poker.png`, `sala_ruleta.png`: recortes transparentes del mismo arte para dibujar las mesas delante del personaje cuando camina por detrás de ellas. No se superponen las antiguas mesas grises sobre el nuevo fondo.

El fondo se escala uniformemente al mapa de 2400 × 1350. La cámara sigue al jugador y permanece dentro de ese mapa, sin barras externas en ventanas 16:9, 4:3, panorámicas o verticales. Las sombras oscuras propias de la ilustración no se eliminan.

## Posiciones e interacción

`src/states/casino/plano.lua` contiene las posiciones medidas sobre el recorte, convertidas al mundo por `2400 / 736`. Se conserva la asignación:

- Semicírculo superior izquierdo: blackjack.
- Mesa redonda inferior izquierda: póker.
- Mesa alargada con rueda a la derecha: ruleta.
- Puerta bajo el letrero EXIT: salida del casino.

Las colisiones y zonas de interacción se ajustaron a esas posiciones. Los PNG grises anteriores y el trazado vectorial siguen disponibles como respaldo si el nuevo fondo no se puede cargar. El código no requiere el archivo de WhatsApp para ejecutar el juego.

La resolución está limitada por la captura recibida; un original de mayor resolución se puede integrar después, conservando el mismo encuadre y revisando sus coordenadas.
