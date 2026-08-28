# Decisiones de Diseño - Proyecto 2: Ronda Segura

## 1. Debate Técnico Obligatorio: Validación de Geocerca en el Servidor vs. App Móvil

### Pregunta Central
¿Por qué la validación de la geocerca se realiza en el **servidor (backend)** y no dentro del dispositivo móvil?

### Justificación Técnica
1. **Manipulabilidad del Cliente (APK):** Las aplicaciones móviles cliente pueden ser descompiladas, modificadas o burladas con herramientas de simulación de ubicación GPS (Fake GPS / Location Mocking).
2. **Principio de Seguridad Cero Confianza (Zero Trust):** Ninguna regla de negocio que un usuario tenga incentivo para evadir (como fingir estar en un punto de vigilancia sin haber caminado hasta allí) debe ser evaluada de forma exclusiva en el cliente.
3. **Imposibilidad de alteración en el Servidor:** La fórmula del semiverseno (**Haversine**) se ejecuta en la API backend utilizando las coordenadas reales almacenadas en la base de datos para cada `punto_control`.

---

## 2. Filtro de Precisión GPS (Umbral máximo: 30 m)

### Decisión
Se descartan automáticamente las lecturas de ubicación donde el campo `posicion.accuracy > 30.0` metros antes de realizar el escaneo o enviar al servidor.

### Justificación
- En interiores o zonas con mala cobertura de satélites GPS, el dispositivo puede reportar un margen de error (precisión) de 100 m o más.
- Aceptar una lectura con 150 m de error provocaría o bien falsos positivos (aceptar estar frente al punto cuando se está lejos) o rechazos injustos al usuario.
- Exigir una precisión de $\le 30 \text{ m}$ garantiza fiabilidad mínima en el dato capturado.

---

## 3. Tolerancia Dinámica de Geocerca

### Decisión
La distancia máxima tolerada para aceptar la marcación en un punto de control se calcula como:
$$\text{Tolerancia} = \text{radio\_m} + \min(\text{precision\_m}, 30)$$

### Justificación
- No castiga al vigilante si la señal del satélite presenta una pequeña fluctuación dentro de los 30 m aceptados.
- El radio base asignado al punto de control (ej. 40 m) absorbe las diferencias estructurales de los edificios.

---

## 4. Estrategia de Sincronización Offline

### Decisión
Cuando el equipo no cuenta con red móvil al momento del escaneo QR, el evento se guarda en la base de datos SQLite `ronda_segura.db` registrando:
1. Las coordenadas exactas en el instante del escaneo.
2. La hora original UTC del escaneo.

Al recuperar la conexión, el sincronizador envía los datos al backend pasando la fecha original (`escaneadaEn`). El servidor evalúa la geocerca usando las coordenadas y marca de tiempo originales.
