#!/usr/bin/env sh
# Idempotent first-run setup for a clean checkout.
#
# Creates edubox_server/config/passwords.yaml from the committed dev-only
# passwords.example.yaml when it is missing. It never overwrites an existing
# passwords.yaml, so a developer's own OpenRouter key survives.
#
# When passwords.yaml exists, it checks that every `<runMode>.<key>` in the
# example is also present there (a key added to the example after the file was
# created, e.g. test.e2eControlToken). Missing keys are listed and the script
# exits 1, so the test run fails here with a clear message instead of later
# with a confusing authorization error.
set -eu

repo_root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
example="$repo_root/edubox_server/config/passwords.example.yaml"
target="$repo_root/edubox_server/config/passwords.yaml"

# Prints `<section>.<key>` for every key nested one level under a top-level
# section, ignoring comments and blank lines.
yaml_keys() {
  awk '
    /^[[:space:]]*(#|$)/ { next }
    /^[A-Za-z0-9_]+:[[:space:]]*(#.*)?$/ {
      section = $0
      sub(/:.*/, "", section)
      next
    }
    /^[^[:space:]]/ { section = ""; next }
    section != "" && /^[[:space:]]+[A-Za-z0-9_]+:/ {
      key = $0
      sub(/^[[:space:]]+/, "", key)
      sub(/:.*/, "", key)
      print section "." key
    }
  ' "$1" | LC_ALL=C sort -u
}

if [ ! -f "$target" ]; then
  cp "$example" "$target"
  echo "bootstrap: created $target from passwords.example.yaml (dev-only values)"
  exit 0
fi

echo "bootstrap: $target exists, left unchanged"

target_keys=$(yaml_keys "$target")
missing=$(yaml_keys "$example" | while IFS= read -r key; do
  if ! printf '%s\n' "$target_keys" | grep -Fqx -- "$key"; then
    printf '%s\n' "$key"
  fi
done)

if [ -n "$missing" ]; then
  echo "bootstrap: ERROR $target is missing keys that passwords.example.yaml defines:" >&2
  printf '%s\n' "$missing" | sed 's/^/  - /' >&2
  echo "bootstrap: copy them from passwords.example.yaml (dev-only values), or move" >&2
  echo "bootstrap: passwords.yaml aside and re-run tool/bootstrap.sh." >&2
  exit 1
fi
