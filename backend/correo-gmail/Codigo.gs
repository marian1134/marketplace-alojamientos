// StayHub: envía los correos de la página desde esta cuenta de Gmail.
// Se pega en script.google.com y se publica como "Aplicación web".
// La clave se guarda en Configuración del proyecto > Propiedades del script
// con el nombre CLAVE (la misma que GOOGLE_SCRIPT_CLAVE en Render).

function doPost(e) {
  var datos;
  try {
    datos = JSON.parse(e.postData.contents);
  } catch (error) {
    return responder({ ok: false, error: 'solicitud inválida' });
  }

  var clave = PropertiesService.getScriptProperties().getProperty('CLAVE');
  if (!clave || datos.clave !== clave) {
    return responder({ ok: false, error: 'clave incorrecta' });
  }

  try {
    var opciones = { name: datos.nombre || 'StayHub' };
    if (datos.html) {
      opciones.htmlBody = datos.html;
    }
    GmailApp.sendEmail(datos.para, datos.asunto, datos.texto, opciones);
    return responder({ ok: true });
  } catch (error) {
    return responder({ ok: false, error: String(error) });
  }
}

// Para probar desde el editor: cambia el correo y presiona "Ejecutar"
function probarEnvio() {
  GmailApp.sendEmail('tu-correo@gmail.com', 'Prueba de StayHub', 'Si te llegó este correo, el script funciona.');
}

function responder(objeto) {
  return ContentService
    .createTextOutput(JSON.stringify(objeto))
    .setMimeType(ContentService.MimeType.JSON);
}
