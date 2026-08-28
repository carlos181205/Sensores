# Decisiones de Diseño - Proyecto 3: Inventario CEET Sin Conexión

## 1. Bloqueo Optimista por Versión (`version`) vs. El Último que Escriba Gana

### Justificación Técnica
- **El problema de la alternativa ingenua ("El último que escriba gana"):** Si dos aprendices descargan el catálogo en la mañana (ambos con `version = 1`), y el Aprendiz A modifica la cantidad del Multímetro a las 10:00 AM y sincroniza (subiendo a `version = 2`), cuando el Aprendiz B suba sus datos a las 11:00 AM sobreescribiría silenciosamente el trabajo de su compañero sin que nadie lo note.
- **La solución con Bloqueo Optimista:** Cada registro incluye un campo entero `version`. Al intentar actualizar, la consulta SQL exige `WHERE id = $1 AND version = $2`.
- Si la versión en la base de datos es `7` y el cliente envía `5`, el backend detecta inmediatamente el descalce y devuelve un objeto de **conflicto explícito**.

---

## 2. Estrategia de Sincronización Delta (Por Diferencias)

### Justificación
- Se utiliza una bandera local en SQLite `sucio = 1` (dirty flag).
- La app **únicamente reenvía los registros que fueron editados durante la toma física** (`WHERE sucio = 1`).
- Esto reduce drásticamente el consumo de ancho de banda y evita reenviar cientos de ítems intactos.

---

## 3. Compresión de Fotografías de Averías (< 300 KB)

### Justificación
- Los sensores de cámara de smartphones modernos capturan fotos de 8 MB a 15 MB.
- Al tomar decenas de fotos de equipos averiados en un sótano sin red, guardar fotos pesadas agotaría el almacenamiento local de SQLite y colapsaría el ancho de banda al sincronizar.
- Se configura `ImagePicker` con un ancho máximo de `600px` y calidad `50%`, garantizando imágenes nítidas comprimidas por debajo de los **300 KB**.
