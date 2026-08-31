# Arquitectura

Flutter sigue `presentación → providers Riverpod → dominio → repositorio → fuente Dio`. La pantalla de medición consume streams de hardware reales, los providers se autoeliminan y cancelan sensores, GPS y `CameraController`. El dominio contiene la inclinación, el filtro complementario, el rumbo circular y la regla de cumplimiento, sin dependencias de widgets ni HTTP.

La API sigue `ruta → controlador → servicio → repositorio → PostgreSQL`. Las rutas no contienen SQL y el servicio vuelve a calcular desviación y cumplimiento. `multer` guarda la foto anotada en disco; PostgreSQL conserva únicamente su identificador seguro. `PDFKit` arma el reporte desde la visita y sus mediciones.
