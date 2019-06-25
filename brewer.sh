#!/usr/bin/env bash
# Fail if any commands fails
set -e
# Debug log
set -x

BOTTLE_FILENAME=$PACKAGE_NAME-$PACKAGE_VERSION.mojave.tar.xz

# Check if the bottle is already available and exit if found
BOTTLE_URL=https://dl.bintray.com/swiftbrew/bottles/$BOTTLE_FILENAME
STATUS_CODE=$(curl \
  --silent \
  --fail \
  --output /dev/null \
  --write-out "%{http_code}" \
  "$BOTTLE_URL" || true)

if [ "${STATUS_CODE}" == 200 ]; then
  echo "Bottle already exists."
  exit 0
fi

# Create a new package
curl -XPOST \
  --user swiftbrew:"$BINTRAY_API_KEY" \
  --header 'Content-Type: application/json' \
  --data '{"name": "'"$PACKAGE_NAME"'", "licenses": ["MIT"], "vcs_url": "'"$PACKAGE_GIT_URL"'"}' \
  "https://api.bintray.com/packages/swiftbrew/bottles"

# Install mint
HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_INSTALL_CLEANUP=1 brew install mint

# Use mint to build the package
mint install "$PACKAGE_GIT_URL@$PACKAGE_VERSION"

cd /usr/local/lib/mint/packages/

# Make a tarball
tar cJf "$BOTTLE_FILENAME" "$PACKAGE_NAME/build/$PACKAGE_VERSION"

# Upload bottle
curl \
  --silent \
  --fail \
  --user swiftbrew:"$BINTRAY_API_KEY" \
  --upload-file "$BOTTLE_FILENAME" \
  "https://api.bintray.com/content/swiftbrew/bottles/$PACKAGE_NAME/$PACKAGE_VERSION/$BOTTLE_FILENAME?publish=1"
