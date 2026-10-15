#!/usr/bin/env bash
# Installs pinned upstream binaries into the build directory, without third-party actions.
set -euo pipefail
cd "$(dirname "$0")/../.."
ROOT="$PWD/build/godot-tools"
mkdir -p "$ROOT/downloads" "$ROOT/bin" "$ROOT/data/godot/export_templates/4.6.3.stable"
BASE=https://github.com/godotengine/godot-builds/releases/download/4.6.3-stable
cd "$ROOT/downloads"
curl -fsSL --retry 3 "$BASE/Godot_v4.6.3-stable_linux.x86_64.zip" -o engine.zip
curl -fsSL --retry 3 "$BASE/Godot_v4.6.3-stable_export_templates.tpz" -o templates.tpz
echo 'a035258da32b77f966a5376f9fa29c30a6adde826a85ba918e1605bd1fc9823eba7d85f1dd5e748956bd2ba72827c0025ffa11bb82aec91128c407a2e723c99c  engine.zip' | sha512sum -c -
echo 'da606b61c10157844f8300172df374472665f95015495cb1a7cd132c40ede404faa96cc1016a4b9662db9909ddea69632c4948b2cd11163438dad4808881fb68  templates.tpz' | sha512sum -c -
unzip -qo engine.zip -d "$ROOT/bin"
mv "$ROOT/bin/Godot_v4.6.3-stable_linux.x86_64" "$ROOT/bin/godot"
chmod +x "$ROOT/bin/godot"
unzip -p templates.tpz templates/android_release.apk > "$ROOT/data/godot/export_templates/4.6.3.stable/android_release.apk"
unzip -p templates.tpz templates/android_debug.apk > "$ROOT/data/godot/export_templates/4.6.3.stable/android_debug.apk"
unzip -p templates.tpz templates/version.txt > "$ROOT/data/godot/export_templates/4.6.3.stable/version.txt"
rm engine.zip templates.tpz
if [[ -n "${GITHUB_ENV:-}" ]]; then
  echo "GODOT=$ROOT/bin/godot" >> "$GITHUB_ENV"
  echo "XDG_DATA_HOME=$ROOT/data" >> "$GITHUB_ENV"
fi
