const { validarVisita, validarMedicion } = require('../validacion/validadores');

function crearControladorVisitas(servicio, servicioReporte) {
  return {
    crear: async (req, res, next) => {
      try { res.status(201).json({ visita: await servicio.crearVisita(validarVisita(req.body)) }); } catch (error) { next(error); }
    },
    listar: async (_, res, next) => {
      try { res.json({ visitas: await servicio.listarVisitas() }); } catch (error) { next(error); }
    },
    obtener: async (req, res, next) => {
      try { res.json({ visita: await servicio.obtenerVisita(Number(req.params.id)) }); } catch (error) { next(error); }
    },
    crearMedicion: async (req, res, next) => {
      try {
        const medicion = await servicio.crearMedicion(Number(req.params.id), validarMedicion(req.body, req.file), req.file);
        res.status(201).json({ medicion });
      } catch (error) { next(error); }
    },
    listarMediciones: async (req, res, next) => {
      try { res.json({ mediciones: await servicio.listarMediciones(Number(req.params.id)) }); } catch (error) { next(error); }
    },
    reporte: async (req, res, next) => {
      try {
        const pdf = await servicioReporte.generar(Number(req.params.id));
        res.type('application/pdf').attachment(`reporte-visita-${req.params.id}.pdf`).send(pdf);
      } catch (error) { next(error); }
    },
  };
}

module.exports = { crearControladorVisitas };
