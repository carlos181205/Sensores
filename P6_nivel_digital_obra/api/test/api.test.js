const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const test = require('node:test');
const { crearApp } = require('../src/app');
const { ServicioVisitas } = require('../src/servicios/servicio_visitas');
const { ServicioReporte } = require('../src/servicios/servicio_reporte');

class RepositorioMemoria {
  constructor() { this.visitas = []; this.mediciones = []; }
  async crearVisita(datos) { const visita = { id: this.visitas.length + 1, ...datos, iniciaEn: new Date().toISOString(), terminaEn: null }; this.visitas.push(visita); return visita; }
  async listarVisitas() { return this.visitas; }
  async buscarVisita(id) { return this.visitas.find((visita) => visita.id === id) || null; }
  async crearMedicion(datos) { const medicion = { id: this.mediciones.length + 1, ...datos, creadoEn: new Date().toISOString() }; this.mediciones.push(medicion); return medicion; }
  async listarMediciones(visitaId) { return this.mediciones.filter((medicion) => medicion.visitaId === visitaId); }
}

async function servidorPrueba() {
  const temporal = fs.mkdtempSync(path.join(os.tmpdir(), 'p6-api-'));
  const configuracion = { almacenDir: temporal, maxFotoBytes: 4 * 1024 * 1024, maxInclinacion: 1.5, maxDesviacionAzimut: 5 };
  const servicioVisitas = new ServicioVisitas({ repositorio: new RepositorioMemoria(), configuracion, almacenDir: temporal });
  const app = crearApp({ servicioVisitas, servicioReporte: new ServicioReporte({ servicioVisitas, almacenDir: temporal }), configuracion });
  const servidor = await new Promise((resolver) => { const resultado = app.listen(0, () => resolver(resultado)); });
  return { base: `http://127.0.0.1:${servidor.address().port}`, cerrar: () => new Promise((resolver) => servidor.close(resolver)) };
}

test('health responde correctamente', async () => {
  const api = await servidorPrueba();
  try { const respuesta = await fetch(`${api.base}/health`); assert.equal(respuesta.status, 200); assert.equal((await respuesta.json()).estado, 'ok'); } finally { await api.cerrar(); }
});

test('crea una visita y rechaza azimut inválido', async () => {
  const api = await servidorPrueba();
  try {
    const creada = await fetch(`${api.base}/api/visitas`, { method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify({ identificador: 'M-01', azimutObjetivo: 180 }) });
    assert.equal(creada.status, 201);
    const invalida = await fetch(`${api.base}/api/visitas`, { method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify({ identificador: 'M-02', azimutObjetivo: 360 }) });
    assert.equal(invalida.status, 400);
  } finally { await api.cerrar(); }
});

test('valida archivo, tamaño y crea medición multipart', async () => {
  const api = await servidorPrueba();
  try {
    await fetch(`${api.base}/api/visitas`, { method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify({ identificador: 'M-03', azimutObjetivo: 1 }) });
    const sinFoto = await fetch(`${api.base}/api/visitas/1/mediciones`, { method: 'POST' });
    assert.equal(sinFoto.status, 400);
    const datos = new FormData();
    for (const [clave, valor] of Object.entries({ inclinacionX: '0.1', inclinacionY: '-0.2', azimut: '359', azimutObjetivo: '1', medidoEn: new Date().toISOString() })) datos.set(clave, valor);
    datos.set('foto', new Blob([new Uint8Array([0xff, 0xd8, 0xff])], { type: 'image/jpeg' }), 'foto.jpg');
    const creada = await fetch(`${api.base}/api/visitas/1/mediciones`, { method: 'POST', body: datos });
    assert.equal(creada.status, 201);
    assert.equal((await creada.json()).medicion.desviacionAzimut, -2);
    const formato = new FormData();
    formato.set('foto', new Blob(['texto'], { type: 'text/plain' }), 'foto.txt');
    const rechazada = await fetch(`${api.base}/api/visitas/1/mediciones`, { method: 'POST', body: formato });
    assert.equal(rechazada.status, 400);
    const enorme = new FormData();
    enorme.set('foto', new Blob([new Uint8Array(4 * 1024 * 1024 + 1)], { type: 'image/jpeg' }), 'enorme.jpg');
    const demasiadoGrande = await fetch(`${api.base}/api/visitas/1/mediciones`, { method: 'POST', body: enorme });
    assert.equal(demasiadoGrande.status, 413);
  } finally { await api.cerrar(); }
});

test('genera un reporte PDF de la visita', async () => {
  const api = await servidorPrueba();
  try {
    await fetch(`${api.base}/api/visitas`, { method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify({ identificador: 'M-04', azimutObjetivo: 180 }) });
    const pdf = await fetch(`${api.base}/api/visitas/1/reporte`);
    assert.equal(pdf.status, 200);
    assert.equal(pdf.headers.get('content-type'), 'application/pdf');
  } finally { await api.cerrar(); }
});
