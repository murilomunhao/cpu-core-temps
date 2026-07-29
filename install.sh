#!/usr/bin/env bash
set -euo pipefail

ID="com.github.murilomunhao.cpu-core-temps"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLASMOID_DIR="${HOME}/.local/share/plasma/plasmoids/${ID}"
ICON_DIR="${HOME}/.local/share/icons/hicolor/scalable/apps"

echo "Instalando plasmoid em: ${PLASMOID_DIR}"
mkdir -p "$(dirname "${PLASMOID_DIR}")"
rm -rf "${PLASMOID_DIR}"
cp -r "${SCRIPT_DIR}/package" "${PLASMOID_DIR}"

echo "Instalando ícone em: ${ICON_DIR}"
mkdir -p "${ICON_DIR}"
cp "${SCRIPT_DIR}/package/contents/icons/${ID}.svg" "${ICON_DIR}/${ID}.svg"

if command -v gtk-update-icon-cache >/dev/null 2>&1; then
  [ -f "${HOME}/.local/share/icons/hicolor/index.theme" ] || touch "${HOME}/.local/share/icons/hicolor/index.theme"
  gtk-update-icon-cache -f -t "${HOME}/.local/share/icons/hicolor" >/dev/null 2>&1 || true
fi
if command -v xdg-icon-resource >/dev/null 2>&1; then
  xdg-icon-resource forceupdate >/dev/null 2>&1 || true
fi

echo "Reiniciando Plasma Shell..."
if systemctl --user restart plasma-plasmashell.service >/dev/null 2>&1; then
  echo "OK (systemctl)."
elif command -v kquitapp6 >/dev/null 2>&1 && kquitapp6 plasmashell >/dev/null 2>&1; then
  nohup kstart6 plasmashell >/dev/null 2>&1 &
  echo "OK (Plasma 6 relançado)."
elif command -v kquitapp5 >/dev/null 2>&1 && kquitapp5 plasmashell >/dev/null 2>&1; then
  nohup kstart5 plasmashell >/dev/null 2>&1 &
  echo "OK (Plasma 5 relançado)."
else
  killall plasmashell >/dev/null 2>&1 || true
  sleep 1
  nohup plasmashell >/dev/null 2>&1 &
  echo "OK (plasmashell forçado e relançado)."
fi

echo
echo "Pronto. Adicione o widget: Editar painel → Adicionar widgets → CPU Core Temps"
echo "Ícone: ${ICON_DIR}/${ID}.svg"
