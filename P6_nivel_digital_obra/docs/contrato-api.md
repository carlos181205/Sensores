# Contrato API

- `GET /health`: `{ "estado": "ok" }`.
- `POST /api/visitas`: JSON `{ identificador, azimutObjetivo }`, crea una visita. El azimut debe estar en `[0,360)`.
- `GET /api/visitas` y `GET /api/visitas/:id`: consulta visitas.
- `POST /api/visitas/:id/mediciones`: una sola petición `multipart/form-data` con `foto` JPEG/PNG (máximo 4 MB), `inclinacionX`, `inclinacionY`, `azimut`, `azimutObjetivo`, `desviacionAzimut`, `latitud`, `longitud`, `cumple` y `medidoEn`. El servidor no confía en los campos calculados: adopta el objetivo de la visita, recalcula desviación y cumplimiento.
- `GET /api/visitas/:id/mediciones`: lista mediciones.
- `GET /api/visitas/:id/reporte`: devuelve PDF descargable.

Los errores son JSON: `{ "error": "mensaje claro" }`. Se rechazan MIME no permitidos, foto faltante, más de 4 MB y valores numéricos inválidos.
