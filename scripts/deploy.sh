#!/bin/bash
# Augšupielādē norādītos failus uz Namecheap FTPS (tablo.saliedeties.lv).
# Lietošana: scripts/deploy.sh index.html calendar.ics
set -euo pipefail
cd "$(dirname "$0")/.."
set -a
source .env.deploy
set +a

for f in "$@"; do
  echo "Augšupielādē: $f"
  curl -sk --ftp-ssl --ftp-pasv --disable-epsv -m 30 --user "${FTP_USER}:${FTP_PASS}" \
    -T "$f" "ftp://${FTP_HOST}:${FTP_PORT}/$(basename "$f")"
done
echo "Gatavs."
