#!/bin/bash
# migrate-pool-layout.sh - Reorganize pool to Debian-standard layout
# Uses git mv to preserve history

set -e

cd "$(dirname "$0")"

echo "=== Migrating pool/ to Debian-standard layout ==="
echo ""

# Find all .deb files in current pool structure
find pool/main -name "*.deb" -type f | sort | while read DEB_FILE; do
    echo "Processing: $DEB_FILE"

    # Extract package metadata
    PKG_NAME=$(dpkg-deb -f "$DEB_FILE" Package)
    SOURCE_PKG=$(dpkg-deb -f "$DEB_FILE" Source)

    # If no Source field, source package name = binary package name
    if [ -z "$SOURCE_PKG" ]; then
        SOURCE_PKG="$PKG_NAME"
    else
        # Source field can be "source-pkg (version)", extract just the name
        SOURCE_PKG=$(echo "$SOURCE_PKG" | awk '{print $1}')
    fi

    # Calculate Debian-style pool prefix
    if [[ $SOURCE_PKG == lib* ]]; then
        # lib packages: use "lib" + first letter after "lib"
        PREFIX="lib${SOURCE_PKG:3:1}"
    else
        # Other packages: just first letter
        PREFIX="${SOURCE_PKG:0:1}"
    fi

    # Calculate new location
    NEW_DIR="pool/main/${PREFIX}/${SOURCE_PKG}"
    DEB_BASENAME=$(basename "$DEB_FILE")
    NEW_PATH="${NEW_DIR}/${DEB_BASENAME}"

    # Check if already in correct location
    if [ "$DEB_FILE" = "$NEW_PATH" ]; then
        echo "  ✓ Already in correct location: $NEW_PATH"
        continue
    fi

    # Create destination directory
    mkdir -p "$NEW_DIR"

    # Move using git mv
    echo "  → Moving to: $NEW_PATH"
    git mv "$DEB_FILE" "$NEW_PATH"

    echo ""
done

echo "=== Cleaning up empty directories ==="
# Remove empty directories (bottom-up)
find pool/main -type d -empty -delete 2>/dev/null || true

echo ""
echo "=== Migration complete! ==="
echo ""
echo "Next steps:"
echo "1. Regenerate Packages and Release files for both suites"
echo "2. Review changes with: git status"
echo "3. Commit changes with descriptive message"
