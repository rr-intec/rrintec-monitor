# Monitor de disponibilidad de RR INTEC

Revisa cada 5 minutos los sistemas de los clientes y avisa por Telegram cuando uno cae y cuando vuelve.

- La lista de sitios, el token de Telegram y las claves viven en los **secretos** del repo, no en el código.
- El script no imprime nombres ni direcciones: los registros de Actions de este repo son públicos.
- Para agregar o quitar un sitio: editar el secreto `SITIOS` (una línea por sitio: `Nombre|https://...`).
- Prueba manual: Actions → "Vigilar sitios" → Run workflow → marcar "prueba".
