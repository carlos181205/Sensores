# Modelo de datos

`p6_visitas` representa una unidad de trabajo: identificador, azimut objetivo, inicio y finalización. `p6_mediciones` tiene FK no destructiva a la visita, inclinaciones X/Y, rumbo, desviación, coordenadas opcionales si GNSS no está disponible, resultado final, ruta de foto y fecha medida.

Los índices `p6_mediciones(visita_id, medido_en)` y `p6_visitas(inicia_en DESC)` aceleran el reporte y la consulta. La migración es aditiva e idempotente; no modifica datos de P5 ni de otros proyectos.
