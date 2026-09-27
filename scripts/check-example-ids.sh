#!/usr/bin/env bash
# Fails if any tracked file contains a 12-digit number that is not one of the
# AWS documentation example account IDs this repository is allowed to use.
set -euo pipefail

ALLOWED='^(111122223333|444455556666|777788889999|123456789012|555555555555)$'
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

bad=0
while IFS= read -r file; do
  [[ -f "$file" ]] || continue
  # Every run of digits, then keep runs of exactly 12. Splitting on digit runs
  # (rather than matching delimiters) catches adjacent IDs such as a,b lists.
  while IFS=: read -r line digits; do
    [[ "${#digits}" -eq 12 ]] || continue
    if [[ ! "$digits" =~ $ALLOWED ]]; then
      echo "$file:$line: $digits is not an allowed example account ID" >&2
      bad=1
    fi
  done < <(grep -InoE '[0-9]+' "$file" || true)
done < <(git ls-files --cached --others --exclude-standard \
  | grep -vE '(\.png|\.svg|\.terraform\.lock\.hcl|\.secrets\.baseline)$')

if [[ "$bad" -ne 0 ]]; then
  exit 1
fi
echo "Only example account IDs found."
