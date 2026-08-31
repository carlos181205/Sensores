const fs = require('node:fs');
const path = require('node:path');
const { cumpleMedicion, desviacionCircular } = require('../utilidades/azimut');

class ServicioVisitas {
  constructor({ repositorio, configuracion, almacenDir }) {
    this.repositorio = repositorio;
    this.configuracion = configuracion;
    this.almacenDir = almacenDir;
  }

  crearVisita(datos) { return this.repositorio.crearVisita(datos); }
  listarVisitas() { return this.repositorio.listarVisitas(); }

  async obtenerVisita(id) {
    const visita = await this.repositorio.buscarVisita(id);
    if (!visita) throw crearError('Visita no encontrada.', 404);
    return visita;
  }

  async crearMedicion(visitaId, datos, archivo) {
    const visita = await this.obtenerVisita(visitaId);
    if (Math.abs(datos.azimutObjetivo - visita.azimutObjetivo) > Number.EPSILON) {
      borrarArchivo(archivo.path);
      throw crearError('El azimut objetivo debe coincidir con el de la visita.', 422);
    }
    const desviacionAzimut = desviacionCircular(datos.azimut, visita.azimutObjetivo);
    const medicion = {
      visitaId: visita.id,
      ...datos,
      azimutObjetivo: visita.azimutObjetivo,
      desviacionAzimut,
      cumple: cumpleMedicion({ ...datos, azimutObjetivo: visita.azimutObjetivo }, this.configuracion),
      fotoRuta: path.basename(archivo.path),
    };
    return this.repositorio.crearMedicion(medicion);
  }

  async listarMediciones(visitaId) {
    await this.obtenerVisita(visitaId);
    return this.repositorio.listarMediciones(visitaId);
  }
}

function borrarArchivo(ruta) { fs.unlink(ruta, () => {}); }
function crearError(mensaje, estado) { return Object.assign(new Error(mensaje), { estado }); }

module.exports = { ServicioVisitas, crearError };
