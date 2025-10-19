#!/bin/bash
# list-packages.sh - Show package versions in the repository
# Usage: ./list-packages.sh [--all] [suite]
#   --all: Show all versions, not just latest
#   suite: testing, stable, or both (default: both)

set -e

cd "$(dirname "$0")"

# Parse arguments
SHOW_ALL=0
SUITE="both"

while [[ $# -gt 0 ]]; do
    case $1 in
        --all)
            SHOW_ALL=1
            shift
            ;;
        testing|stable|both)
            SUITE=$1
            shift
            ;;
        *)
            echo "Usage: $0 [--all] [testing|stable|both]"
            echo "  --all: Show all versions (default: latest only)"
            echo "  suite: testing, stable, or both (default: both)"
            exit 1
            ;;
    esac
done

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo "=== Astroberry64 Repository Packages ==="
echo ""

# Find all packages and group by source package
declare -A PACKAGE_VERSIONS

for deb in pool/main/*/*/*.deb; do
    [ -f "$deb" ] || continue

    # Extract metadata
    PKG_NAME=$(dpkg-deb -f "$deb" Package)
    VERSION=$(dpkg-deb -f "$deb" Version)
    ARCH=$(dpkg-deb -f "$deb" Architecture)

    # Store: PACKAGE_VERSIONS[package_name]="version1:arch1,version2:arch2,..."
    KEY="$PKG_NAME"
    if [ -z "${PACKAGE_VERSIONS[$KEY]}" ]; then
        PACKAGE_VERSIONS[$KEY]="${VERSION}:${ARCH}"
    else
        PACKAGE_VERSIONS[$KEY]="${PACKAGE_VERSIONS[$KEY]},${VERSION}:${ARCH}"
    fi
done

# Sort package names alphabetically
SORTED_PACKAGES=($(for key in "${!PACKAGE_VERSIONS[@]}"; do echo "$key"; done | sort))

# Display packages
for PKG_NAME in "${SORTED_PACKAGES[@]}"; do
    # Parse versions and architectures
    IFS=',' read -ra VERSIONS <<< "${PACKAGE_VERSIONS[$PKG_NAME]}"

    # Sort versions (newest first) using dpkg --compare-versions
    SORTED_VERSIONS=()
    for ITEM in "${VERSIONS[@]}"; do
        SORTED_VERSIONS+=("$ITEM")
    done

    # Bubble sort by version (newest first)
    for ((i=0; i<${#SORTED_VERSIONS[@]}; i++)); do
        for ((j=i+1; j<${#SORTED_VERSIONS[@]}; j++)); do
            VER1="${SORTED_VERSIONS[$i]%%:*}"
            VER2="${SORTED_VERSIONS[$j]%%:*}"
            set +e
            dpkg --compare-versions "$VER1" lt "$VER2"
            RESULT=$?
            set -e
            if [ $RESULT -eq 0 ]; then
                # Swap
                TEMP="${SORTED_VERSIONS[$i]}"
                SORTED_VERSIONS[$i]="${SORTED_VERSIONS[$j]}"
                SORTED_VERSIONS[$j]="$TEMP"
            fi
        done
    done

    # Determine which suites this package is in
    SUITES=""
    if grep -q "^Package: $PKG_NAME\$" dists/trixie-testing/main/binary-*/Packages 2>/dev/null; then
        SUITES="${SUITES}testing "
    fi
    if grep -q "^Package: $PKG_NAME\$" dists/trixie-stable/main/binary-*/Packages 2>/dev/null; then
        SUITES="${SUITES}stable "
    fi

    # Filter by requested suite
    if [ "$SUITE" = "testing" ] && [[ ! "$SUITES" =~ testing ]]; then
        continue
    fi
    if [ "$SUITE" = "stable" ] && [[ ! "$SUITES" =~ stable ]]; then
        continue
    fi

    # Display package name
    echo -e "${BLUE}$PKG_NAME${NC} ${CYAN}[$SUITES]${NC}"

    if [ $SHOW_ALL -eq 1 ]; then
        # Show all versions
        for ITEM in "${SORTED_VERSIONS[@]}"; do
            VERSION="${ITEM%%:*}"
            ARCH="${ITEM#*:}"
            echo -e "  ${GREEN}$VERSION${NC} ($ARCH)"
        done
    else
        # Show latest version only
        LATEST="${SORTED_VERSIONS[0]}"
        VERSION="${LATEST%%:*}"
        ARCH="${LATEST#*:}"
        echo -e "  ${GREEN}$VERSION${NC} ($ARCH)"
    fi
    echo ""
done

# Summary
PACKAGE_COUNT=${#SORTED_PACKAGES[@]}
echo "========================================="
echo -e "${YELLOW}Total packages: $PACKAGE_COUNT${NC}"
echo ""
echo "Usage:"
echo "  ./list-packages.sh          # Show latest versions (both suites)"
echo "  ./list-packages.sh --all    # Show all versions"
echo "  ./list-packages.sh testing  # Show only testing suite packages"
echo "  ./list-packages.sh stable   # Show only stable suite packages"
