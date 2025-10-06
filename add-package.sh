#!/bin/bash
# Script to add a .deb package to the APT repository

set -e

if [ $# -lt 1 ]; then
    echo "Usage: $0 <package.deb>"
    exit 1
fi

DEB_FILE="$1"

if [ ! -f "$DEB_FILE" ]; then
    echo "Error: File $DEB_FILE not found"
    exit 1
fi

# Get package name
PKG_NAME=$(dpkg-deb -f "$DEB_FILE" Package)

echo "Adding package: $PKG_NAME"

# Copy to pool
mkdir -p "pool/main/${PKG_NAME}"
cp "$DEB_FILE" "pool/main/${PKG_NAME}/"

# Generate Packages file
dpkg-scanpackages -m pool > dists/bookworm/main/binary-arm64/Packages
gzip -k -f dists/bookworm/main/binary-arm64/Packages

# Generate Release file
cat > dists/bookworm/Release <<EOF
Origin: Astroberry64
Label: Astroberry64
Suite: bookworm
Codename: bookworm
Architectures: arm64
Components: main
Description: APT repository for Astroberry64 packages
Date: $(date -Ru)
EOF

# Calculate checksums
cd dists/bookworm
echo "MD5Sum:" >> Release
find main -type f | while read f; do
    echo " $(md5sum "$f" | cut -d' ' -f1) $(stat -c%s "$f") $f" >> Release
done

echo "SHA256:" >> Release
find main -type f | while read f; do
    echo " $(sha256sum "$f" | cut -d' ' -f1) $(stat -c%s "$f") $f" >> Release
done

cd ../..

echo "Package added successfully!"
echo "Don't forget to commit and push changes to GitHub."
