#!/bin/bash
# cleanup-old-packages.sh - Remove old package versions from pool/
# Keeps N latest versions per package, removes older ones

set -e

cd "$(dirname "$0")"

# Configuration
KEEP_VERSIONS="${KEEP_VERSIONS:-3}"  # Keep latest 3 versions by default
DRY_RUN="${DRY_RUN:-1}"              # Default to dry-run mode

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "=== APT Repository Cleanup ==="
echo "Configuration:"
echo "  Keep versions: $KEEP_VERSIONS (per package)"
echo "  Dry-run mode: $([ $DRY_RUN -eq 1 ] && echo 'YES (no files will be deleted)' || echo 'NO (files will be DELETED)')"
echo ""

# Find all source packages
declare -A SOURCE_PACKAGES

for deb in pool/main/*/*/*.deb; do
    [ -f "$deb" ] || continue

    # Extract metadata
    PKG_NAME=$(dpkg-deb -f "$deb" Package)
    SOURCE_PKG=$(dpkg-deb -f "$deb" Source)
    VERSION=$(dpkg-deb -f "$deb" Version)

    # If no Source field, use package name
    if [ -z "$SOURCE_PKG" ]; then
        SOURCE_PKG="$PKG_NAME"
    else
        # Source field can be "source-pkg (version)", extract just name
        SOURCE_PKG=$(echo "$SOURCE_PKG" | awk '{print $1}')
    fi

    # Store: SOURCE_PACKAGES[source_pkg|binary_pkg]="version1:path1,version2:path2,..."
    KEY="${SOURCE_PKG}|${PKG_NAME}"
    if [ -z "${SOURCE_PACKAGES[$KEY]}" ]; then
        SOURCE_PACKAGES[$KEY]="${VERSION}:${deb}"
    else
        SOURCE_PACKAGES[$KEY]="${SOURCE_PACKAGES[$KEY]},${VERSION}:${deb}"
    fi
done

# Analyze each package
TOTAL_TO_DELETE=0
TOTAL_SIZE_SAVED=0
declare -a FILES_TO_DELETE

for KEY in "${!SOURCE_PACKAGES[@]}"; do
    SOURCE_PKG="${KEY%|*}"
    BINARY_PKG="${KEY#*|}"

    # Parse versions and paths
    IFS=',' read -ra VERSIONS <<< "${SOURCE_PACKAGES[$KEY]}"

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
            # dpkg --compare-versions returns 0 if true, 1 if false
            # Temporarily disable set -e for the comparison
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

    # Determine what to keep vs delete
    KEEP_COUNT=0
    DELETE_COUNT=0

    echo -e "${BLUE}Package: ${SOURCE_PKG} / ${BINARY_PKG}${NC}"

    for ITEM in "${SORTED_VERSIONS[@]}"; do
        VERSION="${ITEM%%:*}"
        FILE_PATH="${ITEM#*:}"
        SIZE=$(stat -c%s "$FILE_PATH" 2>/dev/null || echo 0)
        SIZE_MB=$(awk "BEGIN {printf \"%.2f\", $SIZE/1048576}")

        if [ $KEEP_COUNT -lt $KEEP_VERSIONS ]; then
            echo -e "  ${GREEN}✓ KEEP${NC}   $VERSION  ($SIZE_MB MB)  $FILE_PATH"
            KEEP_COUNT=$((KEEP_COUNT + 1))
        else
            echo -e "  ${RED}✗ DELETE${NC} $VERSION  ($SIZE_MB MB)  $FILE_PATH"
            FILES_TO_DELETE+=("$FILE_PATH")
            DELETE_COUNT=$((DELETE_COUNT + 1))
            TOTAL_TO_DELETE=$((TOTAL_TO_DELETE + 1))
            TOTAL_SIZE_SAVED=$((TOTAL_SIZE_SAVED + SIZE))
        fi
    done

    echo ""
done

# Summary
TOTAL_SIZE_SAVED_MB=$(awk "BEGIN {printf \"%.2f\", $TOTAL_SIZE_SAVED/1048576}")
echo "========================================="
echo -e "${YELLOW}Summary:${NC}"
echo "  Total files to delete: $TOTAL_TO_DELETE"
echo "  Total space to save: ${TOTAL_SIZE_SAVED_MB} MB"
echo ""

if [ ${#FILES_TO_DELETE[@]} -eq 0 ]; then
    echo -e "${GREEN}✓ No files to delete. Repository is clean!${NC}"
    exit 0
fi

# Execute deletion if not dry-run
if [ $DRY_RUN -eq 0 ]; then
    echo -e "${RED}EXECUTING DELETION...${NC}"

    for FILE in "${FILES_TO_DELETE[@]}"; do
        echo "  Deleting: $FILE"
        git rm "$FILE"
    done

    # Clean up empty directories
    find pool/main -type d -empty -delete 2>/dev/null || true

    echo ""
    echo -e "${GREEN}✓ Deletion complete!${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Regenerate repository metadata: ./regenerate-repo.sh"
    echo "  2. Review changes: git status"
    echo "  3. Commit: git commit -m 'Clean up old package versions'"
    echo "  4. Push: git push origin main"
else
    echo -e "${YELLOW}DRY-RUN MODE: No files were deleted.${NC}"
    echo ""
    echo "To execute deletion, run:"
    echo "  DRY_RUN=0 KEEP_VERSIONS=$KEEP_VERSIONS ./cleanup-old-packages.sh"
fi
