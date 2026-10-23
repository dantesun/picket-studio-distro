#!/usr/bin/env bash
# Dry-run verification: apply patches and resolve the Bazel build target.
# Usage: scripts/verify.sh <intellij-community-dir>
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMUNITY_DIR="$(cd "${1:-.}" && pwd)"
cd "$COMMUNITY_DIR"

# The IDEA distribution build requires the android module tree.
if [ ! -d android ]; then
  echo "android module not found; cloning it (required for bazel query)"
  git clone --depth 1 --branch master https://github.com/JetBrains/android.git android \
    || echo "WARN: android module fetch failed; bazel query may fail"
fi

bash "$SCRIPT_DIR/apply-patches.sh" "$COMMUNITY_DIR"
./bazel.cmd query //build:idea_community >/dev/null
echo "OK: patches applied and build target //build:idea_community resolved"
