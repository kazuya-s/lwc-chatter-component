#!/bin/bash
set -euo pipefail

# =============================================================================
# open-org.sh
# ScratchOrg をブラウザで開くスクリプト
# =============================================================================

ALIAS="${1:-chatter-expanded-dev}"

echo "ScratchOrg '${ALIAS}' をブラウザで開きます..."
sf org open --target-org "${ALIAS}"
