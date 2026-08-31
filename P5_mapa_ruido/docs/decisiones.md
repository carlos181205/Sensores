# Decisiones técnicas — P5

- **Lotes:** se acumulan exactamente 20 muestras y se hace una petición HTTP
  por lote. El lote solo se limpia después de una respuesta exitosa; si falla,
  queda pendiente y se reintenta mientras la captura sigue activa.
- **Batería:** `MIN_BATTERY_PERCENT` es `15`. Se consulta el nivel antes de
  comenzar y se sondea durante la captura; por debajo del umbral se detienen
  micrófono, GPS y listener de batería sin cerrar la aplicación.
- **GPS:** `distanceFilterMeters` es `15` y está centralizado en
  `ConfiguracionP5`. Se descartan posiciones con precisión mayor a 40 m.
- **Celdas:** latitud y longitud se redondean a 3 decimales en columnas
  generadas de PostgreSQL (aproximadamente 110 m). Solo aparecen celdas con
  al menos 5 muestras.
- **Nivel:** `record` entrega amplitud en dBFS; `NivelRuidoService` la
  transforma una sola vez a una escala relativa 0–100. `nivelDb` representa
  esa escala relativa, no dB SPL calibrados.
- **Limitación:** el micrófono y su ganancia dependen del teléfono. El
  resultado sirve para comparar zonas o momentos del mismo dispositivo, no
  como medición ambiental oficial o de sonómetro.
- **Mapa:** `flutter_map` y OpenStreetMap muestran datos agregados recibidos
  de `GET /api/mapa`; el cliente nunca construye el mapa desde muestras
  individuales.
- **URL:** la IP de desarrollo está centralizada en
  `app/lib/core/configuracion.dart`; debe cambiarse por la IP local del PC
  cuando la red sea diferente.
