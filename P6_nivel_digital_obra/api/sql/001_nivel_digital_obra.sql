-- Migración aditiva para P6. No modifica tablas de proyectos anteriores.
CREATE TABLE IF NOT EXISTS p6_visitas (
  id BIGSERIAL PRIMARY KEY,
  identificador TEXT NOT NULL,
  azimut_objetivo NUMERIC(6, 2) NOT NULL CHECK (azimut_objetivo >= 0 AND azimut_objetivo < 360),
  inicia_en TIMESTAMPTZ NOT NULL DEFAULT now(),
  termina_en TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS p6_mediciones (
  id BIGSERIAL PRIMARY KEY,
  visita_id BIGINT NOT NULL REFERENCES p6_visitas(id) ON DELETE RESTRICT,
  inclinacion_x NUMERIC(7, 3) NOT NULL,
  inclinacion_y NUMERIC(7, 3) NOT NULL,
  azimut NUMERIC(6, 3) NOT NULL CHECK (azimut >= 0 AND azimut < 360),
  azimut_objetivo NUMERIC(6, 3) NOT NULL CHECK (azimut_objetivo >= 0 AND azimut_objetivo < 360),
  desviacion_azimut NUMERIC(7, 3) NOT NULL,
  latitud NUMERIC(10, 7),
  longitud NUMERIC(10, 7),
  cumple BOOLEAN NOT NULL,
  foto_ruta TEXT NOT NULL,
  medido_en TIMESTAMPTZ NOT NULL,
  creado_en TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_p6_mediciones_visita_medido_en ON p6_mediciones (visita_id, medido_en);
CREATE INDEX IF NOT EXISTS idx_p6_visitas_inicia_en ON p6_visitas (inicia_en DESC);
