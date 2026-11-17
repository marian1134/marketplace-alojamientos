import { useState } from 'react'
import { t, useIdioma } from '../idiomas'
import './descargar-app.css'

// Invita a descargar StayHub en el celular: APK para Android y pasos para iPhone.
// No se muestra cuando la página ya está abierta como app instalada.
function yaEsApp() {
  if (typeof window === 'undefined') return false
  return window.matchMedia?.('(display-mode: standalone)').matches
    || window.navigator.standalone === true
    || document.referrer.startsWith('android-app://')
}

function esIphone() {
  return typeof navigator !== 'undefined' && /iPhone|iPad|iPod/i.test(navigator.userAgent)
}

export default function DescargarApp() {
  useIdioma()
  const [verPasosIphone, setVerPasosIphone] = useState(false)
  if (yaEsApp()) return null
  const iphone = esIphone()

  return (
    <div className="descargar-app" id="descargar-app">
      <div>
        <strong>{t('Lleva StayHub en tu celular')}</strong>
        <p>{t('Descarga la app y reserva tus viajes desde cualquier lugar.')}</p>
      </div>
      <div className="descargar-app-botones">
        {!iphone && (
          <a className="portada-boton-principal" href="/descargas/StayHub.apk" download="StayHub.apk">
            {t('Descargar para Android')}
          </a>
        )}
        <button type="button" className="descargar-app-iphone" aria-expanded={verPasosIphone} onClick={() => setVerPasosIphone((v) => !v)}>
          {t('Instalar en iPhone')}
        </button>
      </div>
      {verPasosIphone && (
        <ol className="descargar-app-pasos">
          <li>{t('Abre esta página en Safari.')}</li>
          <li>{t('Toca el botón Compartir (el cuadro con la flecha hacia arriba).')}</li>
          <li>{t('Elige «Agregar a pantalla de inicio» y luego Agregar.')}</li>
        </ol>
      )}
      {!iphone && <p className="descargar-app-nota">{t('Al abrir el archivo, Android puede pedir permiso para instalar apps de este origen.')}</p>}
    </div>
  )
}
