#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NCOV_DIR="${NCOV_DIR:-${PROJECT_ROOT}/work/ncov}"
NCOV_RELEASE="${NCOV_RELEASE:-v16}"

mkdir -p "$(dirname "${NCOV_DIR}")"

if [[ ! -d "${NCOV_DIR}/.git" ]]; then
  git clone https://github.com/nextstrain/ncov.git "${NCOV_DIR}"
fi

git -C "${NCOV_DIR}" fetch --tags --prune
git -C "${NCOV_DIR}" checkout "${NCOV_RELEASE}"

mkdir -p "${NCOV_DIR}/my_profiles/pakistan"
cp "${PROJECT_ROOT}/profiles/pakistan/config.yaml" "${NCOV_DIR}/my_profiles/pakistan/config.yaml"
cp "${PROJECT_ROOT}/profiles/pakistan/auspice_config.json" "${NCOV_DIR}/my_profiles/pakistan/auspice_config.json"
cp "${PROJECT_ROOT}/profiles/pakistan/description.md" "${NCOV_DIR}/my_profiles/pakistan/description.md"

mkdir -p "${NCOV_DIR}/data/remote-open/reference"
curl -L --fail --max-time 120 \
  -o "${NCOV_DIR}/data/remote-open/reference/metadata.tsv.xz" \
  "https://data.nextstrain.org/files/ncov/open/reference/metadata.tsv.xz"
curl -L --fail --max-time 120 \
  -o "${NCOV_DIR}/data/remote-open/reference/aligned.fasta.xz" \
  "https://data.nextstrain.org/files/ncov/open/reference/aligned.fasta.xz"

cat <<EOF
Prepared Nextstrain ncov workflow:
  ${NCOV_DIR}

Release:
  ${NCOV_RELEASE}

Next step:
  bash scripts/run_build.sh /path/to/metadata.tsv /path/to/sequences.fasta
EOF
