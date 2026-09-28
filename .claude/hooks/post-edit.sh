#!/usr/bin/env bash
# Post-edit hook: format the file Claude Code just edited.
set -euo pipefail

FILE="$(jq -r '.tool_input.file_path // empty')"
[[ -z "$FILE" || ! -f "$FILE" ]] && exit 0

case "$FILE" in
  *.tf | *.tfvars | *.tftest.hcl)
    terraform fmt "$FILE" >/dev/null 2>&1 || true
    ;;
  *.sh)
    if command -v shellharden >/dev/null 2>&1; then
      shellharden --replace "$FILE" 2>/dev/null || true
    fi
    chmod +x "$FILE"
    ;;
  *.md)
    if command -v markdownlint >/dev/null 2>&1; then
      markdownlint --fix "$FILE" 2>/dev/null || true
    fi
    ;;
esac
