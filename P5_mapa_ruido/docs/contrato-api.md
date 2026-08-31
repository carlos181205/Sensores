# Contrato de API — P5

Base URL: `/api`

## POST `/api/muestras`

Registra un lote de exactamente 20 muestras. El servidor valida la forma,
tipos, coordenadas, precisión, nivel relativo 0–100 y fechas antes de tocar
PostgreSQL.

Solicitud (cada elemento debe incluir los cinco campos; el arreglo completo
debe tener 20 elementos):

```json
{
  "muestras": [
    {
      "nivelDb": 65.2,
      "latitud": 4.6097,
      "longitud": -74.0817,
      "precisionM": 8.5,
      "medidoEn": "2026-08-30T18:30:00.000Z"
    }
  ]
}
```

Respuesta `201`:

```json
{
  "ok": true,
  "mensaje": "Lote de muestras guardado correctamente.",
  "cantidad": 20
}
```

`400` indica contrato, cantidad o tipos inválidos; `422` indica valores
fuera de rango o fechas inválidas; `500` indica un error interno. Un lote
rechazado no se inserta parcialmente.

## GET `/api/muestras`

Conservado para inspección y devuelve muestras crudas. No debe usarse para
construir el mapa final.

## GET `/api/mapa`

Consulta la vista PostgreSQL `mapa_ruido` y devuelve únicamente celdas con al
menos 5 muestras:

```json
{
  "ok": true,
  "datos": [
    {
      "celdaLat": 4.61,
      "celdaLon": -74.082,
      "promedioDb": 61.4,
      "maximoDb": 73.2,
      "muestras": 23
    }
  ]
}
```

No se envían `id`, coordenadas individuales, precisión ni fechas al cliente
del mapa. `200` es una respuesta válida también cuando `datos` está vacío;
`500` informa que no se pudo consultar el mapa.
