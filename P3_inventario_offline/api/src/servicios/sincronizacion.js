const { pool, isPostgresConfigured } = require('../config/db');

// Catálogo por defecto para pruebas y modo en memoria
const ITEMS_SEED = [
  { id: 'item-001', codigo_barras: '7701234567890', nombre: 'Multímetro Digital Fluke 177', cantidad: 10, estado: 'bueno', version: 1, modificado_en: new Date().toISOString() },
  { id: 'item-002', codigo_barras: '7709876543210', nombre: 'Osciloscopio Tektronix 200MHz', cantidad: 4, estado: 'bueno', version: 1, modificado_en: new Date().toISOString() },
  { id: 'item-003', codigo_barras: '7701122334455', nombre: 'Generador de Funciones Rigol', cantidad: 8, estado: 'bueno', version: 1, modificado_en: new Date().toISOString() },
  { id: 'item-004', codigo_barras: '7705566778899', nombre: 'Fuente de Poder Regulada DC', cantidad: 12, estado: 'bueno', version: 1, modificado_en: new Date().toISOString() },
];

const memoriaStore = {
  items: new Map(ITEMS_SEED.map((i) => [i.id, { ...i }])),
};

async function procesarSincronizacion({ ultimaSync, cambiosLocales = [] }) {
  const aplicados = [];
  const conflictos = [];

  const fechaSync = ultimaSync ? new Date(ultimaSync) : new Date(0);

  // 1. Procesar los cambios locales enviados por la app cliente
  for (const c of cambiosLocales) {
    if (!c.id) continue;

    if (!isPostgresConfigured || !pool) {
      // Modo local en memoria
      const actual = memoriaStore.items.get(c.id);
      if (!actual) {
        // Nuevo registro creado offline
        const nuevo = {
          id: c.id,
          codigo_barras: c.codigoBarras || c.codigo_barras,
          nombre: c.nombre || 'Equipo de laboratorio',
          cantidad: Number(c.cantidad || 1),
          estado: c.estado || 'bueno',
          version: Number(c.version || 1) + 1,
          foto_base64: c.fotoBase64 || c.foto_base64 || null,
          modificado_en: new Date().toISOString(),
        };
        memoriaStore.items.set(c.id, nuevo);
        aplicados.push(c.id);
      } else if (actual.version === Number(c.version)) {
        // La versión coincide: Actualización limpia (Bloqueo optimista exitoso)
        actual.cantidad = Number(c.cantidad);
        actual.estado = c.estado;
        if (c.fotoBase64 || c.foto_base64) actual.foto_base64 = c.fotoBase64 || c.foto_base64;
        actual.version += 1;
        actual.modificado_en = new Date().toISOString();
        aplicados.push(c.id);
      } else {
        // Conflicto de versión: La versión del servidor cambió (ej. servidor 7, cliente 5)
        conflictos.push({
          id: c.id,
          versionServidor: actual.version,
          versionCliente: Number(c.version),
          valorServidor: { cantidad: actual.cantidad, estado: actual.estado, fotoBase64: actual.foto_base64 },
          valorCliente: { cantidad: Number(c.cantidad), estado: c.estado, fotoBase64: c.fotoBase64 || c.foto_base64 },
        });
      }
    } else {
      // Modo PostgreSQL
      const dbRes = await pool.query('SELECT * FROM item WHERE id = $1;', [c.id]);
      const actual = dbRes.rows[0];

      if (!actual) {
        await pool.query(
          `INSERT INTO item (id, codigo_barras, nombre, cantidad, estado, version, foto_base64, modificado_en)
           VALUES ($1, $2, $3, $4, $5, $6, $7, NOW());`,
          [c.id, c.codigoBarras || c.codigo_barras, c.nombre || 'Equipo', Number(c.cantidad || 1), c.estado || 'bueno', Number(c.version || 1) + 1, c.fotoBase64 || c.foto_base64 || null]
        );
        aplicados.push(c.id);
      } else if (actual.version === Number(c.version)) {
        await pool.query(
          `UPDATE item SET
             cantidad = $1,
             estado = $2,
             foto_base64 = COALESCE($3, foto_base64),
             version = version + 1,
             modificado_en = NOW()
           WHERE id = $4 AND version = $5;`,
          [Number(c.cantidad), c.estado, c.fotoBase64 || c.foto_base64 || null, c.id, Number(c.version)]
        );
        aplicados.push(c.id);
      } else {
        conflictos.push({
          id: c.id,
          versionServidor: actual.version,
          versionCliente: Number(c.version),
          valorServidor: { cantidad: actual.cantidad, estado: actual.estado, fotoBase64: actual.foto_base64 },
          valorCliente: { cantidad: Number(c.cantidad), estado: c.estado, fotoBase64: c.fotoBase64 || c.foto_base64 },
        });
      }
    }
  }

  // 2. Obtener cambios remotos ocurridos en el servidor después de `ultimaSync`
  let cambiosRemotos = [];
  if (!isPostgresConfigured || !pool) {
    cambiosRemotos = Array.from(memoriaStore.items.values()).filter(
      (item) => new Date(item.modificado_en) > fechaSync && !aplicados.includes(item.id)
    );
  } else {
    const remotosRes = await pool.query(
      'SELECT * FROM item WHERE modificado_en > $1;',
      [fechaSync.toISOString()]
    );
    cambiosRemotos = remotosRes.rows.filter((item) => !aplicados.includes(item.id));
  }

  return {
    aplicados,
    conflictos,
    cambiosRemotos,
    servidorEn: new Date().toISOString(),
  };
}

module.exports = {
  ITEMS_SEED,
  memoriaStore,
  procesarSincronizacion,
};
