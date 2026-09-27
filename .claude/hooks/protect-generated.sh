#!/usr/bin/env bash
# Pre-edit hook: block hand edits to generated files.
set -euo pipefail

FILE="$(jq -r '.tool_input.file_path // empty')"

case "$FILE" in
  */.terraform.lock.hcl | */.terraform/*)
    echo "Generated file: run terraform providers lock or terraform init instead of editing $FILE." >&2
    exit 2
    ;;
  docs/diagrams/*.png | */docs/diagrams/*.png)
    echo "Rendered diagram: edit the source in docs/diagrams/ and re-render instead of editing $FILE." >&2
    exit 2
    ;;
esac
exit 0
