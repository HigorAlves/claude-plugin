#!/usr/bin/env bash
# Plugin Ecosystem Validator
# Validates structural compliance, version sync, frontmatter, and safety constraints.
# Exit code 0 = all checks pass, non-zero = failures found.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# Use temp files for counters (avoids subshell scoping issues with pipes)
ERR_FILE=$(mktemp)
WARN_FILE=$(mktemp)
echo 0 > "$ERR_FILE"
echo 0 > "$WARN_FILE"
trap 'rm -f "$ERR_FILE" "$WARN_FILE"' EXIT

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

error() {
  echo -e "  ${RED}✗${NC} $1"
  echo $(( $(cat "$ERR_FILE") + 1 )) > "$ERR_FILE"
}

warn() {
  echo -e "  ${YELLOW}!${NC} $1"
  echo $(( $(cat "$WARN_FILE") + 1 )) > "$WARN_FILE"
}

pass() { echo -e "  ${GREEN}✓${NC} $1"; }

section() { echo -e "\n${BOLD}${CYAN}[$1]${NC}"; }

# ─── 1. JSON Validation ──────────────────────────────────────────────

section "JSON Validation"

while IFS= read -r file; do
  rel="${file#$ROOT_DIR/}"
  if python3 -c "import json; json.load(open('$file'))" 2>/dev/null; then
    pass "$rel"
  else
    error "$rel — invalid JSON"
  fi
done < <(find "$ROOT_DIR" \( -name "plugin.json" -o -name "marketplace.json" -o -name "hooks.json" \) -not -path "*/node_modules/*" -not -path "*/.git/*" | sort)

# ─── 2. Agent Frontmatter ────────────────────────────────────────────

section "Agent Frontmatter"

MAX_DESCRIPTION_LENGTH=300

while IFS= read -r file; do
  rel="${file#$ROOT_DIR/}"
  agent_name=$(basename "$file" .md)

  # Check file starts with ---
  if ! head -1 "$file" | grep -q "^---$"; then
    error "$rel — missing frontmatter"
    continue
  fi

  # Extract frontmatter (between first two ---)
  frontmatter=$(awk '/^---$/{n++; if(n==2) exit; next} n==1{print}' "$file")

  # Check required fields
  for field in name description; do
    if ! echo "$frontmatter" | grep -q "^${field}:"; then
      error "$rel — missing required field: $field"
    fi
  done

  # Check name matches filename
  declared_name=$(echo "$frontmatter" | grep "^name:" | head -1 | sed 's/^name:[[:space:]]*//')
  if [[ -n "$declared_name" && "$declared_name" != "$agent_name" ]]; then
    error "$rel — name '$declared_name' doesn't match filename '$agent_name'"
  fi

  # Check maxTurns exists
  if ! echo "$frontmatter" | grep -q "^maxTurns:"; then
    warn "$rel — missing maxTurns (agents can run unbounded)"
  fi

  # Check description length
  desc=$(echo "$frontmatter" | grep "^description:" | head -1 | sed 's/^description:[[:space:]]*//')
  desc_len=${#desc}
  if [[ $desc_len -gt $MAX_DESCRIPTION_LENGTH ]]; then
    warn "$rel — description is $desc_len chars (max $MAX_DESCRIPTION_LENGTH). Descriptions are always loaded into context."
  fi

  pass "$rel"
done < <(find "$ROOT_DIR" -path "*/agents/*.md" -not -path "*/node_modules/*" -not -path "*/.git/*" | sort)

# ─── 3. Skill Frontmatter ────────────────────────────────────────────

section "Skill Frontmatter"

while IFS= read -r file; do
  rel="${file#$ROOT_DIR/}"

  frontmatter=$(awk '/^---$/{n++; if(n==2) exit; next} n==1{print}' "$file")

  # Check name exists and is lowercase-hyphen
  skill_name=$(echo "$frontmatter" | grep "^name:" | head -1 | sed 's/^name:[[:space:]]*//')
  if [[ -z "$skill_name" ]]; then
    error "$rel — missing name field"
  elif [[ "$skill_name" =~ [A-Z\ ] ]]; then
    error "$rel — name '$skill_name' must be lowercase-hyphen (e.g., 'spec-authoring')"
  else
    pass "$rel"
  fi

  # Check no version field (not valid for skills)
  if echo "$frontmatter" | grep -q "^version:"; then
    warn "$rel — 'version' is not a standard skill frontmatter field"
  fi
done < <(find "$ROOT_DIR" -name "SKILL.md" -not -path "*/node_modules/*" -not -path "*/.git/*" | sort)

# ─── 4. Command Frontmatter ──────────────────────────────────────────

section "Command Frontmatter"

while IFS= read -r file; do
  rel="${file#$ROOT_DIR/}"
  has_error=false

  frontmatter=$(awk '/^---$/{n++; if(n==2) exit; next} n==1{print}' "$file")

  # Check description exists
  if ! echo "$frontmatter" | grep -q "^description:"; then
    error "$rel — missing description field"
    has_error=true
  fi

  # Check for non-standard 'args' field (should be 'argument-hint')
  if echo "$frontmatter" | grep -q "^args:"; then
    error "$rel — uses 'args:' instead of 'argument-hint:'"
    has_error=true
  fi

  # Check for unrestricted Bash in allowed-tools
  bash_entries=$(echo "$frontmatter" | grep -oE '"Bash"' || true)
  if [[ -n "$bash_entries" ]]; then
    error "$rel — unrestricted Bash in allowed-tools (use scoped patterns like 'Bash(git *:*)')"
    has_error=true
  fi

  if [[ "$has_error" == false ]]; then
    pass "$rel"
  fi
done < <(find "$ROOT_DIR" -path "*/commands/*.md" -not -path "*/node_modules/*" -not -path "*/.git/*" | sort)

# ─── 5. Version Sync ─────────────────────────────────────────────────

section "Version Sync"

MARKETPLACE="$ROOT_DIR/.claude-plugin/marketplace.json"

if [[ -f "$MARKETPLACE" ]]; then
  marketplace_plugins=$(python3 -c "
import json
d = json.load(open('$MARKETPLACE'))
for p in d['plugins']:
    print(f\"{p['name']}={p['version']}\")
")

  while IFS='=' read -r mp_name mp_version; do
    plugin_json=$(find "$ROOT_DIR" -path "*/$mp_name/.claude-plugin/plugin.json" -type f 2>/dev/null | head -1)
    if [[ -n "$plugin_json" ]]; then
      pj_version=$(python3 -c "import json; print(json.load(open('$plugin_json'))['version'])")
      if [[ "$mp_version" == "$pj_version" ]]; then
        pass "$mp_name: marketplace=$mp_version, plugin.json=$pj_version"
      else
        error "$mp_name: marketplace=$mp_version != plugin.json=$pj_version"
      fi
    else
      warn "$mp_name: listed in marketplace but no plugin.json found"
    fi
  done <<< "$marketplace_plugins"
else
  warn "marketplace.json not found"
fi

# ─── 6. Plugin.json Validation ───────────────────────────────────────

section "Plugin.json Validation"

while IFS= read -r file; do
  rel="${file#$ROOT_DIR/}"
  dir_name=$(basename "$(dirname "$(dirname "$file")")")
  has_error=false

  # Check required fields
  for field in name version description; do
    if ! python3 -c "import json; d=json.load(open('$file')); assert '$field' in d" 2>/dev/null; then
      error "$rel — missing required field: $field"
      has_error=true
    fi
  done

  # Check plugin name matches directory
  pj_name=$(python3 -c "import json; print(json.load(open('$file'))['name'])")
  if [[ "$pj_name" != "$dir_name" ]]; then
    error "$rel — name '$pj_name' doesn't match directory '$dir_name'"
    has_error=true
  fi

  if [[ "$has_error" == false ]]; then
    pass "$rel"
  fi
done < <(find "$ROOT_DIR" -name "plugin.json" -path "*/.claude-plugin/*" -not -name "marketplace.json" -not -path "*/.git/*" | sort)

# ─── 7. Hooks Validation ─────────────────────────────────────────────

section "Hooks Validation"

while IFS= read -r file; do
  rel="${file#$ROOT_DIR/}"

  has_session=$(python3 -c "
import json, sys
d = json.load(open('$file'))
hooks = d.get('hooks', {})
if 'SessionStart' in hooks:
    for entry in hooks['SessionStart']:
        if 'matcher' not in entry:
            print('missing')
            sys.exit(0)
print('ok')
" 2>/dev/null)

  if [[ "$has_session" == "missing" ]]; then
    warn "$rel — SessionStart hook missing 'matcher' field"
  elif [[ "$has_session" == "ok" ]]; then
    pass "$rel"
  fi
done < <(find "$ROOT_DIR" -name "hooks.json" -not -path "*/node_modules/*" -not -path "*/.git/*" | sort)

# ─── 8. Reference Integrity ──────────────────────────────────────────

section "Reference Integrity"

while IFS= read -r ref_dir; do
  skill_dir=$(dirname "$ref_dir")
  skill_md="$skill_dir/SKILL.md"

  if [[ -f "$skill_md" ]]; then
    while IFS= read -r ref; do
      ref_path="$skill_dir/$ref"
      rel="${ref_path#$ROOT_DIR/}"
      if [[ -f "$ref_path" ]]; then
        pass "$rel exists"
      else
        error "$rel — referenced in SKILL.md but file not found"
      fi
    done < <(grep -oE 'references/[a-z0-9-]+\.md' "$skill_md" 2>/dev/null | sort -u)
  fi
done < <(find "$ROOT_DIR" -path "*/skills/*/references" -type d -not -path "*/.git/*")

# ─── Summary ─────────────────────────────────────────────────────────

ERRORS=$(cat "$ERR_FILE")
WARNINGS=$(cat "$WARN_FILE")

echo ""
echo -e "${BOLD}─────────────────────────────────────────${NC}"
if [[ $ERRORS -eq 0 && $WARNINGS -eq 0 ]]; then
  echo -e "${GREEN}${BOLD}All checks passed!${NC}"
elif [[ $ERRORS -eq 0 ]]; then
  echo -e "${YELLOW}${BOLD}Passed with $WARNINGS warning(s)${NC}"
else
  echo -e "${RED}${BOLD}Failed: $ERRORS error(s), $WARNINGS warning(s)${NC}"
fi

if [[ $ERRORS -gt 0 ]]; then
  exit 1
fi
exit 0
