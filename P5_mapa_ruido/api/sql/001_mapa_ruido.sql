-- Migración aditiva e idempotente para P5.
-- No elimina ni reescribe las mediciones existentes.

BEGIN;

ALTER TABLE public.muestras_ruido
  ADD COLUMN IF NOT EXISTS sesion_id UUID;

-- Las filas históricas reciben una sesión válida para conservarlas.
UPDATE public.muestras_ruido
SET sesion_id = gen_random_uuid()
WHERE sesion_id IS NULL;

ALTER TABLE public.muestras_ruido
  ALTER COLUMN sesion_id SET NOT NULL;

ALTER TABLE public.muestras_ruido
  ADD COLUMN IF NOT EXISTS celda_lat NUMERIC(7,3)
    GENERATED ALWAYS AS (ROUND(latitud::numeric, 3)) STORED;

ALTER TABLE public.muestras_ruido
  ADD COLUMN IF NOT EXISTS celda_lon NUMERIC(7,3)
    GENERATED ALWAYS AS (ROUND(longitud::numeric, 3)) STORED;

CREATE INDEX IF NOT EXISTS idx_muestras_ruido_celda
  ON public.muestras_ruido (celda_lat, celda_lon);

DO $$
BEGIN
  IF to_regclass('public.mapa_ruido') IS NULL THEN
    EXECUTE $view$
      CREATE VIEW public.mapa_ruido AS
      SELECT
        celda_lat,
        celda_lon,
        ROUND(AVG(nivel_db)::numeric, 1) AS promedio_db,
        MAX(nivel_db) AS maximo_db,
        COUNT(*) AS muestras
      FROM public.muestras_ruido
      GROUP BY celda_lat, celda_lon
      HAVING COUNT(*) >= 5
    $view$;
  ELSE
    EXECUTE $view$
      CREATE OR REPLACE VIEW public.mapa_ruido AS
      SELECT
        celda_lat,
        celda_lon,
        ROUND(AVG(nivel_db)::numeric, 1) AS promedio_db,
        MAX(nivel_db) AS maximo_db,
        COUNT(*) AS muestras
      FROM public.muestras_ruido
      GROUP BY celda_lat, celda_lon
      HAVING COUNT(*) >= 5
    $view$;
  END IF;
END
$$;

COMMIT;
