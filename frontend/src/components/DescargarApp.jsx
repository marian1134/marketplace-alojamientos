import { t, useIdioma } from '../idiomas'
import './descargar-app.css'

// Invita a descargar StayHub como app de Android (APK).
// No se muestra en iPhone ni cuando la página ya está abierta como app instalada.
function debeMostrarse() {
  if (typeof window === 'undefined') return false
  const yaEsApp = window.matchMedia?.('(display-mode: standalone)').matches
    || window.navigator.standalone === true
    || document.referrer.startsWith('android-app://')
  const iphone = /iPhone|iPad|iPod/i.test(navigator.userAgent)
  return !yaEsApp && !iphone
}

export default function DescargarApp() {
  useIdioma()
  if (!debeMostrarse()) return null

  return (
    <div className="descargar-app" id="descargar-app">
      <div>
        <strong>{t('Lleva StayHub en tu celular')}</strong>
        <p>{t('Descarga la app para Android y reserva tus viajes desde cualquier lugar.')}</p>
      </div>
      <a className="portada-boton-principal" href="/descargas/StayHub.apk" download="StayHub.apk">
        {t('Descargar para Android')}
      </a>
      <p className="descargar-app-nota">{t('Al abrir el archivo, Android puede pedir permiso para instalar apps de este origen.')}</p>
    </div>
  )
}
