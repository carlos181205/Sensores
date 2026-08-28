CREATE TABLE IF NOT EXISTS usuario (
  id SERIAL PRIMARY KEY,
  nombre VARCHAR(150) NOT NULL,
  email VARCHAR(150) UNIQUE NOT NULL,
  rol VARCHAR(50) DEFAULT 'vigilante'
);

CREATE TABLE IF NOT EXISTS punto_control (
  id SERIAL PRIMARY KEY,
  codigo VARCHAR(100) UNIQUE NOT NULL,
  nombre VARCHAR(150) NOT NULL,
  latitud DOUBLE PRECISION NOT NULL,
  longitud DOUBLE PRECISION NOT NULL,
  radio_m INT NOT NULL DEFAULT 40,
  orden INT NOT NULL
);

CREATE TABLE IF NOT EXISTS ronda (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  usuario_id INT NOT NULL,
  inicia_en TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  vence_en TIMESTAMP WITH TIME ZONE NOT NULL,
  estado VARCHAR(50) DEFAULT 'en_curso'
);

CREATE TABLE IF NOT EXISTS marcacion (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ronda_id UUID NOT NULL REFERENCES ronda(id) ON DELETE CASCADE,
  punto_id INT NOT NULL REFERENCES punto_control(id) ON DELETE CASCADE,
  latitud DOUBLE PRECISION NOT NULL,
  longitud DOUBLE PRECISION NOT NULL,
  precision_m REAL NOT NULL,
  distancia_m REAL NOT NULL,
  aceptada BOOLEAN NOT NULL,
  motivo_rechazo TEXT,
  escaneada_en TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  CONSTRAINT uq_ronda_punto UNIQUE (ronda_id, punto_id)
);

CREATE INDEX IF NOT EXISTS idx_marcacion_ronda ON marcacion(ronda_id);
