#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "Usage: bash scripts/publish_to_community_repo.sh /path/to/NIH-BIGVI-PAKISTAN-ncov [--push]" >&2
  exit 2
fi

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NCOV_DIR="${NCOV_DIR:-${PROJECT_ROOT}/work/ncov}"
COMMUNITY_REPO="$(realpath "$1")"
PUSH="${2:-}"

if [[ "${PUSH}" != "" && "${PUSH}" != "--push" ]]; then
  echo "Unknown option: ${PUSH}" >&2
  exit 2
fi

if [[ ! -d "${COMMUNITY_REPO}/.git" ]]; then
  echo "Community repository is not a git checkout: ${COMMUNITY_REPO}" >&2
  exit 1
fi

AUSPICE_FILES=(
  ncov_Pakistan.json
  ncov_Pakistan_root-sequence.json
  ncov_Pakistan_tip-frequencies.json
)
AUSPICE_EXPORTS=()

for filename in "${AUSPICE_FILES[@]}"; do
  AUSPICE_EXPORTS+=("${NCOV_DIR}/auspice/${filename}")
done

python3 "${PROJECT_ROOT}/scripts/validate_auspice_exports.py" "${AUSPICE_EXPORTS[@]}"

mkdir -p "${COMMUNITY_REPO}/auspice"

for filename in "${AUSPICE_FILES[@]}"; do
  cp "${NCOV_DIR}/auspice/${filename}" "${COMMUNITY_REPO}/auspice/${filename}"
done

git -C "${COMMUNITY_REPO}" status --short

if git -C "${COMMUNITY_REPO}" diff --quiet -- auspice; then
  echo "No Auspice changes to publish."
  exit 0
fi

git -C "${COMMUNITY_REPO}" add auspice/ncov_Pakistan.json \
  auspice/ncov_Pakistan_root-sequence.json \
  auspice/ncov_Pakistan_tip-frequencies.json

git -C "${COMMUNITY_REPO}" commit -m "Update Pakistan SARS-CoV-2 Nextstrain build"

if [[ "${PUSH}" == "--push" ]]; then
  git -C "${COMMUNITY_REPO}" push origin main
else
  echo
  echo "Committed locally. Review, then push with:"
  echo "  git -C ${COMMUNITY_REPO} push origin main"
fi
