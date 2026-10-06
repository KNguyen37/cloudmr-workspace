#!/usr/bin/env bash
# Clone missing repos into repos/, fast-forward existing ones.
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p repos
for r in cloudmr-tools mroptimum-tools mroptimum-app camrie-tools CAMRIE-app; do
  if [ -d "repos/$r/.git" ]; then
    echo "pull  $r"; git -C "repos/$r" pull --ff-only || echo "  (skipped: $r has local changes or diverged)"
  else
    echo "clone $r"; git clone "https://github.com/KNguyen37/$r.git" "repos/$r"
  fi
  grep -qx 'CLAUDE.md' "repos/$r/.git/info/exclude" 2>/dev/null || echo 'CLAUDE.md' >> "repos/$r/.git/info/exclude"
done
