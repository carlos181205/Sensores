# Contrato API - Proyecto 1: Bitácora sísmica CEET

## Base URL

- Local: http://localhost:3000/api

## 1) Registrar dispositivo

### Endpoint
POST /dispositivos

### Request body
```json
{
  "dispositivoId": "celular_ceet_01",
  "nombre": "Samsung A54",
  "modelo": "SM-A546B",
  "versionFirmware": "1.0.0"
}
```

### Response success
```json
{
  "ok": true,
  "mensaje": "Dispositivo registrado correctamente",
  "dispositivo": {
    "id": 1,
    "dispositivo_id": "celular_ceet_01",
    "nombre": "Samsung A54",
    "modelo": "SM-A546B",
    "version_firmware": "1.0.0",
    "fecha_registro": "2026-08-28T12:00:00.000Z"
  }
}
```

## 2) Registrar evento individual

### Endpoint
POST /eventos

### Request body
```json
{
  "dispositivoId": "celular_ceet_01",
  "claveCliente": "evt-001",
  "intensidad": 19.8,
  "latitud": 4.7110,
  "longitud": -74.0721,
  "descripcion": "Impacto sísmico detectado",
  "fechaEvento": "2026-08-28T12:00:00.000Z"
}
```

### Response success
```json
{
  "ok": true,
  "mensaje": "Evento registrado correctamente",
  "evento": {
    "id": 1,
    "dispositivo_id": "celular_ceet_01",
    "clave_cliente": "evt-001",
    "intensidad": 19.8,
    "latitud": 4.711,
    "longitud": -74.0721,
    "descripcion": "Impacto sísmico detectado",
    "fecha_evento": "2026-08-28T12:00:00.000Z",
    "severidad": "leve"
  },
  "idempotente": true
}
```

## 3) Reenvío por lote

### Endpoint
POST /eventos/lote

### Request body
```json
{
  "eventos": [
    {
      "dispositivoId": "celular_ceet_01",
      "claveCliente": "evt-001",
      "intensidad": 18.7,
      "latitud": 4.7110,
      "longitud": -74.0721,
      "descripcion": "Impacto 1",
      "fechaEvento": "2026-08-28T12:00:00.000Z"
    },
    {
      "dispositivoId": "celular_ceet_01",
      "claveCliente": "evt-002",
      "intensidad": 32.5,
      "latitud": 4.7120,
      "longitud": -74.0730,
      "descripcion": "Impacto 2",
      "fechaEvento": "2026-08-28T12:05:00.000Z"
    }
  ]
}
```

### Response success
```json
{
  "ok": true,
  "mensaje": "Lote sincronizado",
  "total": 2,
  "resultados": [
    {
      "ok": true,
      "evento": {
        "dispositivo_id": "celular_ceet_01",
        "clave_cliente": "evt-001"
      }
    }
  ]
}
```

## 4) Consultar historial

### Endpoint
GET /eventos

### Query params opcionales
- desde: fecha ISO inicial
- hasta: fecha ISO final
- severidad: leve | moderado | fuerte
- pagina: número de página
- limite: número de registros por página

### Example
```http
GET /eventos?desde=2026-08-01T00:00:00.000Z&hasta=2026-08-31T23:59:59.000Z&severidad=moderado&pagina=1&limite=10
```

### Response success
```json
{
  "ok": true,
  "total": 1,
  "pagina": 1,
  "limite": 10,
  "eventos": [
    {
      "id": 5,
      "dispositivo_id": "celular_ceet_01",
      "clave_cliente": "evt-002",
      "intensidad": 32.5,
      "latitud": 4.712,
      "longitud": -74.073,
      "descripcion": "Impacto 2",
      "fecha_evento": "2026-08-28T12:05:00.000Z",
      "severidad": "moderado"
    }
  ]
}
```

## 5) Resumen por severidad

### Endpoint
GET /eventos/resumen

### Query params opcionales
- desde
- hasta
- severidad

### Example
```http
GET /eventos/resumen?desde=2026-08-01T00:00:00.000Z&hasta=2026-08-31T23:59:59.000Z
```

### Response success
```json
{
  "ok": true,
  "total": 8,
  "resumen": {
    "leve": 3,
    "moderado": 3,
    "fuerte": 2
  }
}
```
