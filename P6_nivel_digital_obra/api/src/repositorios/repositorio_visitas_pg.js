class RepositorioVisitasPg {
  constructor(pool) { this.pool = pool; }

  async crearVisita(visita) {
    const resultado = await this.pool.query(
      'INSERT INTO p6_visitas (identificador, azimut_objetivo) VALUES ($1, $2) RETURNING *',
      [visita.identificador, visita.azimutObjetivo],
    );
    return aVisita(resultado.rows[0]);
  }

  async listarVisitas() {
    const resultado = await this.pool.query('SELECT * FROM p6_visitas ORDER BY inicia_en DESC');
    return resultado.rows.map(aVisita);
  }

  async buscarVisita(id) {
    const resultado = await this.pool.query('SELECT * FROM p6_visitas WHERE id = $1', [id]);
    return resultado.rows[0] ? aVisita(resultado.rows[0]) : null;
  }

  async crearMedicion(medicion) {
    const resultado = await this.pool.query(
      `INSERT INTO p6_mediciones (visita_id, inclinacion_x, inclinacion_y, azimut, azimut_objetivo, desviacion_azimut, latitud, longitud, cumple, foto_ruta, medido_en)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11) RETURNING *`,
      [medicion.visitaId, medicion.inclinacionX, medicion.inclinacionY, medicion.azimut, medicion.azimutObjetivo, medicion.desviacionAzimut, medicion.latitud, medicion.longitud, medicion.cumple, medicion.fotoRuta, medicion.medidoEn],
    );
    return aMedicion(resultado.rows[0]);
  }

  async listarMediciones(visitaId) {
    const resultado = await this.pool.query('SELECT * FROM p6_mediciones WHERE visita_id = $1 ORDER BY medido_en', [visitaId]);
    return resultado.rows.map(aMedicion);
  }
}

function aVisita(fila) {
  return { id: fila.id, identificador: fila.identificador, azimutObjetivo: Number(fila.azimut_objetivo), iniciaEn: fila.inicia_en, terminaEn: fila.termina_en };
}
function aMedicion(fila) {
  return { id: fila.id, visitaId: fila.visita_id, inclinacionX: Number(fila.inclinacion_x), inclinacionY: Number(fila.inclinacion_y), azimut: Number(fila.azimut), azimutObjetivo: Number(fila.azimut_objetivo), desviacionAzimut: Number(fila.desviacion_azimut), latitud: fila.latitud === null ? null : Number(fila.latitud), longitud: fila.longitud === null ? null : Number(fila.longitud), cumple: fila.cumple, fotoRuta: fila.foto_ruta, medidoEn: fila.medido_en, creadoEn: fila.creado_en };
}

module.exports = { RepositorioVisitasPg };
