#!/usr/bin/env bash
# Sync the canonical coreui-styling SCSS into every CLASS Angular project's
# actual build output (src/styles/). The skill's docs (design-system.md,
# README.md, reference/) need NO sync step — .claude/skills/coreui-styling
# is a symlink to /d/AGENTS/skills/coreui-styling in every project, so
# editing it anywhere already updates it everywhere.
#
# This script only handles the part that is NOT symlinked: each project's
# own src/styles/*.scss, which Angular actually compiles.
#
# Source of truth: /d/AGENTS/skills/coreui-styling/reference/styles/
# Edit files there (or through any project's symlinked copy — same file),
# then re-run this script. Idempotent — safe to run as often as needed.
#
# Usage:
#   ./sync-design-system.sh              # sync all known projects
#   ./sync-design-system.sh crmclass-app # sync a single project by folder name

set -euo pipefail

HUB_STYLES="/d/AGENTS/skills/coreui-styling/reference/styles"
ROOT="/d/sistemas"

# folder-name -> absolute path
#
# NOT included: nfeclass-app (still on Tailwind for page content — this
# design system explicitly excludes Tailwind, see design-system.md) and
# shopclass-app (no @coreui dependency at all — never onboarded). Both had
# stray, never-wired _tokens.scss/_ds-*.scss files sitting in src/styles/
# from an earlier abandoned attempt; those were removed rather than synced,
# to avoid dead files implying an adoption that never happened. Onboarding
# either one is a real migration project (drop Tailwind or add CoreUI+
# Bootstrap first), not something this script should attempt silently.
declare -A PROJECTS=(
  [erpclass-admin]="$ROOT/ERPCLASS/erpclass-admin"
  [erpclass-dash]="$ROOT/ERPCLASS/erpclass-dash"
  [erpclass-cob]="$ROOT/ERPCLASS/erpclass-cob"
  [erpclass-cota]="$ROOT/ERPCLASS/erpclass-cota"
  [erpclass-mkt]="$ROOT/ERPCLASS/erpclass-mkt"
  [erpclass-help]="$ROOT/ERPCLASS/erpclass-help"
  [erpclass-conn]="$ROOT/ERPCLASS/erpclass-conn"
  [mobiclass-app]="$ROOT/MOBICLASS/mobiclass-app"
  [crmclass-app]="$ROOT/CRMCLASS/crmclass-app"
)

TARGET_FILTER="${1:-}"

sync_one() {
  local name="$1"
  local dir="$2"
  local styles_dir="$dir/src/styles"

  if [ ! -d "$dir" ]; then
    echo "SKIP  $name (not found: $dir)"
    return
  fi
  if [ ! -d "$styles_dir" ]; then
    echo "SKIP  $name (no src/styles/ — not this design system's layout)"
    return
  fi

  local changed=0
  for f in _tokens.scss _ds-components.scss _ds-forms.scss _theme.scss; do
    if [ ! -f "$styles_dir/$f" ] || ! cmp -s "$HUB_STYLES/$f" "$styles_dir/$f"; then
      cp "$HUB_STYLES/$f" "$styles_dir/$f"
      changed=1
    fi
  done

  local has_swal=0
  if [ -f "$dir/package.json" ] && grep -q '"sweetalert2"' "$dir/package.json"; then
    has_swal=1
    if [ ! -f "$styles_dir/_ds-modals.scss" ] || ! cmp -s "$HUB_STYLES/_ds-modals.scss" "$styles_dir/_ds-modals.scss"; then
      cp "$HUB_STYLES/_ds-modals.scss" "$styles_dir/_ds-modals.scss"
      changed=1
    fi

    local custom_scss="$styles_dir/_custom.scss"
    if [ -f "$custom_scss" ] && ! grep -q "ds-modals" "$custom_scss"; then
      printf "@use 'ds-modals';\n%s\n" "$(cat "$custom_scss")" > "$custom_scss"
      changed=1
      echo "      -> wired @use 'ds-modals'; into _custom.scss (review placement)"
    fi
  fi

  if [ "$changed" = "1" ]; then
    echo "SYNC  $name (styles updated$([ "$has_swal" = "1" ] && echo ", ds-modals present"))"
  else
    echo "OK    $name (already in sync)"
  fi
}

if [ -n "$TARGET_FILTER" ]; then
  if [ -z "${PROJECTS[$TARGET_FILTER]+x}" ]; then
    echo "Unknown project: $TARGET_FILTER" >&2
    exit 1
  fi
  sync_one "$TARGET_FILTER" "${PROJECTS[$TARGET_FILTER]}"
else
  for name in "${!PROJECTS[@]}"; do
    sync_one "$name" "${PROJECTS[$name]}"
  done
fi
