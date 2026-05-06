#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: bash scripts/run_build.sh /path/to/metadata.tsv /path/to/sequences.fasta" >&2
  exit 2
fi

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NCOV_DIR="${NCOV_DIR:-${PROJECT_ROOT}/work/ncov}"
METADATA="$(realpath "$1")"
SEQUENCES="$(realpath "$2")"

if [[ ! -f "${METADATA}" ]]; then
  echo "Metadata file not found: ${METADATA}" >&2
  exit 1
fi

if [[ ! -f "${SEQUENCES}" ]]; then
  echo "Sequence FASTA file not found: ${SEQUENCES}" >&2
  exit 1
fi

if [[ ! -d "${NCOV_DIR}/.git" ]]; then
  bash "${PROJECT_ROOT}/scripts/setup_ncov.sh"
fi

mkdir -p "${NCOV_DIR}/my_profiles/pakistan"
cp "${PROJECT_ROOT}/profiles/pakistan/config.yaml" "${NCOV_DIR}/my_profiles/pakistan/config.yaml"
cp "${PROJECT_ROOT}/profiles/pakistan/auspice_config.json" "${NCOV_DIR}/my_profiles/pakistan/auspice_config.json"
cp "${PROJECT_ROOT}/profiles/pakistan/description.md" "${NCOV_DIR}/my_profiles/pakistan/description.md"

cat > "${NCOV_DIR}/my_profiles/pakistan/builds.yaml" <<EOF
auspice_json_prefix: ncov

inputs:
  - name: reference_data
    metadata: data/remote-open/reference/metadata.tsv.xz
    aligned: data/remote-open/reference/aligned.fasta.xz
    skip_sanitize_metadata: true
  - name: custom_data
    metadata: "${METADATA}"
    sequences: "${SEQUENCES}"

builds:
  Pakistan:
    title: "Genomic epidemiology of SARS-CoV-2 in Pakistan"
    subsampling_scheme: all
    auspice_config: my_profiles/pakistan/auspice_config.json

traits:
  Pakistan:
    sampling_bias_correction: 2.5
    columns: ["country", "division"]

refine:
  root: "Wuhan-Hu-1/2019"

files:
  description: my_profiles/pakistan/description.md
EOF

export PATH="${PROJECT_ROOT}/.local/bin:${PATH}"

(
  cd "${NCOV_DIR}"
  snakemake --profile my_profiles/pakistan
)

echo
echo "Build complete. Output files:"
stat -c '  %n %s bytes' "${NCOV_DIR}"/auspice/ncov_Pakistan*.json
