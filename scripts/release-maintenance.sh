#!/bin/bash
#
# A script to automate release maintenance for Rancher docs.
#
# This script updates multiple AsciiDoc files with new version information.
# It supports two modes:
#   1. Interactive: Prompts the user for all necessary information.
#   2. Non-interactive: Takes all information as command-line arguments.

set -o errexit
set -o nounset
set -o pipefail

# --- Configuration ---
# Base path to the documentation repository.
# The script assumes it is located in the root of the docs repository.
# It determines its own location to make the path portable.
DOCS_REPO_PATH=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
DOCS_REPO_PATH=${DOCS_REPO_PATH%scripts}

# --- Global Variables ---
INTERACTIVE=false
VERSION=""
TAG_VERSION=""
RELEASE_DATE=""
ADAPTER_VERSION=""
WEBHOOK_VERSION=""
TURTLES_VERSION=""
FLEET_VERSION=""
NEW_CURRENT_PRIME_AVAIL="y"
NEW_CURRENT_COMMUNITY_AVAIL="y"

# --- Functions ---

# Print usage information and exit.
usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

This script automates the process of release maintenance for Rancher docs.

Modes of Operation:
  Interactive (default):
    Run the script without any arguments to be prompted for all required values.
    $ ./scripts/$(basename "$0")

  Non-interactive:
    Provide a git tag to derive the version and fetch component versions automatically.
    $ ./scripts/$(basename "$0") -t v2.13.2-alpha3 -d "2026-05-27"

    Or, provide the version and component versions manually:
    $ ./scripts/$(basename "$0") -v v2.13.2 -d "2026-05-27" -a v107.0.1+up8.0.0 -w v0.9.2 -T 108.0.4+up0.25.4-rc.1 -F 108.0.2+up0.14.2

Options:
  -v <version>          The new Rancher version (e.g., v2.13.2). (Required if -t is not used)
  -d <date>             The release date (e.g., "2026-05-27"). (Required)
  -t <tag>              A git tag from rancher/rancher repository (e.g., v2.13.1-alpha4).
                        If used, the version is derived from the tag, and -a and -w are fetched from GitHub.
  -a <adapter_version>  The corresponding CSP adapter version. (Required if -t is not used)
  -w <webhook_version>  The corresponding webhook version. (Required if -t is not used)
  -T <turtles_version>  The corresponding Turtles version. (Required if -t is not used)
  -F <fleet_version>    The corresponding Fleet version. (Required if -t is not used)

  --prime [y/n]         Is this version available in Prime? (Default: y)
  --community [y/n]     Is this version available in Community? (Default: y)
  -h, --help            Display this help message and exit.
EOF
  exit 1
}

# Prompt user for inputs in interactive mode.
get_inputs_interactive() {
  echo "Running in interactive mode. Please provide the release details."
  read -rp "Enter a git tag (e.g., v2.13.1-alpha4), or leave blank to enter version manually: " TAG_VERSION
  read -rp "Enter the release date (e.g., 2026-05-27): " RELEASE_DATE

  if [[ -n "$TAG_VERSION" ]]; then
    VERSION=${TAG_VERSION%%-*}
    echo "  -> Derived version: ${VERSION}"
  else
    read -rp "Enter the new Rancher version (e.g., v2.13.2): " VERSION
    read -rp "Enter the CSP adapter version: " ADAPTER_VERSION
    read -rp "Enter the webhook version: " WEBHOOK_VERSION
    read -rp "Enter the Turtles version: " TURTLES_VERSION
    read -rp "Enter the Fleet version: " FLEET_VERSION
  fi

  read -rp "Is this version available in Prime? [Y/n]: " NEW_CURRENT_PRIME_AVAIL
  NEW_CURRENT_PRIME_AVAIL=${NEW_CURRENT_PRIME_AVAIL:-y}
  read -rp "Is this version available in Community? [Y/n]: " NEW_CURRENT_COMMUNITY_AVAIL
  NEW_CURRENT_COMMUNITY_AVAIL=${NEW_CURRENT_COMMUNITY_AVAIL:-y}
  echo
}

# Parse command-line arguments.
parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -v) VERSION="$2"; shift 2 ;;
      -t) TAG_VERSION="$2"; shift 2 ;;
      -d) RELEASE_DATE="$2"; shift 2 ;;
      -a) ADAPTER_VERSION="$2"; shift 2 ;;
      -w) WEBHOOK_VERSION="$2"; shift 2 ;;
      -T) TURTLES_VERSION="$2"; shift 2 ;;
      -F) FLEET_VERSION="$2"; shift 2 ;;
      --prime) NEW_CURRENT_PRIME_AVAIL="$2"; shift 2 ;;
      --community) NEW_CURRENT_COMMUNITY_AVAIL="$2"; shift 2 ;;
      -h|--help) usage ;;
      *) echo "Unknown option: $1"; usage ;;
    esac
  done
}

# Validate that all required inputs have been provided and are in the correct format.
validate_inputs() {
  local valid=true
  if [[ -z "$VERSION" ]]; then echo "Error: Version is required. Use -v or -t."; valid=false; fi
  if [[ ! "$VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then echo "Error: Version format must be vX.Y.Z."; valid=false; fi
  if [[ -z "$RELEASE_DATE" ]]; then echo "Error: Release date is required."; valid=false; fi
  if ! date -d "$RELEASE_DATE" >/dev/null 2>&1; then echo "Error: Invalid date format for '$RELEASE_DATE'."; valid=false; fi
  
  if [[ -z "$TAG_VERSION" ]]; then
    if [[ -z "$ADAPTER_VERSION" ]]; then echo "Error: Adapter version is required when not using -t."; valid=false; fi
    if [[ -z "$WEBHOOK_VERSION" ]]; then echo "Error: Webhook version is required when not using -t."; valid=false; fi
    if [[ -z "$TURTLES_VERSION" ]]; then echo "Error: Turtles version is required when not using -t."; valid=false; fi
    if [[ -z "$FLEET_VERSION" ]]; then echo "Error: Fleet version is required when not using -t."; valid=false; fi
  fi

  if ! "$valid"; then
    echo
    usage
  fi
}

# Execute a command.
run_cmd() {
  ex -s "$1" <<< "$2"
}

# Update the revdate in a given file.
update_revdate() {
  local file="$1"
  local iso_date="$2"
  echo "-> Updating revdate in $file"
  local ex_cmd
  ex_cmd=$(cat <<EOF
%s/^:revdate: .*/:revdate: ${iso_date}/
x
EOF
)
  run_cmd "$file" "$ex_cmd"
}

# Update the release-notes.adoc file.
update_release_notes() {
  local file="$1"
  local version="$2"
  local new_prime_mark="$3"
  local new_community_mark="$4"

  echo "-> Updating release notes in $file"

  # 1. Capture the content of the current version block using specific markers.
  local current_block
  current_block=$(awk '/\/\/.*CURRENT VERSION END\./{p=0} /\/\/.*CURRENT VERSION\./{p=1; next} p' "$file")
  if [[ -z "$current_block" ]]; then
    echo "Error: Could not find 'CURRENT VERSION' block in $file" >&2
    exit 1
  fi

  # 2. Create the new past version entry by modifying the captured current block.
  local old_version
  old_version=$(echo "$current_block" | head -n 1 | cut -d '|' -f 2 | tr -d ' ')

  local past_block
  if [[ -n "$old_version" ]]; then
    # When moving a version to "Past", update its support matrix link from "N/A" to a URL.
    local url_version_part="rancher-$(echo "$old_version" | tr '.' '-')"
    local support_matrix_url="https://www.suse.com/suse-rancher/support-matrix/all-supported-versions/${url_version_part}/"
    local support_matrix_cell="| ${support_matrix_url}[View]"
    # Replace the "| N/A" line for the support matrix with the generated URL.
    past_block=$(echo "${current_block}" | sed "0,/^| N\/A\$/s#^| N/A\$#${support_matrix_cell}#")
  else
    # Fallback if the old version couldn't be parsed.
    past_block="${current_block}"
  fi
  past_block="${past_block}"$'\n'

  # 3. Create the new current version entry.
  local new_current_block
  new_current_block=$(cat <<EOF
| ${version}
| xref:release-notes/${version}.adoc[View]
| N/A
| ${new_prime_mark}
| ${new_community_mark}

EOF
)

  # 4. Atomically update the file: insert past version and replace current version.
  local ex_cmd
  ex_cmd=$(cat <<EOF
/\/\/.*PAST VERSIONS\./a
${past_block}
.
/\/\/.*CURRENT VERSION\./+1,/\/\/.*CURRENT VERSION END\./-1d
/\/\/.*CURRENT VERSION\./a
${new_current_block}
.
x
EOF
)
  run_cmd "$file" "$ex_cmd"
}

# Update a simple compatibility matrix file.
update_matrix() {
  local file="$1"
  local header_pattern="$2"
  local new_row="$3"
  
  echo "-> Updating matrix in $file"
  local ex_cmd
  ex_cmd=$(cat <<EOF
/${header_pattern}/a
${new_row}
.
x
EOF
)
  run_cmd "$file" "$ex_cmd"
}

# Update an attribute in antora.yml.
update_antora_attr() {
  local file="$1"
  local attr="$2"
  local value="$3"
  echo "-> Updating $attr in $file"
  local ex_cmd
  ex_cmd=$(cat <<EOF
%s/^\(\s*\)${attr}: .*/\1${attr}: ${value}/
x
EOF
)
  run_cmd "$file" "$ex_cmd"
}

# --- Main Logic ---
main() {
  if [[ $# -eq 0 ]]; then
    INTERACTIVE=true
    get_inputs_interactive
  else
    parse_args "$@"
    # If a tag is provided without an explicit version, derive the version from the tag.
    if [[ -n "$TAG_VERSION" ]] && [[ -z "$VERSION" ]]; then
      VERSION=${TAG_VERSION%%-*}
      echo "-> Derived version from tag: ${VERSION}"
    fi
  fi

  # Sync webhook availability with new version availability. This simplifies input
  # by only requiring one set of availability flags (prime/community).
  local WEBHOOK_PRIME_AVAIL=$NEW_CURRENT_PRIME_AVAIL
  local WEBHOOK_COMMUNITY_AVAIL=$NEW_CURRENT_COMMUNITY_AVAIL

  validate_inputs

  # If a tag is provided, fetch versions from GitHub.
  if [[ -n "$TAG_VERSION" ]]; then
    echo "-> Fetching versions from GitHub tag: ${TAG_VERSION}..."
    local build_yaml_url="https://raw.githubusercontent.com/rancher/rancher/refs/tags/${TAG_VERSION}/build.yaml"
    local build_yaml_content
    # Use curl to fetch the content. -sS for silent with errors, -f for fail-fast, -L to follow redirects.
    build_yaml_content=$(curl -sSfL "$build_yaml_url")
    if [[ $? -ne 0 ]] || [[ -z "$build_yaml_content" ]]; then
        echo "Error: Failed to fetch or empty content from $build_yaml_url" >&2
        exit 1
    fi

    # Parse YAML content using grep and awk. This is simple and avoids extra dependencies.
    WEBHOOK_VERSION=$(echo "$build_yaml_content" | awk '/^webhookVersion:/ {print $2}')
    ADAPTER_VERSION=$(echo "$build_yaml_content" | awk '/^cspAdapterMinVersion:/ {print $2}')
    TURTLES_VERSION=$(echo "$build_yaml_content" | awk '/^turtlesVersion:/ {print $2}')
    FLEET_VERSION=$(echo "$build_yaml_content" | awk '/^fleetVersion:/ {print $2}')

    if [[ -z "$WEBHOOK_VERSION" ]] || [[ -z "$ADAPTER_VERSION" ]]; then
        echo "Error: Could not parse webhookVersion or cspAdapterMinVersion from build.yaml" >&2
        exit 1
    fi
    echo "  - Found Webhook Version: ${WEBHOOK_VERSION}"
    echo "  - Found Adapter Version: ${ADAPTER_VERSION}"
    if [[ -n "$TURTLES_VERSION" ]]; then
      echo "  - Found Turtles Version: ${TURTLES_VERSION}"
    fi
    if [[ -n "$FLEET_VERSION" ]]; then
      echo "  - Found Fleet Version: ${FLEET_VERSION}"
    fi
  fi

  # Prepare variables
  local iso_date
  iso_date=$(date -d "$RELEASE_DATE" "+%Y-%m-%d")
  local version_no_v="${VERSION#v}"
  local minor_version_no_v
  minor_version_no_v=$(echo "$version_no_v" | cut -d. -f1,2)
  local minor_version_with_v="v${minor_version_no_v}"

  # Calculate final turtles version
  local final_turtles_version=""
  if [[ -n "$TURTLES_VERSION" ]]; then
    local turtles_clean="${TURTLES_VERSION#*+up}"
    turtles_clean=$(echo "$turtles_clean" | cut -d. -f1,2)
    final_turtles_version="v${turtles_clean}"
  fi

  # Calculate final fleet version
  local final_fleet_version=""
  if [[ -n "$FLEET_VERSION" ]]; then
    local fleet_clean="${FLEET_VERSION#*+up}"
    fleet_clean=$(echo "$fleet_clean" | cut -d. -f1,2)
    final_fleet_version="v${fleet_clean}"
  fi

  # Validate Turtles
  if [[ -n "$final_turtles_version" ]]; then
    echo "-> Validating Turtles version ${final_turtles_version}..."
    local turtles_url="https://github.com/rancher/turtles-product-docs/tree/main/versions/${final_turtles_version}"
    local http_status
    http_status=$(curl -s -L -o /dev/null -w "%{http_code}" "$turtles_url")

    if [[ "$http_status" != "200" ]]; then
      echo "Warning: '${final_turtles_version}' not found in Turtles docs repo. Skipping update."
      final_turtles_version=""
    else
      echo "   Confirmed '${final_turtles_version}' exists in Turtles docs repo."
    fi
  fi

  # Validate Fleet
  if [[ -n "$final_fleet_version" ]]; then
    echo "-> Validating Fleet version ${final_fleet_version}..."
    local fleet_url="https://github.com/rancher/fleet-product-docs/tree/product-docs/versions/${final_fleet_version}"
    local http_status
    http_status=$(curl -s -L -o /dev/null -w "%{http_code}" "$fleet_url")

    if [[ "$http_status" != "200" ]]; then
      echo "Warning: '${final_fleet_version}' not found in Fleet docs repo. Skipping update."
      final_fleet_version=""
    else
      echo "   Confirmed '${final_fleet_version}' exists in Fleet docs repo."
    fi
  fi

  local webhook_prime_mark
  local webhook_community_mark
  local new_current_prime_mark
  local new_current_community_mark
  [[ "${WEBHOOK_PRIME_AVAIL,,}" == "y" ]] && webhook_prime_mark="&#10003;" || webhook_prime_mark="&cross;"
  [[ "${WEBHOOK_COMMUNITY_AVAIL,,}" == "y" ]] && webhook_community_mark="&#10003;" || webhook_community_mark="&cross;"
  [[ "${NEW_CURRENT_PRIME_AVAIL,,}" == "y" ]] && new_current_prime_mark="&#10003;" || new_current_prime_mark="N/A"
  [[ "${NEW_CURRENT_COMMUNITY_AVAIL,,}" == "y" ]] && new_current_community_mark="&#10003;" || new_current_community_mark="N/A"

  # Define file paths
  local antora_file_versions="${DOCS_REPO_PATH}/versions/${minor_version_with_v}/antora.yml"
  local antora_file_community="${DOCS_REPO_PATH}/community-docs/${minor_version_with_v}/antora.yml"
  local antora_file_srfa="${DOCS_REPO_PATH}/versions/${minor_version_with_v}/antora-yml/antora-srfa.yml"

  # Define path to the modules directory where locales are stored
  local modules_path="${DOCS_REPO_PATH}/versions/${minor_version_with_v}/modules"
  # Initialize arrays to keep track of target files and available locales
  local all_files=()
  local locales=()

  # Iterate through all subdirectories in the modules folder to dynamically detect locales
  for locale_dir in "$modules_path"/*; do
    # Skip any item that is not a directory
    if [[ ! -d "$locale_dir" ]]; then continue; fi
    local locale
    # Extract the locale name (e.g., 'en', 'zh') and add it to the locales array
    locale=$(basename "$locale_dir")
    locales+=("$locale")

    # Append the file paths for the current locale to the all_files array for existence validation and revdate updates
    local base_path="${locale_dir}/pages"
    all_files+=(
      "${base_path}/release-notes.adoc"
      "${base_path}/installation-and-upgrade/hosted-kubernetes/cloud-marketplace/aws/install-adapter.adoc"
      "${base_path}/security/rancher-webhook/rancher-webhook.adoc"
      "${base_path}/faq/deprecated-features.adoc"
    )
  done

  for file in "${all_files[@]}"; do
    if [[ ! -f "$file" ]]; then
      echo "Error: File not found at '$file'. Please check DOCS_REPO_PATH and version number." >&2
      exit 1
    fi
  done

  echo "Starting release task automation for version ${VERSION}..."
  echo

  # Update revdate on all files
  for file in "${all_files[@]}"; do
    update_revdate "$file" "$iso_date"
  done

  # Update antora.yml files
  if [[ -n "$final_turtles_version" ]]; then
    if [[ -f "$antora_file_versions" ]]; then
      update_antora_attr "$antora_file_versions" "turtles-docs-version" "$final_turtles_version"
    fi
    if [[ -f "$antora_file_community" ]]; then
      update_antora_attr "$antora_file_community" "turtles-docs-version" "$final_turtles_version"
    fi
    if [[ -f "$antora_file_srfa" ]]; then
      update_antora_attr "$antora_file_srfa" "turtles-docs-version" "$final_turtles_version"
    fi
  fi

  if [[ -n "$final_fleet_version" ]]; then
    if [[ -f "$antora_file_versions" ]]; then
      update_antora_attr "$antora_file_versions" "fleet-docs-version" "$final_fleet_version"
    fi
    if [[ -f "$antora_file_community" ]]; then
      # Strip 'v' prefix for Fleet community docs
      local fleet_version_community="${final_fleet_version#v}"
      update_antora_attr "$antora_file_community" "fleet-docs-version" "$fleet_version_community"
    fi
    if [[ -f "$antora_file_srfa" ]]; then
      update_antora_attr "$antora_file_srfa" "fleet-docs-version" "$final_fleet_version"
    fi
  fi

  local current_patch_version="${VERSION#v}"
  if [[ "$NEW_CURRENT_PRIME_AVAIL" == "y" && "$NEW_CURRENT_COMMUNITY_AVAIL" == "n" ]]; then
    # Strip 'v' prefix
    if [[ -f "$antora_file_versions" ]]; then
      update_antora_attr "$antora_file_versions" "current-patch-version" "$current_patch_version"
    fi
  else
    if [[ -f "$antora_file_versions" && -f "$antora_file_community" ]]; then
      update_antora_attr "$antora_file_versions" "current-patch-version" "$current_patch_version"
      update_antora_attr "$antora_file_community" "current-patch-version" "$current_patch_version"
    fi
  fi

  local adapter_row
  adapter_row="| ${VERSION}"$'\n'"| v${ADAPTER_VERSION#v}"$'\n'

  local webhook_version_clean="${WEBHOOK_VERSION##*up}"
  webhook_version_clean="${webhook_version_clean%%-rc*}"
  local webhook_row
  webhook_row="| ${VERSION}"$'\n'"| v${webhook_version_clean}"$'\n'"| ${webhook_prime_mark}"$'\n'"| ${webhook_community_mark}"$'\n'

  local deprecated_row
  deprecated_row="| https://github.com/rancher/rancher/releases/tag/${VERSION}[${version_no_v}]"$'\n'"| ${iso_date}"$'\n'

  # Iterate through each detected locale to apply content updates
  for locale in "${locales[@]}"; do
    # Set the base pages path for the current locale
    local base_path="${modules_path}/${locale}/pages"

    # Update the specific AsciiDoc files for the current locale with the new version rows and notes
    update_release_notes "${base_path}/release-notes.adoc" "$VERSION" "$new_current_prime_mark" "$new_current_community_mark"
    update_matrix "${base_path}/installation-and-upgrade/hosted-kubernetes/cloud-marketplace/aws/install-adapter.adoc" "\/\/ DO NOT EDIT THIS LINE, REQUIRED BY RELEASE SCRIPT\." "$adapter_row"
    update_matrix "${base_path}/security/rancher-webhook/rancher-webhook.adoc" "\/\/ DO NOT EDIT THIS LINE, REQUIRED BY RELEASE SCRIPT\." "$webhook_row"
    update_matrix "${base_path}/faq/deprecated-features.adoc" "\/\/ DO NOT EDIT THIS LINE, REQUIRED BY RELEASE SCRIPT\." "$deprecated_row"
  done

  echo "✅ All tasks completed."
}

# Run the main function with all provided arguments
main "$@"
