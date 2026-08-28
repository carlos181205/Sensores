CREATE TABLE IF NOT EXISTS item (
  id VARCHAR(100) PRIMARY KEY,
  codigo_barras VARCHAR(100) UNIQUE NOT NULL,
  nombre VARCHAR(150) NOT NULL,
  cantidad INT NOT NULL DEFAULT 1,
  estado VARCHAR(50) NOT NULL DEFAULT 'bueno',
  version INT NOT NULL DEFAULT 1,
  foto_base64 TEXT,
  modificado_en TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_item_codigo ON item(codigo_barras);
CREATE INDEX IF NOT EXISTS idx_item_modificado ON item(modificado_en);
