# Decisiones técnicas

- El filtro complementario usa peso configurable `0.98`: integra el giroscopio y lo corrige con el acelerómetro. Su primer dato usa solo acelerómetro para evitar salto inicial.
- La inclinación se obtiene con `atan2` y se muestra a 0.1°. Los streams se cancelan al salir de la pantalla.
- El rumbo se normaliza a `[0,360)`. La desviación firmada es positiva al girar en sentido horario desde objetivo a actual; se compara circularmente (359° y 1° difieren 2°).
- La tolerancia contractual es ±1.5° por eje y ±5° de rumbo. Flutter predice el estado, pero Node es la autoridad final.
- Foto JPEG/PNG: máximo 4 MiB. Se guarda en `api/almacen/fotos`, no como Base64 en PostgreSQL.
- La cámara, sensores y GPS usan hardware real y degradan con mensaje claro ante permiso denegado o error.
- El magnetómetro es sensible a inclinación y perturbaciones; el rumbo es más confiable con el teléfono plano y no equivale a un instrumento profesional calibrado. La compensación de inclinación queda fuera de este alcance.
