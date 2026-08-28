# Contrato API - Proyecto 2: Ronda Segura

## Base URL
- Local: `http://localhost:3001/api`

---

## 1) Consultar catálogo de puntos de control
### Endpoint
`GET /puntos`

### Response 200 OK
```json
{
  "ok": true,
  "puntos": [
    {
      "id": 1,
      "codigo": "PUNTO-01",
      "nombre": "Entrada Principal CEET",
      "latitud": 4.6581,
      "longitud": -74.0935,
      "radio_m": 40,
      "orden": 1
    }
  ]
}
```

---

## 2) Iniciar nueva ronda
### Endpoint
`POST /rondas`

### Request Body
```json
{
  "usuarioId": 1
}
```

### Response 201 Created
```json
{
  "ok": true,
  "mensaje": "Ronda iniciada correctamente",
  "ronda": {
    "id": "e8d1a2b3-...",
    "usuario_id": 1,
    "inicia_en": "2026-08-28T14:00:00.000Z",
    "vence_en": "2026-08-28T14:45:00.000Z",
    "estado": "en_curso"
  }
}
```

---

## 3) Registrar marcación (Validación de Geocerca)
### Endpoint
`POST /rondas/:id/marcaciones`

### Request Body
```json
{
  "codigo": "PUNTO-01",
  "latitud": 4.65812,
  "longitud": -74.09351,
  "precisionM": 12.5,
  "escaneadaEn": "2026-08-28T14:05:00.000Z"
}
```

### Response 201 Created (Geocerca Valida)
```json
{
  "ok": true,
  "mensaje": "Marcación aceptada por el servidor",
  "marcacion": {
    "id": "m9a8b7c6-...",
    "ronda_id": "e8d1a2b3-...",
    "punto_id": 1,
    "latitud": 4.65812,
    "longitud": -74.09351,
    "precision_m": 12.5,
    "distancia_m": 2.84,
    "aceptada": true,
    "motivo_rechazo": null,
    "escaneada_en": "2026-08-28T14:05:00.000Z"
  }
}
```

### Response 422 Unprocessable Entity (Geocerca Rechazada)
```json
{
  "ok": false,
  "mensaje": "Marcación rechazada por geocerca",
  "marcacion": {
    "distancia_m": 350.2,
    "aceptada": false,
    "motivo_rechazo": "Fuera de rango: 350 m (Tolerancia: 52.5 m)"
  }
}
```

---

## 4) Consultar estado de la ronda
### Endpoint
`GET /rondas/:id`

### Response 200 OK
```json
{
  "ok": true,
  "avance": {
    "totalPuntos": 4,
    "puntosVisitados": 3,
    "puntosPendientes": 1,
    "completada": false
  },
  "puntos": [...],
  "marcaciones": [...]
}
```
