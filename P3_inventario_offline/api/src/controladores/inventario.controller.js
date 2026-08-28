const { pool, isPostgresConfigured } = require('../config/db');
const { procesarSincronizacion, memoriaStore, ITEMS_SEED } = require('../servicios/sincronizacion');

const listarItems = async (req, res, next) => {
  try {
    if (!isPostgresConfigured || !pool) {
      return res.status(200).json({ ok: true, items: Array.from(memoriaStore.items.values()) });
    }

    const result = await pool.query('SELECT * FROM item ORDER BY nombre ASC;');
    if (result.rows.length === 0) {
      for (const item of ITEMS_SEED) {
        await pool.query(
          `INSERT INTO item (id, codigo_barras, nombre, cantidad, estado, version, modificado_en)
           VALUES ($1, $2, $3, $4, $5, $6, NOW()) ON CONFLICT (id) DO NOTHING;`,
          [item.id, item.codigo_barras, item.nombre, item.cantidad, item.estado, item.version]
        );
      }
      const seeded = await pool.query('SELECT * FROM item ORDER BY nombre ASC;');
      return res.status(200).json({ ok: true, items: seeded.rows });
    }

    return res.status(200).json({ ok: true, items: result.rows });
  } catch (error) {
    next(error);
  }
};

const sincronizarDelta = async (req, res, next) => {
  try {
    const { ultimaSync, cambiosLocales } = req.body;
    const resultado = await procesarSincronizacion({ ultimaSync, cambiosLocales: cambiosLocales || [] });
    return res.status(200).json({ ok: true, ...resultado });
  } catch (error) {
    next(error);
  }
};

const resolverConflicto = async (req, res, next) => {
  try {
    const { id, conservar, valorElegido } = req.body; // conservar: 'servidor' | 'cliente'
    if (!id || !valorElegido) {
      return res.status(400).json({ ok: false, mensaje: 'Faltan campos id y valorElegido' });
    }

    if (!isPostgresConfigured || !pool) {
      const item = memoriaStore.items.get(id);
      if (item) {
        item.cantidad = Number(valorElegido.cantidad ?? item.cantidad);
        item.estado = valorElegido.estado ?? item.estado;
        if (valorElegido.fotoBase64) item.foto_base64 = valorElegido.fotoBase64;
        item.version += 1;
        item.modificado_en = new Date().toISOString();
      }
      return res.status(200).json({ ok: true, mensaje: 'Conflicto resuelto', item });
    }

    const updated = await pool.query(
      `UPDATE item SET
         cantidad = $1,
         estado = $2,
         foto_base64 = COALESCE($3, foto_base64),
         version = version + 1,
         modificado_en = NOW()
       WHERE id = $4 RETURNING *;`,
      [Number(valorElegido.cantidad), valorElegido.estado, valorElegido.fotoBase64 || null, id]
    );

    return res.status(200).json({ ok: true, mensaje: 'Conflicto resuelto correctamente', item: updated.rows[0] });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  listarItems,
  sincronizarDelta,
  resolverConflicto,
};
