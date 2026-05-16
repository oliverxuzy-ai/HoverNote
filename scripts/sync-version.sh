#!/bin/sh
#
# Single source of truth for the app version = the VERSION file.
# This script writes it into project.yml so xcodegen picks it up:
#   - MARKETING_VERSION       = contents of VERSION  (e.g. 0.1.0)
#   - CURRENT_PROJECT_VERSION = git commit count       (monotonic build no.)
#
# Idempotent. Safe to run locally and in CI. Never bumps VERSION itself —
# that's a human/`release.sh` decision.

set -eu

repo_root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$repo_root"

[ -f VERSION ] || { echo "sync-version: VERSION file missing" >&2; exit 1; }
marketing=$(tr -d ' \t\n\r' < VERSION)
[ -n "$marketing" ] || { echo "sync-version: VERSION is empty" >&2; exit 1; }

# Monotonic build number from history; fall back to 1 outside a git tree.
build=$(git rev-list --count HEAD 2>/dev/null || echo 1)

# BSD (macOS / GitHub macos runner) + GNU sed compatible: -i.bak then drop .bak
sed -i.bak \
  -e "s/^\( *MARKETING_VERSION:\).*/\1 \"${marketing}\"/" \
  -e "s/^\( *CURRENT_PROJECT_VERSION:\).*/\1 \"${build}\"/" \
  project.yml
rm -f project.yml.bak

echo "sync-version: MARKETING_VERSION=${marketing}  CURRENT_PROJECT_VERSION=${build}"
