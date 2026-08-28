const getSalud = (req, res) => {
  res.status(200).json({
    ok: true,
    message: 'API funcionando correctamente',
    timestamp: new Date().toISOString(),
  });
};

module.exports = {
  getSalud,
};
