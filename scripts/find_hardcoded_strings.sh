#!/usr/bin/env bash
# Title: find_hardcoded_strings.sh
# Purpose: Scan Swift + IB XML for hardcoded UI strings not using Localized/NSLocalizedString
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
OUT_DIR="$ROOT/out"
OUT_FILE="$OUT_DIR/hardcoded_strings.txt"
ALLOWLIST_FILE="$ROOT/.i18n-allowlist.txt"

mkdir -p "$OUT_DIR"
: > "$OUT_FILE"

has_allowlist=false
[[ -f "$ALLOWLIST_FILE" ]] && has_allowlist=true
filter_allowlist() {
  if $has_allowlist; then
    grep -F -v -f "$ALLOWLIST_FILE" || true
  else
    cat
  fi
}

# Swift
rg -n --no-heading \
  -g '!**/Pods/**' -g '!**/*.xcassets/**' -g '!**/*.lproj/**' -g '!**/*Tests/**' -g '!**/.build/**' \
  -t swift '"([^"\\]|\\.)+"' \
| rg -v 'Localized\.' \
| rg -v 'NSLocalizedString' \
| rg -v 'assert|precondition|fatalError' \
| rg -v 'http(s)?://|^[^:]+:\d+:"[A-Za-z0-9._-]+$' \
| rg -v '^(.*):\d+:"[{}()\[\];:,<>#@!?=+*/^~`|\\-]*"$' \
| awk -F: '{file=$1; line=$2; rest=$0; sub(/^[^"]*"/,"",rest); sub(/".*$/,"",rest); print "SWIFT|" file "|" line "|" rest}' \
| filter_allowlist >> "$OUT_FILE"

# Storyboards/XIBs
find "$ROOT" -type f \( -name "*.storyboard" -o -name "*.xib" \) \
  ! -path "*/Pods/*" ! -path "*/.build/*" \
| while read -r f; do
    rg -n --no-heading ' (text|title|placeholder|prompt|label|headerTitle|footerTitle|accessibilityLabel|tooltip)="[^"]+"' "$f" \
    | awk -F: -v file="$f" '{
        line=$2;
        match($0, / (text|title|placeholder|prompt|label|headerTitle|footerTitle|accessibilityLabel|tooltip)="([^"]+)"/, m);
        if (m[2] != "") { printf("IBXML|%s|%s|%s\n", file, line, m[2]); }
      }'
  done \
| rg -v '^\s*$' \
| filter_allowlist >> "$OUT_FILE"

sort -u "$OUT_FILE" -o "$OUT_FILE"

COUNT=$(wc -l < "$OUT_FILE" | tr -d ' ')
{
  echo "### i18n scan result"
  echo ""
  if [[ "$COUNT" -eq 0 ]]; then
    echo "No hardcoded UI strings found. ✅"
  else
    echo "**$COUNT** potential hardcoded strings found. ❌"
    echo ""
    echo "| File | Line | Source | Text |"
    echo "|---|---:|---|---|"
    awk -F'|' '{printf("| %s | %s | %s | %s |\n", $2, $3, $1, $4)}' "$OUT_FILE"
  fi
} >> "$GITHUB_STEP_SUMMARY"

if [[ "$COUNT" -gt 0 ]]; then
  while IFS='|' read -r SRC FILE LINE TEXT; do
    echo "::error file=${FILE},line=${LINE}::Hardcoded string (${SRC}): ${TEXT}"
  done < "$OUT_FILE"
  exit 1
fi

