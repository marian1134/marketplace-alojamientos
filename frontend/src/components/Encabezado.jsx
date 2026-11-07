import { t, useIdioma } from '../idiomas'
import AvatarUsuario from './AvatarUsuario';
import CampanaNotificaciones from './CampanaNotificaciones';
// Barra superior de las pantallas internas
function Encabezado({ usuario, pantalla, onNavegar, onCerrarSesion, }) {
    useIdioma();
    const enlaces = [
        { id: 'portada', texto: t("Explorar") },
        { id: 'viajes', texto: t("Mis viajes") },
        { id: 'favoritos', texto: t("Favoritos") },
    ];
    if (usuario?.rol === 'ADMINISTRADOR') {
        enlaces.push({ id: 'administracion', texto: t("Administraci\u00F3n") });
    }
    if (usuario?.rol === 'ANFITRION') {
        enlaces.push({
            id: 'panel',
            texto: t("Panel anfitri\u00F3n"),
        });
        enlaces.push({
            id: 'calendario',
            texto: t("Calendario"),
        });
    }
    return (<header className="encabezado">
      <button type="button" className="encabezado-logo" onClick={() => onNavegar('portada')}>
        <svg viewBox="0 0 24 24" aria-hidden="true">
          <path d="M3 10.5 12 3l9 7.5M5.5 9.5V21h13V9.5M9 21v-7h6v7" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"/>
        </svg>

        StayHub
      </button>

      <nav aria-label={t("Men\u00FA principal")}>
        {enlaces.map((enlace) => (<button key={enlace.id} type="button" className={pantalla === enlace.id ? 'activo' : ''} aria-current={pantalla === enlace.id
                ? 'page'
                : undefined} onClick={() => onNavegar(enlace.id)}>
            {t(enlace.texto)}
          </button>))}
      </nav>

      <div className="encabezado-usuario">
        <CampanaNotificaciones usuario={usuario}/>
        <button type="button" className="encabezado-perfil" onClick={() => onNavegar('perfil')} title={t("Mi perfil")}>
          <AvatarUsuario usuario={usuario} className="avatar-pequeno"/>

          <span className="encabezado-nombre">
            {usuario?.nombre?.split(/\s+/)[0]}
          </span>
        </button>

        <button type="button" className="encabezado-salir" onClick={onCerrarSesion}>{t("Salir")}</button>
      </div>
    </header>);
}
export default Encabezado;
