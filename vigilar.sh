#!/usr/bin/env bash
# Revisa cada sitio y avisa por Telegram solo cuando algo cae o vuelve.
# La lista de sitios llega en el secreto SITIOS (una línea por sitio: Nombre|URL).
# No imprime nombres ni direcciones: los registros de este repo son públicos.
set -u
mkdir -p estado
touch estado/previo.txt

avisar() {
  curl -s -o /dev/null --max-time 20 -X POST "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage" \
    --data-urlencode "chat_id=${TELEGRAM_CHAT_ID}" --data-urlencode "text=$1"
}

if [ "${PRUEBA:-false}" = "true" ]; then
  avisar "Prueba del monitor de RR INTEC: las alertas llegan a este chat."
  exit 0
fi

: > estado/actual.txt
while IFS='|' read -r nombre url; do
  nombre=$(echo "$nombre" | tr -d '\r' | xargs); url=$(echo "${url:-}" | tr -d '\r' | xargs)
  [ -z "$nombre" ] || [ -z "$url" ] && continue
  codigo=000
  for intento in 1 2; do
    extra=(); case "$url" in *supabase*) extra=(-H "apikey: ${SUPABASE_ANON_KEY}");; esac
    codigo=$(curl -s -o /dev/null -L --max-time 20 -w '%{http_code}' "${extra[@]}" "$url" || true)
    if [ "$codigo" -ge 200 ] 2>/dev/null && [ "$codigo" -lt 500 ]; then codigo=ok; break; fi
    sleep 15
  done
  [ "$codigo" != ok ] && echo "${nombre}|${codigo}" >> estado/actual.txt
done <<< "$SITIOS"

sort -o estado/actual.txt estado/actual.txt
cayeron=$(join -t'|' -v1 estado/actual.txt <(sort estado/previo.txt) | cut -d'|' -f1,2 | sed 's/|/ (código /; s/$/)/')
volvieron=$(join -t'|' -v1 <(sort estado/previo.txt) estado/actual.txt | cut -d'|' -f1)
[ -n "$cayeron" ] && avisar "CAÍDO — RR INTEC
$cayeron"
[ -n "$volvieron" ] && avisar "RECUPERADO — RR INTEC
$volvieron"
mv estado/actual.txt estado/previo.txt
echo "revisión terminada: $(wc -l < estado/previo.txt | xargs) sitio(s) con problemas"
