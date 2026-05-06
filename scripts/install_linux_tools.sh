#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BIN_DIR="${PROJECT_ROOT}/.local/bin"
TOOLS_DIR="${PROJECT_ROOT}/.local/tools"

mkdir -p "${BIN_DIR}" "${TOOLS_DIR}"

download_file() {
  local url="$1"
  local output="$2"
  if [[ -s "${output}" ]]; then
    return 0
  fi
  curl -L --fail --connect-timeout 30 --max-time 300 -o "${output}" "${url}"
}

install_nextclade() {
  if [[ -x "${BIN_DIR}/nextclade" ]]; then
    "${BIN_DIR}/nextclade" --version
    return 0
  fi

  download_file \
    "https://github.com/nextstrain/nextclade/releases/download/3.9.0/nextclade-x86_64-unknown-linux-gnu" \
    "${BIN_DIR}/nextclade"
  chmod +x "${BIN_DIR}/nextclade"
  "${BIN_DIR}/nextclade" --version
}

install_iqtree() {
  if [[ -x "${BIN_DIR}/iqtree" ]]; then
    "${BIN_DIR}/iqtree" --version | head -1
    return 0
  fi

  local archive="${TOOLS_DIR}/iqtree-2.2.0-Linux.tar.gz"
  download_file \
    "https://github.com/iqtree/iqtree2/releases/download/v2.2.0/iqtree-2.2.0-Linux.tar.gz" \
    "${archive}"
  tar -xzf "${archive}" -C "${TOOLS_DIR}"
  ln -sf "${TOOLS_DIR}/iqtree-2.2.0-Linux/bin/iqtree2" "${BIN_DIR}/iqtree"
  "${BIN_DIR}/iqtree" --version | head -1
}

install_seqkit() {
  if [[ -x "${BIN_DIR}/seqkit" ]]; then
    "${BIN_DIR}/seqkit" version
    return 0
  fi

  local archive="${TOOLS_DIR}/seqkit_linux_amd64.tar.gz"
  download_file \
    "https://github.com/shenwei356/seqkit/releases/download/v2.12.0/seqkit_linux_amd64.tar.gz" \
    "${archive}"
  tar -xzf "${archive}" -C "${TOOLS_DIR}"
  mv "${TOOLS_DIR}/seqkit" "${BIN_DIR}/seqkit"
  chmod +x "${BIN_DIR}/seqkit"
  "${BIN_DIR}/seqkit" version
}

install_python_helpers() {
  python3 -m pip install --user epiweeks==2.1.2
}

install_nextclade
install_iqtree
install_seqkit
install_python_helpers

cat <<EOF

Installed helper tools in:
  ${BIN_DIR}

Add this directory to PATH before building:
  export PATH="${BIN_DIR}:\$PATH"
EOF
