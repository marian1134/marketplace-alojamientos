import RegistroUsuario from './components/RegistroUsuario'
import './App.css'

function App() {
  return (
    <main className="registro-pagina">
      <aside className="registro-imagen">
        <span className="registro-marca">StayHub</span>

        <div className="registro-bienvenida">
          <h2>Crea tu cuenta</h2>
          <p>
            Encuentra tu próximo destino o comparte tu alojamiento.
          </p>
        </div>
      </aside>

      <RegistroUsuario />
    </main>
  )
}

export default App