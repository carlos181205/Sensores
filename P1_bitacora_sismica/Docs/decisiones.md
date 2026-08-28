# Decisiones de diseño - Proyecto 1: Bitácora sísmica CEET

## 1) Umbral de impacto: 15.0 m/s²

Se eligió un umbral de 15.0 m/s² como punto de activación para un evento sísmico detectado por el acelerómetro.

### Justificación
- Este valor permite distinguir movimientos cotidianos de vibraciones o golpes bruscos relevantes.
- Un valor demasiado bajo aumentaría el número de falsos positivos por movimientos normales del dispositivo.
- Un valor demasiado alto podría ocultar impactos severos y perder eventos relevantes del monitoreo.

### Evidencia de prueba aproximada
En pruebas iniciales de laboratorio con un teléfono en mano y movimiento casual, valores por encima de 10 m/s² se presentaban con frecuencia por desplazamientos cotidianos. En cambio, valores superiores a 15 m/s² aparecían con mayor consistencia en golpes intensos o vibraciones abruptas, lo que reduce ruido y aumenta relevancia.

## 2) Tiempo de reposo entre impactos: 900 ms

Se definió un tiempo de reposo de 900 ms (0.9 segundos) para filtrar eventos duplicados producidos por un mismo impacto continuo.

### Justificación
- Un evento de aceleración puede producir varias lecturas consecutivas en el mismo golpe.
- Sin un filtro, se generarían duplicados por la misma vibración.
- Con 900 ms, el sistema acepta un nuevo evento solo si ha transcurrido suficiente tiempo desde el último impacto.

### Evidencia de prueba aproximada
En pruebas manuales, un golpe fuerte genera múltiples muestras consecutivas dentro de 200–500 ms. El filtro de 900 ms redujo significativamente los dobles registros sin comprometer la detección real de eventos separados.

## 3) Idempotencia por claveCliente y dispositivo

Se decidió usar la combinación de `dispositivo_id + clave_cliente` como clave de idempotencia.

### Justificación
- Un evento detectado en el mismo dispositivo no debe registrarse dos veces si el mismo impacto se reintenta por pérdida de red.
- La claveCliente se genera desde el timestamp o identificador local del evento para que el backend pueda reconocer un evento repetido.
- En la base de datos se aplica una restricción UNIQUE en la combinación `(dispositivo_id, clave_cliente)`.

### Estructura de la regla
```sql
CONSTRAINT uq_dispositivo_clave UNIQUE (dispositivo_id, clave_cliente)
```

### Beneficio técnico
- Evita duplicados al reenviar la cola cuando la red vuelve.
- Facilita la reintentos seguros.
- Conserva trazabilidad exacta para cada impacto detectado.

## 4) Estrategia general de sincronización

Cuando el celular no tiene acceso a red, el evento se guarda en SQLite y se marca como pendiente. Cuando se recupera la conexión, el cliente reenvía la cola completa con lote y el backend usa `ON CONFLICT` para mantener la consistencia.

### Resultado esperado
- Datos no perdidos en modo offline.
- Duplicados evitados por idempotencia.
- Operación segura al recuperar conectividad.
