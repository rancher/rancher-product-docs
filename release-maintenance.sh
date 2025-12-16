#!/bin/bash
#
# A script to automate release maintenance for Rancher docs.
#
# This script updates multiple AsciiDoc files with new version information.
# It supports two modes:
#   1. Interactive: Prompts the user for all necessary information.
#   2. Non-interactive: Takes all information as command-line arguments.
#
# It also includes a dry-run mode to show what commands would be executed
# without making any actual changes to the files.

set -o errexit
set -o nounset
set -o pipefail

# --- Configuration ---
# Base path to the documentation repository.
# The script assumes it is located in the root of the docs repository.
# It determines its own location to make the path portable.
DOCS_REPO_PATH=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# --- Global Variables ---
INTERACTIVE=false
DRY_RUN=false
VERSION=""
TAG_VERSION=""
RELEASE_DATE=""
ADAPTER_VERSION=""
WEBHOOK_VERSION=""
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
    $ ./$(basename "$0")

  Non-interactive:
    Provide a git tag to derive the version and fetch component versions automatically.
    $ ./$(basename "$0") -t v2.13.2 -d "Dec 09, 2025"

    Or, provide the version and component versions manually:
    $ ./$(basename "$0") -v v2.13.2 -d "Dec 09, 2025" -a v107.0.1+up8.0.0 -w v0.9.2

Options:
  -v <version>          The new Rancher version (e.g., v2.13.2). (Required if -t is not used)
  -d <date>             The release date (e.g., "Dec 09, 2025"). (Required)
  -t <tag>              A git tag from rancher/rancher repository (e.g., v2.13.1-alpha4).
                        If used, the version is derived from the tag, and -a and -w are fetched from GitHub.
  -a <adapter_version>  The corresponding CSP adapter version. (Required if -t is not used)
  -w <webhook_version>  The corresponding webhook version. (Required if -t is not used)

  --prime [y/n]         Is this version available in Prime? (Default: y)
  --community [y/n]     Is this version available in Community? (Default: y)
  -n, --dry-run         Show what changes would be made without modifying files.
  -h, --help            Display this help message and exit.
EOF
  exit 1
}

# Prompt user for inputs in interactive mode.
get_inputs_interactive() {
  echo "Running in interactive mode. Please provide the release details."
  read -rp "Enter a git tag (e.g., v2.13.1-alpha4), or leave blank to enter version manually: " TAG_VERSION
  read -rp "Enter the release date (e.g., Dec 09, 2025): " RELEASE_DATE

  if [[ -n "$TAG_VERSION" ]]; then
    VERSION=${TAG_VERSION%%-*}
    echo "  -> Derived version: ${VERSION}"
  else
    read -rp "Enter the new Rancher version (e.g., v2.13.2): " VERSION
    read -rp "Enter the CSP adapter version: " ADAPTER_VERSION
    read -rp "Enter the webhook version: " WEBHOOK_VERSION
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
      --prime) NEW_CURRENT_PRIME_AVAIL="$2"; shift 2 ;;
      --community) NEW_CURRENT_COMMUNITY_AVAIL="$2"; shift 2 ;;
      -n|--dry-run) DRY_RUN=true; shift 1 ;;
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
  fi

  if ! "$valid"; then
    echo
    usage
  fi
}

# Execute a command or print it for a dry run.
run_cmd() {
  if "$DRY_RUN"; then
    echo "DRY-RUN: Would execute..."
    # Pretty-print the ex command for readability
    echo "ex -s \"$1\" <<-EOF"
    echo -e "$2" | sed 's/^/  /'
    echo "EOF"
    echo
  else
    ex -s "$1" <<< "$2"
  fi
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
| xref:release-notes/${version}.adoc[View] / https://github.com/rancher/rancher/releases/tag/${version}[GitHub Release]
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
    WEBHOOK_VERSION=$(echo "$build_yaml_content" | grep '^webhookVersion:' | awk '{print $2}')
    ADAPTER_VERSION=$(echo "$build_yaml_content" | grep '^cspAdapterMinVersion:' | awk '{print $2}')

    if [[ -z "$WEBHOOK_VERSION" ]] || [[ -z "$ADAPTER_VERSION" ]]; then
        echo "Error: Could not parse webhookVersion or cspAdapterMinVersion from build.yaml" >&2
        exit 1
    fi
    echo "  - Found Webhook Version: ${WEBHOOK_VERSION}"
    echo "  - Found Adapter Version: ${ADAPTER_VERSION}"
  fi

  # Prepare variables
  local iso_date
  iso_date=$(date -d "$RELEASE_DATE" "+%Y-%m-%d")
  local version_no_v="${VERSION#v}"
  local minor_version_no_v
  minor_version_no_v=$(echo "$version_no_v" | cut -d. -f1,2)
  local minor_version_with_v="v${minor_version_no_v}"

  local webhook_prime_mark
  local webhook_community_mark
  local new_current_prime_mark
  local new_current_community_mark
  [[ "${WEBHOOK_PRIME_AVAIL,,}" == "y" ]] && webhook_prime_mark="&#10003;" || webhook_prime_mark="&cross;"
  [[ "${WEBHOOK_COMMUNITY_AVAIL,,}" == "y" ]] && webhook_community_mark="&#10003;" || webhook_community_mark="&cross;"
  [[ "${NEW_CURRENT_PRIME_AVAIL,,}" == "y" ]] && new_current_prime_mark="&#10003;" || new_current_prime_mark="N/A"
  [[ "${NEW_CURRENT_COMMUNITY_AVAIL,,}" == "y" ]] && new_current_community_mark="&#10003;" || new_current_community_mark="N/A"

  # Define file paths
  local base_path_en="${DOCS_REPO_PATH}/versions/${minor_version_with_v}/modules/en/pages"
  local release_notes_file_en="${base_path_en}/release-notes.adoc"
  local adapter_file_en="${base_path_en}/installation-and-upgrade/hosted-kubernetes/cloud-marketplace/aws/install-adapter.adoc"
  local webhook_file_en="${base_path_en}/security/rancher-webhook/rancher-webhook.adoc"
  local deprecated_file_en="${base_path_en}/faq/deprecated-features.adoc"

  # Define file paths for Chinese by replacing the language code in the path
  local release_notes_file_zh="${release_notes_file_en/en\/pages/zh\/pages}"
  local adapter_file_zh="${adapter_file_en/en\/pages/zh\/pages}"
  local webhook_file_zh="${webhook_file_en/en\/pages/zh\/pages}"
  local deprecated_file_zh="${deprecated_file_en/en\/pages/zh\/pages}"
  
  local all_files=(
    "$release_notes_file_en" "$adapter_file_en" "$webhook_file_en" "$deprecated_file_en"
    "$release_notes_file_zh" "$adapter_file_zh" "$webhook_file_zh" "$deprecated_file_zh"
  )
  for file in "${all_files[@]}"; do
    if [[ ! -f "$file" ]]; then
      echo "Error: File not found at '$file'. Please check DOCS_REPO_PATH and version number." >&2
      exit 1
    fi
  done

  echo "Starting release task automation for version ${VERSION}..."
  if "$DRY_RUN"; then
    echo "--- DRY RUN MODE: No files will be modified. ---"
  fi
  echo

  # Update revdate on all files
  for file in "${all_files[@]}"; do
    update_revdate "$file" "$iso_date"
  done

  # Update release-notes.adoc
  update_release_notes "$release_notes_file_en" "$VERSION" "$new_current_prime_mark" "$new_current_community_mark"
  update_release_notes "$release_notes_file_zh" "$VERSION" "$new_current_prime_mark" "$new_current_community_mark"

  # Update install-adapter.adoc
  local adapter_row
  adapter_row="| ${VERSION}"$'\n'"| v${ADAPTER_VERSION#v}"$'\n'
  update_matrix "$adapter_file_en" "\/\/ DO NOT EDIT THIS LINE, REQUIRED BY RELEASE SCRIPT\." "$adapter_row"
  update_matrix "$adapter_file_zh" "\/\/ DO NOT EDIT THIS LINE, REQUIRED BY RELEASE SCRIPT\." "$adapter_row"

  # Update rancher-webhook.adoc
  local webhook_row
  webhook_row="| ${VERSION}"$'\n'"| v${WEBHOOK_VERSION##*up}"$'\n'"| ${webhook_prime_mark}"$'\n'"| ${webhook_community_mark}"$'\n'
  # The marker is different here, it's a comment
  update_matrix "$webhook_file_en" "\/\/ DO NOT EDIT THIS LINE, REQUIRED BY RELEASE SCRIPT\." "$webhook_row"
  update_matrix "$webhook_file_zh" "\/\/ DO NOT EDIT THIS LINE, REQUIRED BY RELEASE SCRIPT\." "$webhook_row"

  # Update deprecated-features.adoc
  local deprecated_row_en
  deprecated_row_en="| https://github.com/rancher/rancher/releases/tag/${VERSION}[${version_no_v}]"$'\n'"| ${RELEASE_DATE}"$'\n'
  update_matrix "$deprecated_file_en" "\/\/ DO NOT EDIT THIS LINE, REQUIRED BY RELEASE SCRIPT\." "$deprecated_row_en"

  # Chinese version has a different date format
  local release_date_zh
  release_date_zh=$(date -d "$RELEASE_DATE" "+%Y 年 %-m 月 %-d 日")
  local deprecated_row_zh="| https://github.com/rancher/rancher/releases/tag/${VERSION}[${version_no_v}]"$'\n'"| ${release_date_zh}"$'\n'
  update_matrix "$deprecated_file_zh" "\/\/ DO NOT EDIT THIS LINE, REQUIRED BY RELEASE SCRIPT\." "$deprecated_row_zh"

  echo "✅ All tasks completed."
  if "$DRY_RUN"; then
    echo "--- DRY RUN FINISHED ---"
  fi
}

# Run the main function with all provided arguments
main "$@"
