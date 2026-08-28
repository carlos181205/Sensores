# P1 · Bitácora Sísmica CEET

Proyecto de desarrollo móvil full-stack con Flutter, Dart, Node.js, Express, PostgreSQL y SQLite para la detección, registro y sincronización offline de eventos de vibración e impacto de equipos de laboratorio.

---

## 📁 Estructura del Repositorio (Monorepo)

```text
P1_bitacora_sismica/
├── app/                  # Aplicación móvil en Flutter
│   ├── lib/
│   │   ├── datos/       # SQLite (DbHelper), Cliente API, Servicios de sensores
│   │   ├── presentacion/ # Interfaz de usuario (P1SismicaPage)
│   │   └── main.dart    # Punto de entrada
│   └── pubspec.yaml
├── api/                  # Backend Node.js + Express
│   ├── src/
│   │   ├── controladores/ # Lógica de negocio e idempotencia
│   │   ├── rutas/         # Endpoints de dispositivos y eventos
│   │   └── config/        # Conexión a PostgreSQL (con fallback local)
│   ├── database/
│   │   └── schema.sql     # Script DDL de base de datos
│   └── package.json
├── docs/                 # Documentación técnica obligatoria
│   ├── contrato-api.md   # Especificación REST API
│   └── decisiones.md     # Justificación de umbrales y calibraciones
└── README.md
```

---

## 🚀 Instrucciones de Ejecución

### 1. Backend (`/api`)

1. Navegar a la carpeta `api`:
   ```bash
   cd api
   ```
2. Instalar dependencias:
   ```bash
   npm install
   ```
3. (Opcional) Configurar las variables de entorno en un archivo `.env` o usar el motor en memoria integrado.
4. Iniciar el servidor:
   ```bash
   npm start
   # o para modo desarrollo:
   npm run dev
   ```
   El servidor se iniciará en `http://localhost:3000/api`.

---

### 2. Aplicación Móvil (`/app`)

1. Navegar a la carpeta `app`:
   ```bash
   cd app
   ```
2. Obtener dependencias de Flutter:
   ```bash
   flutter pub get
   ```
3. Ejecutar en un dispositivo Android físico:
   ```bash
   flutter run
   ```

---

## 🛠️ Especificaciones Técnicas

- **Fuerza G / Aceleración:** Utiliza `userAccelerometerEventStream()` para medir aceleración lineal sin la fuerza constante de la gravedad ($9.8 \text{ m/s}^2$).
- **Umbral de Activación:** $15.0 \text{ m/s}^2$ con reposo de $900 \text{ ms}$ para prevenir falsos positivos.
- **Idempotencia:** Evita registros duplicados mediante la clave compuesta `(dispositivo_id, clave_cliente)` y cláusula `ON CONFLICT` en el servidor.
- **Sincronización Offline:** Almacenamiento local en SQLite (`bitacora_ceet.db`) con envío por lotes automático al recuperar la conexión.
