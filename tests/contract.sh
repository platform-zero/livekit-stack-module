#!/usr/bin/env bash
set -euo pipefail
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
metadata="$repo_root/stack.module.json"
python3 - "$metadata" "$repo_root" <<'PY'
import json
import pathlib
import sys
metadata_path = pathlib.Path(sys.argv[1])
repo_root = pathlib.Path(sys.argv[2])
data = json.loads(metadata_path.read_text(encoding="utf-8"))
for key in ("overlays", "runtimeDependencies", "contracts"):
    if key not in data:
        raise SystemExit(f"missing metadata key: {key}")
for path in data.get("overlays", []):
    target = repo_root / path
    if not target.exists():
        raise SystemExit(f"missing overlay: {path}")
for path in data.get("testAssets", []):
    target = repo_root / path
    if not target.exists():
        raise SystemExit(f"missing test asset: {path}")
PY
while IFS= read -r -d '' script; do
  bash -n "$script"
  if command -v shellcheck >/dev/null 2>&1; then
    shellcheck "$script"
  fi
done < <(find "$repo_root" \
  -path '*/.git' -prune -o \
  -path '*/node_modules' -prune -o \
  -type f -name '*.sh' -print0)
if [ -d "$repo_root/stack.js" ]; then
  while IFS= read -r package_json; do
    package_dir="${package_json%/package.json}"
    test -f "$package_dir/package-lock.json" || {
      printf '[module-contract] JS package lacks package-lock.json: %s\n' "$package_dir" >&2
      exit 1
    }
  done < <(find "$repo_root/stack.js" -path '*/node_modules' -prune -o -name package.json -type f -print)
fi
if [ -d "$repo_root/stack.kotlin" ]; then
  if ! find "$repo_root/stack.kotlin" -name build.gradle.kts -type f -print -quit | grep -q .; then
    python3 - "$metadata" <<'PY_CONTRACT_KOTLIN'
import json
import pathlib
import sys
metadata = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
if not any(path.startswith("stack.kotlin/") for path in metadata.get("overlays", [])):
    raise SystemExit("[module-contract] stack.kotlin exists without build.gradle.kts and is not declared as overlay-only")
PY_CONTRACT_KOTLIN
  fi
fi
if [ -d "$repo_root/stack.containers" ]; then
  if ! find "$repo_root/stack.containers" -name Dockerfile -type f -print -quit | grep -q .; then
    python3 - "$metadata" <<'PY_CONTRACT_CONTAINERS'
import json
import pathlib
import sys
metadata = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
if not any(path.startswith("stack.containers/") for path in metadata.get("overlays", [])):
    raise SystemExit("[module-contract] stack.containers exists without Dockerfile and is not declared as overlay-only")
PY_CONTRACT_CONTAINERS
  fi
fi
printf '[module-contract] ok\n' >&2
