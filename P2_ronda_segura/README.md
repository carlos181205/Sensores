# P2 · Ronda Segura

Sistema de control de rondas de vigilancia con escaneo de códigos QR y validación estricta de geocerca en el servidor mediante la fórmula Haversine.

---

## 📁 Estructura del Repositorio

```text
P2_ronda_segura/
├── app/                  # Aplicación móvil Flutter (Mobile Scanner + GPS)
├── api/                  # Backend Node.js + Express (Haversine & Geocercas)
├── docs/                 # Documentación técnica obligatoria
│   ├── contrato-api.md   # Especificación de Endpoints
│   └── decisiones.md     # Debate técnico de geocerca en el servidor
└── README.md
```

---

## 🚀 Instrucciones de Ejecución

### 1. Servidor Backend (`/api`)

1. Entrar a la carpeta `api`:
   ```bash
   cd api
   ```
2. Instalar dependencias:
   ```bash
   npm install
   ```
3. Iniciar el servidor:
   ```bash
   npm start
   ```
   El backend se ejecutará en `http://localhost:3001/api`.

---

### 2. Aplicación Móvil (`/app`)

1. Entrar a la carpeta `app`:
   ```bash
   cd app
   ```
2. Obtener paquetes de Flutter:
   ```bash
   flutter pub get
   ```
3. Ejecutar en dispositivo Android físico:
   ```bash
   flutter run
   ```

---

## 🛠️ Reglas del Proyecto

- **Geocerca en Servidor:** La distancia en metros entre la ubicación reportada por el celular y las coordenadas guardadas del punto de control se calcula en el servidor usando **Haversine**.
- **Filtro GPS:** Se rechazan lecturas con imprecisión mayor a $30 \text{ m}$.
- **Feedback Háptico e Inmediato:** El color de pantalla y la vibración responden inmediatamente tras el escaneo.
- **Sincronización Offline:** Permite escaneos sin conexión guardando la hora y coordenadas originales en SQLite.
