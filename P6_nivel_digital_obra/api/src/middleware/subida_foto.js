const fs = require('node:fs');
const path = require('node:path');
const multer = require('multer');

function crearSubidaFoto({ almacenDir, maxFotoBytes }) {
  const fotosDir = path.join(almacenDir, 'fotos');
  fs.mkdirSync(fotosDir, { recursive: true });
  return multer({
    storage: multer.diskStorage({
      destination: (_, __, done) => done(null, fotosDir),
      filename: (_, archivo, done) => done(null, `${Date.now()}-${Math.round(Math.random() * 1e9)}${path.extname(archivo.originalname).toLowerCase()}`),
    }),
    limits: { fileSize: maxFotoBytes },
    fileFilter: (_, archivo, done) => {
      done(null, archivo.mimetype === 'image/jpeg' || archivo.mimetype === 'image/png');
    },
  }).single('foto');
}

module.exports = { crearSubidaFoto };
