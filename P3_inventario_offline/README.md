# P3 · Inventario CEET Sin Conexión

Toma física de inventario de equipos de laboratorio en ambientes sin señal (sótanos), con escaneo de códigos de barras (EAN-13 / Code-128), fotos comprimidas (`< 300 KB`) y sincronización por diferencias (delta) con bloqueo optimista por versión.

---

## 📁 Estructura del Repositorio

```text
P3_inventario_offline/
├── app/                  # Aplicación móvil Flutter (Mobile Scanner + SQLite)
├── api/                  # Backend Node.js + Express (Sync Delta & Bloqueo Optimista)
├── docs/                 # Documentación técnica obligatoria
│   ├── contrato-api.md   # Especificación de Endpoints y /sync
│   └── decisiones.md     # Justificación técnica de Bloqueo Optimista vs Last-Write-Wins
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
   El backend se ejecutará en `http://localhost:3002/api`.

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

- **Modo Avión Completo:** Funciona 100% sin conexión usando la base de datos SQLite `inventario_ceet.db`.
- **Bloqueo Optimista:** Detecta conflictos si el servidor avanzó de versión mientras el cliente estuvo desconectado.
- **Resolución de Conflictos:** Presenta una pantalla interactiva (`resolucion_conflictos_page.dart`) para elegir entre Versión Servidor vs Versión Cliente.
- **Compresión de Imagen:** Fotos de averías ajustadas a máximo $300 \text{ KB}$.
