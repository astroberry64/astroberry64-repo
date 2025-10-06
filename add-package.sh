#!/bin/bash
# Script to add a .deb package to the APT repository

set -e

if [ $# -lt 1 ]; then
    echo "Usage: $0 <package.deb> [suite]"
    echo "  suite: stable or testing (default: stable)"
    exit 1
fi

DEB_FILE="$1"
SUITE_TYPE="${2:-stable}"

if [[ "$SUITE_TYPE" != "stable" && "$SUITE_TYPE" != "testing" ]]; then
    echo "Error: Suite must be 'stable' or 'testing'"
    exit 1
fi

# Map to bookworm-stable or bookworm-testing
SUITE="bookworm-${SUITE_TYPE}"

if [ ! -f "$DEB_FILE" ]; then
    echo "Error: File $DEB_FILE not found"
    exit 1
fi

# Get package name
PKG_NAME=$(dpkg-deb -f "$DEB_FILE" Package)

echo "Adding package: $PKG_NAME to $SUITE"

# Copy to pool (shared between all suites)
mkdir -p "pool/main/${PKG_NAME}"
DEB_BASENAME=$(basename "$DEB_FILE")
POOL_FILE="pool/main/${PKG_NAME}/${DEB_BASENAME}"
if [ "$DEB_FILE" != "$POOL_FILE" ]; then
    cp "$DEB_FILE" "pool/main/${PKG_NAME}/"
fi

# Generate Packages file
dpkg-scanpackages -m pool > dists/${SUITE}/main/binary-arm64/Packages
gzip -k -f dists/${SUITE}/main/binary-arm64/Packages

# Generate Release file
cat > dists/${SUITE}/Release <<EOF
Origin: Astroberry64
Label: Astroberry64
Suite: ${SUITE}
Codename: ${SUITE}
Architectures: arm64
Components: main
Description: APT repository for Astroberry64 packages (${SUITE_TYPE})
Date: $(date -Ru)
EOF

# Calculate checksums
cd dists/${SUITE}
echo "MD5Sum:" >> Release
find main -type f | while read f; do
    echo " $(md5sum "$f" | cut -d' ' -f1) $(stat -c%s "$f") $f" >> Release
done

echo "SHA256:" >> Release
find main -type f | while read f; do
    echo " $(sha256sum "$f" | cut -d' ' -f1) $(stat -c%s "$f") $f" >> Release
done

cd ../..

echo "Package added successfully to $SUITE!"
echo "Don't forget to commit and push changes to GitHub."
