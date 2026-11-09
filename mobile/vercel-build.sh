#!/usr/bin/env bash
set -euo pipefail

: "${API_BASE_URL:?Define API_BASE_URL in Vercel project variables}"
case "${API_BASE_URL}" in
  https://*) ;;
  *) echo "API_BASE_URL debe usar HTTPS." >&2; exit 1 ;;
esac

FLUTTER_DIR="${HOME}/.cache/flutter"
if [ ! -x "${FLUTTER_DIR}/bin/flutter" ]; then
  mkdir -p "${HOME}/.cache"
  rm -rf "${FLUTTER_DIR}"
  ARCHIVE="$(curl -fsSL https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json | node -e 'let s="";process.stdin.on("data",c=>s+=c).on("end",()=>{const j=JSON.parse(s);const r=j.releases.find(x=>x.hash===j.current_release.stable);if(!r)process.exit(1);process.stdout.write(r.archive);});')"
  curl -fsSL "https://storage.googleapis.com/flutter_infra_release/releases/${ARCHIVE}" -o /tmp/flutter-sdk.tar.xz
  tar -xf /tmp/flutter-sdk.tar.xz -C "${HOME}/.cache"
  rm -f /tmp/flutter-sdk.tar.xz
fi

export PATH="${FLUTTER_DIR}/bin:${PATH}"
flutter config --enable-web
flutter pub get
flutter build web --release --dart-define="API_BASE_URL=${API_BASE_URL}"
