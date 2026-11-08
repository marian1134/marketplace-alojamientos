import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import App from './App.jsx'
import SoporteFlotante from './components/SoporteFlotante.jsx'
import './index.css'
import './components/soporte-flotante.css'
import './responsive.css'

createRoot(document.getElementById('root')).render(
  <StrictMode>
    <App />
    <SoporteFlotante />
  </StrictMode>
)
// Registra el service worker para poder instalar StayHub en el celular
if ('serviceWorker' in navigator) {
  window.addEventListener('load', () => {
    navigator.serviceWorker.register('/sw.js').catch(() => {})
  })
}
