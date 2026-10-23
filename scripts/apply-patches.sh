#!/usr/bin/env bash
# Apply overlay patches to an intellij-community checkout.
# Usage: scripts/apply-patches.sh <intellij-community-dir>
set -euo pipefail

COMMUNITY_DIR="$(cd "${1:-.}" && pwd)"
OVERLAY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$COMMUNITY_DIR"
for p in "$OVERLAY_DIR"/patches/*.patch; do
  echo "== apply $(basename "$p") =="
  git apply --3way "$p"
done
echo "all patches applied"
