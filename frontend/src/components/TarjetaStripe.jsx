import { useIdioma } from '../idiomas'
import { useEffect } from 'react';
import { CardElement, useElements, useStripe } from '@stripe/react-stripe-js';
// Recuadro seguro de Stripe para escribir la tarjeta. Los datos de la
// tarjeta van directo a Stripe: nunca pasan por nuestro servidor.
function TarjetaStripe({ onListo, onCambio }) {
    useIdioma();
    const stripe = useStripe();
    const elements = useElements();
    // Le pasa a la pantalla de pago lo necesario para cobrar
    useEffect(() => {
        if (stripe && elements) {
            onListo({ stripe, elements, CardElement });
        }
    }, [stripe, elements, onListo]);
    return (<div className="tarjeta-stripe">
      <CardElement options={{
            hidePostalCode: true,
            style: {
                base: {
                    fontSize: '16px',
                    color: '#142b2b',
                    '::placeholder': { color: '#8a9a97' },
                },
                invalid: { color: '#b42318' },
            },
        }} onChange={(evento) => onCambio?.(evento.error?.message ?? '')}/>
    </div>);
}
export default TarjetaStripe;
