const errorHandler = (err, req, res, next) => {
  console.error('Error no manejado:', err);

  const statusCode = err.statusCode || 500;

  res.status(statusCode).json({
    ok: false,
    message: err.message || 'Error interno del servidor',
  });
};

module.exports = {
  errorHandler,
};
