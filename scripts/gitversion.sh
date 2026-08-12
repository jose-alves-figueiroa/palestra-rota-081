#!/usr/bin/env bash
set -euo pipefail

hash=$(git rev-parse HEAD 2>/dev/null) || { echo -n "unknown"; exit 0; }
short="${hash: -4}"

if [ -f .build-datetime ]; then
  datetime=$(cat .build-datetime)
else
  datetime=$(date '+%Y-%m-%d %H:%M')
  echo -n "$datetime" > .build-datetime
fi

echo -n "${datetime} - ${short}"
