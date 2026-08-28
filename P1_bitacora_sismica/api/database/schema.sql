CREATE TABLE IF NOT EXISTS dispositivo (
  id SERIAL PRIMARY KEY,
  dispositivo_id VARCHAR(100) NOT NULL UNIQUE,
  nombre VARCHAR(150) NOT NULL,
  modelo VARCHAR(150),
  version_firmware VARCHAR(50),
  fecha_registro TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS evento_impacto (
  id SERIAL PRIMARY KEY,
  dispositivo_id VARCHAR(100) NOT NULL,
  clave_cliente VARCHAR(100) NOT NULL,
  intensidad DOUBLE PRECISION NOT NULL,
  latitud DOUBLE PRECISION,
  longitud DOUBLE PRECISION,
  precision_m DOUBLE PRECISION,
  descripcion TEXT,
  fecha_evento TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  CONSTRAINT uq_dispositivo_clave UNIQUE (dispositivo_id, clave_cliente),
  CONSTRAINT fk_evento_dispositivo FOREIGN KEY (dispositivo_id)
    REFERENCES dispositivo(dispositivo_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_evento_fecha ON evento_impacto (fecha_evento DESC);
CREATE INDEX IF NOT EXISTS idx_evento_dispositivo ON evento_impacto (dispositivo_id);
