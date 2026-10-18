#!/usr/bin/env bash
# Pinned upstream Godot. GODOT_ENGINE_ONLY=1 skips the large export templates.
set -euo pipefail
cd "$(dirname "$0")/../.."
TOOLS_ROOT="$PWD/build/godot-tools"
DATA_ROOT="$TOOLS_ROOT/data"
mkdir -p "$TOOLS_ROOT/downloads" "$TOOLS_ROOT/bin" "$DATA_ROOT/godot/export_templates/4.6.3.stable"
BASE=https://github.com/godotengine/godot-builds/releases/download/4.6.3-stable
ENGINE_SHA=a035258da32b77f966a5376f9fa29c30a6adde826a85ba918e1605bd1fc9823eba7d85f1dd5e748956bd2ba72827c0025ffa11bb82aec91128c407a2e723c99c
TEMPLATE_SHA=da606b61c10157844f8300172df374472665f95015495cb1a7cd132c40ede404faa96cc1016a4b9662db9909ddea69632c4948b2cd11163438dad4808881fb68
download() {
  local name="$1" url="$2" checksum="$3"
  if [[ ! -f "$TOOLS_ROOT/downloads/$name" ]]; then
    curl -fsSL --retry 3 "$url" -o "$TOOLS_ROOT/downloads/$name"
  fi
  printf '%s  %s\n' "$checksum" "$TOOLS_ROOT/downloads/$name" | sha512sum -c -
}
download engine.zip "$BASE/Godot_v4.6.3-stable_linux.x86_64.zip" "$ENGINE_SHA"
unzip -qo "$TOOLS_ROOT/downloads/engine.zip" -d "$TOOLS_ROOT/bin"
mv "$TOOLS_ROOT/bin/Godot_v4.6.3-stable_linux.x86_64" "$TOOLS_ROOT/bin/godot"
chmod +x "$TOOLS_ROOT/bin/godot"
if [[ "${GODOT_ENGINE_ONLY:-0}" != 1 ]]; then
  download templates.tpz "$BASE/Godot_v4.6.3-stable_export_templates.tpz" "$TEMPLATE_SHA"
  unzip -jo "$TOOLS_ROOT/downloads/templates.tpz" templates/android_release.apk templates/android_debug.apk templates/linux_release.x86_64 templates/version.txt -d "$DATA_ROOT/godot/export_templates/4.6.3.stable"
fi
if [[ -n "${GITHUB_ENV:-}" ]]; then
  printf 'GODOT=%s\nXDG_DATA_HOME=%s\n' "$TOOLS_ROOT/bin/godot" "$DATA_ROOT" >> "$GITHUB_ENV"
fi
printf 'GODOT=%s\nXDG_DATA_HOME=%s\n' "$TOOLS_ROOT/bin/godot" "$DATA_ROOT"
