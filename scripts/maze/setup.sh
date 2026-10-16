#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
TOOLS_ROOT="$PWD/build/maze/tools"
DATA_ROOT="$PWD/build/maze/data"
mkdir -p "$TOOLS_ROOT/bin" "$DATA_ROOT/godot/export_templates/4.6.3.stable"
BASE=https://github.com/godotengine/godot-builds/releases/download/4.6.3-stable
if [[ ! -f "$TOOLS_ROOT/engine.zip" ]]; then
  curl -fsSL --retry 3 "$BASE/Godot_v4.6.3-stable_linux.x86_64.zip" -o "$TOOLS_ROOT/engine.zip"
fi
if [[ ! -f "$TOOLS_ROOT/templates.tpz" ]]; then
  curl -fsSL --retry 3 "$BASE/Godot_v4.6.3-stable_export_templates.tpz" -o "$TOOLS_ROOT/templates.tpz"
fi
(cd "$TOOLS_ROOT" && sha512sum -c <<'CHECKSUMS'
a035258da32b77f966a5376f9fa29c30a6adde826a85ba918e1605bd1fc9823eba7d85f1dd5e748956bd2ba72827c0025ffa11bb82aec91128c407a2e723c99c  engine.zip
da606b61c10157844f8300172df374472665f95015495cb1a7cd132c40ede404faa96cc1016a4b9662db9909ddea69632c4948b2cd11163438dad4808881fb68  templates.tpz
CHECKSUMS
)
unzip -qo "$TOOLS_ROOT/engine.zip" -d "$TOOLS_ROOT/bin"
mv "$TOOLS_ROOT/bin/Godot_v4.6.3-stable_linux.x86_64" "$TOOLS_ROOT/bin/godot"
chmod +x "$TOOLS_ROOT/bin/godot"
unzip -jo "$TOOLS_ROOT/templates.tpz" templates/android_release.apk templates/android_debug.apk templates/linux_release.x86_64 templates/version.txt -d "$DATA_ROOT/godot/export_templates/4.6.3.stable"
if [[ -n "${GITHUB_ENV:-}" ]]; then
  printf 'GODOT=%s\nXDG_DATA_HOME=%s\n' "$TOOLS_ROOT/bin/godot" "$DATA_ROOT" >> "$GITHUB_ENV"
fi
printf 'GODOT=%s\nXDG_DATA_HOME=%s\n' "$TOOLS_ROOT/bin/godot" "$DATA_ROOT"
