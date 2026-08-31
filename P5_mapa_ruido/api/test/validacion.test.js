const test = require('node:test');
const assert = require('node:assert/strict');

const {
  LOTE_CAPACIDAD,
  validarLote,
} = require('../src/validacion/lote_validator');

function muestraValida() {
  return {
    nivelDb: 65,
    latitud: 4.61,
    longitud: -74.08,
    precisionM: 8,
    medidoEn: new Date().toISOString(),
  };
}

function loteValido() {
  return Array.from({ length: LOTE_CAPACIDAD }, muestraValida);
}

test('acepta exactamente 20 muestras válidas', () => {
  assert.equal(validarLote(loteValido()), null);
});

test('rechaza lotes con cantidad distinta de 20', () => {
  assert.equal(validarLote(loteValido().slice(0, 19)).status, 400);
  assert.equal(validarLote([...loteValido(), muestraValida()]).status, 400);
});

test('rechaza coordenadas y precisión inválidas', () => {
  const lote = loteValido();
  lote[0].latitud = 91;
  assert.equal(validarLote(lote).status, 422);

  const otroLote = loteValido();
  otroLote[0].precisionM = -1;
  assert.equal(validarLote(otroLote).status, 422);
});

test('rechaza campos con tipos inválidos', () => {
  const lote = loteValido();
  lote[0].nivelDb = '65';
  assert.equal(validarLote(lote).status, 400);
});
