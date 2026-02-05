#!/usr/bin/env bash

# Plugin Version Manager
# Automatically detects all plugins and updates their versions

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Get the root directory (parent of scripts/)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# Find all plugin.json files
find_plugins() {
    find "$ROOT_DIR" -name "plugin.json" -path "*/.claude-plugin/*" -type f 2>/dev/null | sort
}

# Extract version from plugin.json (first occurrence only, outside of author block)
get_version() {
    local file="$1"
    # Use jq if available, otherwise fall back to grep
    if command -v jq &> /dev/null; then
        jq -r '.version' "$file"
    else
        grep -m1 '"version"' "$file" | sed 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/'
    fi
}

# Extract name from plugin.json (top-level name, not author name)
get_name() {
    local file="$1"
    # Use jq if available, otherwise fall back to grep
    if command -v jq &> /dev/null; then
        jq -r '.name' "$file"
    else
        grep -m1 '"name"' "$file" | sed 's/.*"name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/'
    fi
}

# Get plugin directory from plugin.json path
get_plugin_dir() {
    local file="$1"
    dirname "$(dirname "$file")"
}

# Update version in a file
update_version() {
    local file="$1"
    local new_version="$2"

    if command -v jq &> /dev/null; then
        # Use jq for safe JSON manipulation
        local tmp_file="${file}.tmp"
        jq --arg v "$new_version" '.version = $v' "$file" > "$tmp_file" && mv "$tmp_file" "$file"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS sed
        sed -i '' "s/\"version\"[[:space:]]*:[[:space:]]*\"[^\"]*\"/\"version\": \"$new_version\"/" "$file"
    else
        # Linux sed
        sed -i "s/\"version\"[[:space:]]*:[[:space:]]*\"[^\"]*\"/\"version\": \"$new_version\"/" "$file"
    fi
}

# Validate semantic version
validate_version() {
    local version="$1"
    if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.]+)?$ ]]; then
        return 1
    fi
    return 0
}

# Increment version
increment_version() {
    local version="$1"
    local part="$2"  # major, minor, patch

    IFS='.' read -r major minor patch <<< "${version%%-*}"

    case "$part" in
        major)
            echo "$((major + 1)).0.0"
            ;;
        minor)
            echo "$major.$((minor + 1)).0"
            ;;
        patch)
            echo "$major.$minor.$((patch + 1))"
            ;;
    esac
}

# Main script
main() {
    echo -e "${BOLD}${CYAN}╔═══════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${CYAN}║     Plugin Version Manager            ║${NC}"
    echo -e "${BOLD}${CYAN}╚═══════════════════════════════════════╝${NC}"
    echo ""

    # Find all plugins
    mapfile -t plugin_files < <(find_plugins)

    if [[ ${#plugin_files[@]} -eq 0 ]]; then
        echo -e "${RED}No plugins found!${NC}"
        exit 1
    fi

    # Display current versions
    echo -e "${BOLD}Current Plugin Versions:${NC}"
    echo -e "${BLUE}─────────────────────────────────────────${NC}"
    printf "${BOLD}%-20s %-15s %s${NC}\n" "Plugin" "Version" "Path"
    echo -e "${BLUE}─────────────────────────────────────────${NC}"

    declare -A plugin_versions
    declare -A plugin_paths

    for file in "${plugin_files[@]}"; do
        name=$(get_name "$file")
        version=$(get_version "$file")
        rel_path="${file#$ROOT_DIR/}"

        plugin_versions["$name"]="$version"
        plugin_paths["$name"]="$file"

        printf "%-20s ${GREEN}%-15s${NC} %s\n" "$name" "$version" "$rel_path"
    done

    echo -e "${BLUE}─────────────────────────────────────────${NC}"
    echo ""

    # Check if all versions are the same
    unique_versions=($(printf '%s\n' "${plugin_versions[@]}" | sort -u))

    if [[ ${#unique_versions[@]} -eq 1 ]]; then
        current_version="${unique_versions[0]}"
        echo -e "${GREEN}All plugins are at version ${BOLD}$current_version${NC}"
    else
        echo -e "${YELLOW}Warning: Plugins have different versions${NC}"
        current_version="${unique_versions[0]}"
    fi

    echo ""

    # Ask what to do
    echo -e "${BOLD}What would you like to do?${NC}"
    echo ""
    echo -e "  ${CYAN}1)${NC} Bump ${BOLD}patch${NC} version (${current_version} → $(increment_version "$current_version" patch))"
    echo -e "  ${CYAN}2)${NC} Bump ${BOLD}minor${NC} version (${current_version} → $(increment_version "$current_version" minor))"
    echo -e "  ${CYAN}3)${NC} Bump ${BOLD}major${NC} version (${current_version} → $(increment_version "$current_version" major))"
    echo -e "  ${CYAN}4)${NC} Set ${BOLD}custom${NC} version"
    echo -e "  ${CYAN}5)${NC} Update ${BOLD}specific${NC} plugin only"
    echo -e "  ${CYAN}q)${NC} Quit"
    echo ""
    read -p "Select option [1-5/q]: " choice

    case "$choice" in
        1)
            new_version=$(increment_version "$current_version" patch)
            ;;
        2)
            new_version=$(increment_version "$current_version" minor)
            ;;
        3)
            new_version=$(increment_version "$current_version" major)
            ;;
        4)
            read -p "Enter new version (e.g., 2.0.0): " new_version
            if ! validate_version "$new_version"; then
                echo -e "${RED}Invalid version format. Use semantic versioning (e.g., 1.2.3)${NC}"
                exit 1
            fi
            ;;
        5)
            echo ""
            echo -e "${BOLD}Select plugin to update:${NC}"
            plugin_names=("${!plugin_versions[@]}")
            for i in "${!plugin_names[@]}"; do
                echo -e "  ${CYAN}$((i+1)))${NC} ${plugin_names[$i]} (${plugin_versions[${plugin_names[$i]}]})"
            done
            echo ""
            read -p "Select plugin [1-${#plugin_names[@]}]: " plugin_choice

            if [[ ! "$plugin_choice" =~ ^[0-9]+$ ]] || [[ "$plugin_choice" -lt 1 ]] || [[ "$plugin_choice" -gt ${#plugin_names[@]} ]]; then
                echo -e "${RED}Invalid selection${NC}"
                exit 1
            fi

            selected_plugin="${plugin_names[$((plugin_choice-1))]}"
            selected_version="${plugin_versions[$selected_plugin]}"

            echo ""
            echo -e "Current version of ${BOLD}$selected_plugin${NC}: ${GREEN}$selected_version${NC}"
            read -p "Enter new version: " new_version

            if ! validate_version "$new_version"; then
                echo -e "${RED}Invalid version format. Use semantic versioning (e.g., 1.2.3)${NC}"
                exit 1
            fi

            # Update only the selected plugin
            echo ""
            update_version "${plugin_paths[$selected_plugin]}" "$new_version"
            echo -e "${GREEN}✓${NC} Updated ${BOLD}$selected_plugin${NC} to ${GREEN}$new_version${NC}"
            echo ""
            echo -e "${GREEN}Done!${NC}"
            exit 0
            ;;
        q|Q)
            echo "Cancelled."
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            exit 1
            ;;
    esac

    # Confirm update
    echo ""
    echo -e "${BOLD}Will update all plugins to version: ${GREEN}$new_version${NC}"
    echo ""
    read -p "Proceed? [y/N]: " confirm

    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo "Cancelled."
        exit 0
    fi

    # Update all plugins
    echo ""
    for name in "${!plugin_paths[@]}"; do
        file="${plugin_paths[$name]}"
        old_version="${plugin_versions[$name]}"
        update_version "$file" "$new_version"
        echo -e "${GREEN}✓${NC} ${name}: ${old_version} → ${GREEN}${new_version}${NC}"
    done

    echo ""
    echo -e "${GREEN}${BOLD}All plugins updated to version $new_version${NC}"
    echo ""

    # Suggest git commit
    echo -e "${YELLOW}Suggested commit:${NC}"
    echo -e "  git add -A && git commit -m \"chore: bump plugin versions to $new_version\""
}

main "$@"
