import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import App from './App.jsx'
import SoporteFlotante from './components/SoporteFlotante.jsx'
import './index.css'
import './components/soporte-flotante.css'

createRoot(document.getElementById('root')).render(
  <StrictMode>
    <App />
    <SoporteFlotante />
  </StrictMode>
)