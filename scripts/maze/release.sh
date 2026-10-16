#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
: "${GITHUB_SHA:?Run from the verified GitHub Actions release job}"
: "${GITHUB_REPOSITORY:?Set the source repository}"
export GH_REPO="$GITHUB_REPOSITORY"
VERSION=$(python3 - <<'PY'
import re
from pathlib import Path
print(re.search(r'^config/version="([^"]+)"$', Path('maze-godot/project.godot').read_text(), re.M).group(1))
PY
)
TAG="maze-v$VERSION"
BUNDLE="$PWD/build/maze/release"
EVIDENCE="$PWD/build/maze/release-evidence"
NOTES="$PWD/build/maze/release-notes.md"
mkdir -p "$EVIDENCE"
(cd "$BUNDLE" && sha256sum -c SHA256SUMS.txt)
tar -xzf "$BUNDLE/verification.tar.gz" -C "$EVIDENCE"
cat docs/maze/RELEASE_NOTES.md > "$NOTES"
{
  printf '\n\n源码提交：`%s`\n\n验证运行：https://github.com/%s/actions/runs/%s\n\n' "$GITHUB_SHA" "$GITHUB_REPOSITORY" "$GITHUB_RUN_ID"
  printf '```text\n'
  grep -hE '^(MODEL|SCENE|DESKTOP): [0-9]+ checks, 0 failures$' "$EVIDENCE/reports/"{model,scene,desktop}-report.txt
  printf '```\n'
} >> "$NOTES"
if gh release view "$TAG" --json isDraft,targetCommitish,url > build/maze/existing-release.json 2> build/maze/release-lookup.log; then
  if [[ "$(python3 -c 'import json; print(json.load(open("build/maze/existing-release.json"))["isDraft"])')" == False ]]; then
    python3 -c 'import json; print("Existing published release preserved: " + json.load(open("build/maze/existing-release.json"))["url"])'
    exit 0
  fi
  EXISTING_TARGET=$(python3 -c 'import json; print(json.load(open("build/maze/existing-release.json"))["targetCommitish"])')
  [[ "$EXISTING_TARGET" == "$GITHUB_SHA" ]] || { printf 'Draft release belongs to a different source commit.\n' >&2; exit 1; }
  gh release upload "$TAG" "$BUNDLE"/* --clobber
else
  gh release create "$TAG" "$BUNDLE"/* --draft --prerelease --latest=false --target "$GITHUB_SHA" --title "Pipi Maze · 花园捉迷藏 $VERSION · 2.5D 试玩版" --notes-file "$NOTES"
fi
gh release edit "$TAG" --draft=false --prerelease --latest=false --notes-file "$NOTES"
gh release view "$TAG" --json url --jq .url
