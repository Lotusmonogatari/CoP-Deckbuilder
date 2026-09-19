#!/usr/bin/env bash
# Downloads the Godot engine into .tools/ so the checks can run on a machine
# that doesn't have Godot installed (a build server, a fresh clone).
#
# .tools/ is gitignored — the engine is never committed.
#
# Usage:  tools/get_godot.sh
set -euo pipefail

GODOT_VERSION="4.5.1-stable"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOOLS_DIR="$REPO_ROOT/.tools"
GODOT_BIN="$TOOLS_DIR/godot"

if [ -x "$GODOT_BIN" ]; then
  echo "Godot already present: $("$GODOT_BIN" --version)"
  exit 0
fi

# Only Linux x86_64 is handled here, which is what build servers run.
# On a Mac or Windows desktop, install Godot normally and skip this script.
case "$(uname -s)" in
  Linux) ARCHIVE="Godot_v${GODOT_VERSION}_linux.x86_64.zip"
         BINARY="Godot_v${GODOT_VERSION}_linux.x86_64" ;;
  *)     echo "This script only handles Linux. Install Godot $GODOT_VERSION yourself." >&2
         exit 1 ;;
esac

URL="https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}/${ARCHIVE}"

echo "Downloading Godot ${GODOT_VERSION}..."
mkdir -p "$TOOLS_DIR"
curl -sSL -o "$TOOLS_DIR/godot.zip" "$URL"
unzip -o -q "$TOOLS_DIR/godot.zip" -d "$TOOLS_DIR"
mv "$TOOLS_DIR/$BINARY" "$GODOT_BIN"
chmod +x "$GODOT_BIN"
rm "$TOOLS_DIR/godot.zip"

echo "Installed: $("$GODOT_BIN" --version)"
