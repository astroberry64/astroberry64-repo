#!/bin/bash
# regenerate-repo.sh - Regenerate Packages and Release files for all suites
# Run this after migrating pool/ structure

set -e

cd "$(dirname "$0")"

SUITES=("trixie-stable" "trixie-testing")

for SUITE in "${SUITES[@]}"; do
    echo "=== Regenerating $SUITE ==="

    # Ensure directory structure exists
    mkdir -p "dists/${SUITE}/main/binary-arm64"

    # Generate Packages file
    echo "  Generating Packages file..."
    dpkg-scanpackages -m pool > "dists/${SUITE}/main/binary-arm64/Packages"
    gzip -k -f "dists/${SUITE}/main/binary-arm64/Packages"

    # Generate Release file
    echo "  Generating Release file..."
    SUITE_TYPE="${SUITE#trixie-}"  # Extract "stable" or "testing"
    cat > "dists/${SUITE}/Release" <<EOF
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
    cd "dists/${SUITE}"
    echo "MD5Sum:" >> Release
    find main -type f | while read f; do
        echo " $(md5sum "$f" | cut -d' ' -f1) $(stat -c%s "$f") $f" >> Release
    done

    echo "SHA256:" >> Release
    find main -type f | while read f; do
        echo " $(sha256sum "$f" | cut -d' ' -f1) $(stat -c%s "$f") $f" >> Release
    done

    cd ../..
    echo "  ✓ $SUITE complete"
    echo ""
done

echo "=== Repository metadata regenerated successfully! ==="
echo ""
echo "Verify with:"
echo "  apt-cache policy astroberry64-server-wui (should see new packages)"
