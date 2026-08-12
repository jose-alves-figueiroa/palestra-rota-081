#!/usr/bin/env bash
set -euo pipefail

hash=$(git rev-parse HEAD 2>/dev/null) || { echo -n "unknown"; exit 0; }
short="${hash: -4}"
datetime=$(git log -1 --format=%cd --date=format:'%Y-%m-%d %H:%M')

echo -n "${datetime} - ${short}"
