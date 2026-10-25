import { useState } from 'react'
import './App.css'

function App() {
  const [mensaje, setMensaje] = useState('')
  const [cargando, setCargando] = useState(false)

  async function comprobarConexion() {
    setCargando(true)
    setMensaje('')

    try {
      const respuesta = await fetch('/api/estado')

      if (!respuesta.ok) {
        throw new Error('El backend devolvió un error')
      }

      const texto = await respuesta.text()
      setMensaje(texto)
    } catch {
      setMensaje('No se pudo conectar con el backend')
    } finally {
      setCargando(false)
    }
  }

  return (
    <main>
      <h1>Inversiones LR</h1>
      <p>Marketplace de alojamientos</p>

      <button
        type="button"
        onClick={comprobarConexion}
        disabled={cargando}
      >
        {cargando ? 'Conectando...' : 'Probar conexión'}
      </button>

      <p role="status">{mensaje}</p>
    </main>
  )
}

export default App