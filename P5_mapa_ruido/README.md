# P5 — Mapa colaborativo de ruido

Aplicación Flutter para capturar el nivel sonoro relativo del micrófono,
asociarlo con GPS y enviarlo al backend en lotes de 20 muestras. PostgreSQL
calcula las estadísticas por celdas de aproximadamente 110 m y Flutter
visualiza únicamente esas celdas agregadas.

## Tecnologías

- Flutter, Riverpod, `record`, `geolocator`, `battery_plus`, Dio.
- Node.js, Express y `pg` con SQL directo.
- PostgreSQL/Supabase, columnas generadas, índice compuesto y vista SQL.
- `flutter_map` con OpenStreetMap, sin API key privada.

## Ejecución

```text
cd api
copy .env.example .env
```

Completar `.env` con la conexión existente de PostgreSQL y ejecutar:

```text
npm install
npm start
```

En `app/lib/core/configuracion.dart`, cambiar `apiBaseUrl` por la IP del PC
en la red local del teléfono si es necesario. No usar `localhost` en un
Android físico. Después:

```text
cd app
flutter pub get
flutter run
```

Aplicar una sola vez `api/sql/001_mapa_ruido.sql` sobre la base existente.
La migración es aditiva e idempotente y conserva las mediciones históricas.

## Flujo y arquitectura

Inicio → Medición o Mapa. La medición usa `AudioRecorder` y
`onAmplitudeChanged` cada 3 segundos, toma la última posición GPS válida,
acumula 20 muestras y las envía por Dio. Un lote fallido permanece pendiente
para reintento. El backend valida y guarda; la vista `mapa_ruido` agrupa por
celda y `GET /api/mapa` devuelve solo estadísticas.

La app conserva capas de modelos, fuentes API, repositorios, servicios,
providers Riverpod y pantallas.

## Limitación de medición

`nivelDb` es una escala relativa 0–100 derivada del dBFS de la amplitud del
micrófono. Un celular no es un sonómetro calibrado: estos valores no son dB
SPL absolutos ni sustituyen una medición profesional.

## Documentación

- [Contrato de API](docs/contrato-api.md)
- [Modelo de datos](docs/modelo-datos.md)
- [Decisiones técnicas](docs/decisiones.md)
