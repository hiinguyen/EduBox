#!/usr/bin/env sh
# Idempotent first-run setup for a clean checkout.
#
# Creates edubox_server/config/passwords.yaml from the committed dev-only
# passwords.example.yaml when it is missing. It never overwrites an existing
# passwords.yaml, so a developer's own OpenRouter key survives.
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
example="$repo_root/edubox_server/config/passwords.example.yaml"
target="$repo_root/edubox_server/config/passwords.yaml"

if [ -f "$target" ]; then
  echo "bootstrap: $target exists, left unchanged"
else
  cp "$example" "$target"
  echo "bootstrap: created $target from passwords.example.yaml (dev-only values)"
fi
