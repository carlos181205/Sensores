# P6 — Nivel digital de obra

Aplicación Flutter y API Node.js para verificar la instalación de mástiles de telecomunicaciones con acelerómetro, giroscopio, magnetómetro, cámara y GNSS reales. La captura usa un único `MedicionSnapshot` para el overlay, la imagen anotada y la solicitud multipart; el servidor recalcula la conformidad, persiste los datos en PostgreSQL y genera el PDF de la visita.

## Ejecución

1. Cree `api/.env` desde `api/.env.example`, complete solo la conexión PostgreSQL y aplique `api/sql/001_nivel_digital_obra.sql`.
2. En `api`, ejecute `npm install` y `npm start`.
3. En `app`, ejecute `flutter pub get` y `flutter run --dart-define=API_BASE_URL=http://IP_DEL_PC:3000`. En Android físico no use `localhost`.

## Pruebas

Ejecute `flutter analyze` y `flutter test` en `app`; ejecute `npm test` en `api`. Consulte [arquitectura](docs/arquitectura.md), [contrato API](docs/contrato-api.md), [modelo de datos](docs/modelo-datos.md) y [decisiones](docs/decisiones.md).

## Limitación importante

El magnetómetro es más fiable con el teléfono plano. Al inclinarlo, cambia la proyección del campo magnético y el rumbo puede desviarse. Esta aplicación no sustituye instrumentos profesionales calibrados; la compensación de inclinación magnética queda como extensión futura.
