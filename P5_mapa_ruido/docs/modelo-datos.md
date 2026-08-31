# Modelo de datos — P5

## Tabla `muestras_ruido`

La base existente conserva su nombre e identificador UUID. La migración
`api/sql/001_mapa_ruido.sql` agrega de forma segura `sesion_id`, `celda_lat`,
`celda_lon` e índice, sin borrar las 20 mediciones históricas.

| Campo | Tipo | Descripción |
|---|---|---|
| `id` | UUID | Identificador de la muestra |
| `sesion_id` | UUID | Sesión común al lote recibido |
| `nivel_db` | DOUBLE PRECISION | Escala relativa 0–100 |
| `latitud` | DOUBLE PRECISION | Latitud GPS |
| `longitud` | DOUBLE PRECISION | Longitud GPS |
| `precision_m` | DOUBLE PRECISION | Precisión GPS en metros |
| `medido_en` | TIMESTAMPTZ | Instante de medición |
| `creado_en` | TIMESTAMPTZ | Instante de inserción |
| `celda_lat` | NUMERIC(7,3) | `ROUND(latitud, 3)`, columna generada |
| `celda_lon` | NUMERIC(7,3) | `ROUND(longitud, 3)`, columna generada |

El índice `idx_muestras_ruido_celda` cubre `(celda_lat, celda_lon)`.

## Vista `mapa_ruido`

PostgreSQL agrupa por las dos columnas generadas y calcula `AVG`, `MAX` y
`COUNT`. La vista redondea el promedio a una decimal y aplica
`HAVING COUNT(*) >= 5`; Flutter no descarga ni agrupa muestras crudas.

La escala es relativa y no equivale a dB SPL calibrados.
