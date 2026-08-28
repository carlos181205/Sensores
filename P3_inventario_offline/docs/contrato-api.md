# Contrato API - Proyecto 3: Inventario CEET Sin Conexión

## Base URL
- Local: `http://localhost:3002/api`

---

## 1) Consultar catálogo completo
### Endpoint
`GET /items`

### Response 200 OK
```json
{
  "ok": true,
  "items": [
    {
      "id": "item-001",
      "codigo_barras": "7701234567890",
      "nombre": "Multímetro Digital Fluke 177",
      "cantidad": 10,
      "estado": "bueno",
      "version": 1,
      "modificado_en": "2026-08-28T14:00:00.000Z"
    }
  ]
}
```

---

## 2) Sincronización Delta por Versión (Bloqueo Optimista)
### Endpoint
`POST /sync`

### Request Body
```json
{
  "ultimaSync": "2026-08-28T14:00:00.000Z",
  "cambiosLocales": [
    {
      "id": "item-001",
      "codigo_barras": "7701234567890",
      "nombre": "Multímetro Digital Fluke 177",
      "cantidad": 12,
      "estado": "averiado",
      "version": 1,
      "foto_base64": "data:image/jpeg;base64,...",
      "modificado_en": "2026-08-28T14:30:00.000Z"
    }
  ]
}
```

### Response 200 OK
```json
{
  "ok": true,
  "aplicados": ["item-001"],
  "conflictos": [
    {
      "id": "item-002",
      "versionServidor": 7,
      "versionCliente": 5,
      "valorServidor": { "cantidad": 9, "estado": "bueno" },
      "valorCliente": { "cantidad": 11, "estado": "averiado" }
    }
  ],
  "cambiosRemotos": [
    {
      "id": "item-003",
      "version": 2,
      "cantidad": 8
    }
  ],
  "servidorEn": "2026-08-28T14:45:00.000Z"
}
```

---

## 3) Resolver Conflicto de Versión
### Endpoint
`POST /items/resolver-conflicto`

### Request Body
```json
{
  "id": "item-002",
  "conservar": "cliente",
  "valorElegido": {
    "cantidad": 11,
    "estado": "averiado"
  }
}
```

### Response 200 OK
```json
{
  "ok": true,
  "mensaje": "Conflicto resuelto correctamente",
  "item": {
    "id": "item-002",
    "version": 8,
    "cantidad": 11,
    "estado": "averiado"
  }
}
```
