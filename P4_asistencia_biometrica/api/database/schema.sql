CREATE TABLE IF NOT EXISTS ficha (
  id SERIAL PRIMARY KEY,
  codigo VARCHAR(100) UNIQUE NOT NULL,
  nombre VARCHAR(150) NOT NULL,
  hora_inicio TIME NOT NULL DEFAULT '07:00:00',
  hora_fin TIME NOT NULL DEFAULT '13:00:00',
  centro_lat DOUBLE PRECISION DEFAULT 4.6581,
  centro_lon DOUBLE PRECISION DEFAULT -74.0935,
  radio_m INT DEFAULT 500
);

CREATE TABLE IF NOT EXISTS usuario (
  id SERIAL PRIMARY KEY,
  documento VARCHAR(50) UNIQUE NOT NULL,
  nombre VARCHAR(150) NOT NULL,
  email VARCHAR(150) UNIQUE NOT NULL,
  password VARCHAR(255) NOT NULL,
  rol VARCHAR(50) NOT NULL DEFAULT 'aprendiz',
  ficha_id INT REFERENCES ficha(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS refresh_token (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  usuario_id INT NOT NULL REFERENCES usuario(id) ON DELETE CASCADE,
  token VARCHAR(500) UNIQUE NOT NULL,
  expira_en TIMESTAMP WITH TIME ZONE NOT NULL,
  revocado BOOLEAN DEFAULT FALSE,
  creado_en TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS marcacion_asistencia (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  usuario_id INT NOT NULL REFERENCES usuario(id) ON DELETE CASCADE,
  ficha_id INT REFERENCES ficha(id) ON DELETE SET NULL,
  tipo VARCHAR(20) NOT NULL,
  latitud DOUBLE PRECISION NOT NULL,
  longitud DOUBLE PRECISION NOT NULL,
  precision_m REAL NOT NULL,
  distancia_m REAL NOT NULL,
  dentro_perimetro BOOLEAN NOT NULL,
  dentro_horario BOOLEAN NOT NULL,
  registrada_en TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_marcacion_usuario ON marcacion_asistencia(usuario_id);
CREATE INDEX IF NOT EXISTS idx_refresh_token_user ON refresh_token(usuario_id);
