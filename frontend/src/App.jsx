import { useState } from 'react'
import RegistroUsuario from './components/RegistroUsuario'
import InicioSesion from './components/InicioSesion'
import NuevaClave from './components/NuevaClave'
import './App.css'

function App() {
  const [pantalla, setPantalla] = useState('login')

  const [token, setToken] = useState(() =>
    new URLSearchParams(window.location.search).get('token')
  )

  const esRecuperacion = token !== null
  const esLogin = pantalla === 'login'

  function volverAlInicio() {
    const direccion = new URL(window.location.href)
    direccion.searchParams.delete('token')

    window.history.replaceState(
      null,
      '',
      direccion.pathname + direccion.search + direccion.hash
    )

    setToken(null)
    setPantalla('login')
  }

  let titulo = 'Crea tu cuenta'

  if (esRecuperacion) {
    titulo = 'Recupera tu cuenta'
  } else if (esLogin) {
    titulo = 'Bienvenido de nuevo'
  }

  return (
    <main className="registro-pagina">
      <aside className="registro-imagen">
        <span className="registro-marca">StayHub</span>

        <div className="registro-bienvenida">
          <h2>{titulo}</h2>

          <p>
            Encuentra tu próximo destino o comparte tu alojamiento.
          </p>
        </div>
      </aside>

      <section>
        {esRecuperacion ? (
          <NuevaClave
            token={token}
            onVolver={volverAlInicio}
          />
        ) : (
          <>
            {esLogin ? <InicioSesion /> : <RegistroUsuario />}

            <p className="cambio-pantalla">
              {esLogin ? '¿No tienes cuenta? ' : '¿Ya tienes cuenta? '}

              <button
                type="button"
                className="boton-enlace"
                onClick={() =>
                  setPantalla(esLogin ? 'registro' : 'login')
                }
              >
                {esLogin ? 'Regístrate' : 'Inicia sesión'}
              </button>
            </p>
          </>
        )}
      </section>
    </main>
  )
}

export default App