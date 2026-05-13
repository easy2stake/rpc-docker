#!/usr/bin/env bash
#
# Generate the Engine API JWT shared by reth (authrpc) and op-node (--l2.jwt-secret).
# Default path matches ronin/env.template (RONIN_RETH_DATADIR).
#
# Usage: ./create-jwt.sh
# Optional: RONIN_RETH_DATADIR=/path/to/datadir ./create-jwt.sh

set -euo pipefail

RONIN_RETH_DATADIR="${RONIN_RETH_DATADIR:-${HOME}/ronin-reth-datadir}"
JWT_PATH="${RONIN_RETH_DATADIR}/jwt.hex"

if ! command -v openssl >/dev/null 2>&1; then
  echo "ERROR: openssl is required but not found in PATH." >&2
  exit 1
fi

mkdir -p "${RONIN_RETH_DATADIR}"

openssl rand -hex 32 > "${JWT_PATH}"
chmod 600 "${JWT_PATH}"

echo "Wrote Engine API JWT (hex, no 0x prefix) to:"
echo "  ${JWT_PATH}"
