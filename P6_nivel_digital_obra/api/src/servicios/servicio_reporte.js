const fs = require('node:fs');
const path = require('node:path');
const PDFDocument = require('pdfkit');

class ServicioReporte {
  constructor({ servicioVisitas, almacenDir }) {
    this.servicioVisitas = servicioVisitas;
    this.almacenDir = almacenDir;
  }

  async generar(visitaId) {
    const visita = await this.servicioVisitas.obtenerVisita(visitaId);
    const mediciones = await this.servicioVisitas.listarMediciones(visitaId);
    const documento = new PDFDocument({ margin: 42, autoFirstPage: true });
    const partes = [];
    documento.on('data', (parte) => partes.push(parte));
    const terminado = new Promise((resolver) => documento.on('end', resolver));
    documento.fontSize(20).text('Nivel digital de obra — Reporte de visita');
    documento.moveDown().fontSize(11);
    documento.text(`Visita: ${visita.identificador}`);
    documento.text(`Inicio: ${new Date(visita.iniciaEn).toLocaleString('es-CO')}`);
    documento.text(`Azimut objetivo: ${Number(visita.azimutObjetivo).toFixed(1)}°`);
    documento.moveDown();
    for (const [indice, medicion] of mediciones.entries()) {
      documento.fontSize(13).text(`Medición ${indice + 1}: ${medicion.cumple ? 'CUMPLE' : 'NO CUMPLE'}`);
      documento.fontSize(10).text(`Fecha: ${new Date(medicion.medidoEn).toLocaleString('es-CO')}`);
      documento.text(`X: ${medicion.inclinacionX.toFixed(1)}° | Y: ${medicion.inclinacionY.toFixed(1)}°`);
      documento.text(`Azimut: ${medicion.azimut.toFixed(1)}° | Desviación: ${medicion.desviacionAzimut.toFixed(1)}°`);
      documento.text(`GPS: ${medicion.latitud ?? 'sin dato'}, ${medicion.longitud ?? 'sin dato'}`);
      const foto = path.join(this.almacenDir, 'fotos', medicion.fotoRuta);
      if (fs.existsSync(foto)) {
        try { documento.moveDown(0.4).image(foto, { fit: [480, 330], align: 'center' }); } catch (_) { documento.text('No se pudo incrustar la fotografía.'); }
      }
      if (indice < mediciones.length - 1) documento.addPage();
    }
    documento.end();
    await terminado;
    return Buffer.concat(partes);
  }
}

module.exports = { ServicioReporte };
