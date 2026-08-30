# Contrato API REST - Proyecto 4: Asistencia biométrica

## Base URL

- Local: http://localhost:3003/api

## 1) Login

### Endpoint
POST /auth/login

### Request body
```json
{
  "documento": "1010123456",
  "password": "123456"
}
```

### Response success
```json
{
  "ok": true,
  "mensaje": "Autenticación exitosa",
  "tokens": {
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  },
  "usuario": {
    "id": 1,
    "documento": "1010123456",
    "nombre": "Carlos Aprendiz ADSO",
    "rol": "APRENDIZ",
    "sedeId": 1
  }
}
```

## 2) Renovar access token

### Endpoint
POST /auth/refresh

### Request body
```json
{
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

### Response success
```json
{
  "ok": true,
  "mensaje": "Tokens renovados correctamente (rotación transparente)",
  "tokens": {
    "accessToken": "nuevo_access_token",
    "refreshToken": "nuevo_refresh_token"
  }
}
```

## 3) Cerrar sesión

### Endpoint
POST /auth/logout

### Request body
```json
{
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

### Response success
```json
{
  "ok": true,
  "mensaje": "Sesión cerrada correctamente"
}
```

## 4) Registrar asistencia

### Endpoint
POST /asistencia/marcacion

### Header requerido
```http
Authorization: Bearer <accessToken>
```

### Request body
```json
{
  "tipo": "ENTRADA",
  "latitud": 4.65812,
  "longitud": -74.09354,
  "precisionM": 8.5,
  "timestamp": "2026-08-30T08:15:00.000Z"
}
```

### Casos de respuesta

#### A) Marcación aceptada
```json
{
  "ok": true,
  "mensaje": "Marcación de asistencia registrada exitosamente",
  "asistencia": {
    "id": "b3d7b0d2-2d2a-4d50-94b0-3d7f02c7f729",
    "usuarioId": 1,
    "sedeId": 1,
    "tipo": "ENTRADA",
    "latitud": 4.65812,
    "longitud": -74.09354,
    "precisionM": 8.5,
    "distanciaM": 18.42,
    "dentroPerimetro": true,
    "dentroHorario": true,
    "estado": "ACEPTADA",
    "registradoEn": "2026-08-30T08:15:00.000Z"
  }
}
```

#### B) Marcación rechazada por geocerca
```json
{
  "ok": false,
  "codigo": "GEOCERCA_RECHAZADA",
  "mensaje": "Marcación rechazada por regla de negocio: Fuera del perímetro del centro SENA",
  "asistencia": {
    "usuarioId": 1,
    "sedeId": 1,
    "tipo": "ENTRADA",
    "latitud": 4.7000,
    "longitud": -74.1000,
    "distanciaM": 4821.12,
    "dentroPerimetro": false,
    "dentroHorario": true,
    "estado": "RECHAZADA",
    "motivoRechazo": "Fuera del perímetro del centro SENA"
  }
}
```

## 5) Consultar mis asistencias

### Endpoint
GET /asistencia/mias

### Query params opcionales
- desde: ISO date
- hasta: ISO date
- pagina: número de página
- limite: número de registros

### Response success
```json
{
  "ok": true,
  "total": 1,
  "pagina": 1,
  "limite": 10,
  "asistencias": [
    {
      "id": "b3d7b0d2-2d2a-4d50-94b0-3d7f02c7f729",
      "usuarioId": 1,
      "tipo": "ENTRADA",
      "latitud": 4.65812,
      "longitud": -74.09354,
      "estado": "ACEPTADA",
      "registradoEn": "2026-08-30T08:15:00.000Z"
    }
  ]
}
```

## 6) Validaciones obligatorias del backend

1. La validación de geocerca se ejecuta en el servidor y nunca en la app móvil.
2. El access token debe expirar en un lapso corto, por ejemplo 15 minutos.
3. El refresh token debe rotarse automáticamente cada vez que se renueva sesión.
4. Las marcaciones offline se conservan con timestamp y coordenadas exactas originales.
5. Las respuestas de rechazo deben devolver un código explícito y el motivo del bloqueo.

## 7) Modelo de negocio

- Un usuario pertenece a una sede.
- Una asistencia se asocia a una sede y a un usuario.
- Cada asistencia registra latitud, longitud, precisión, distancia y estado.
- Los refresh tokens se gestionan por usuario y se pueden revocar.
- El estado final de la asistencia puede ser: `PENDIENTE`, `ACEPTADA` o `RECHAZADA`.
