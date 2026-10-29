#!/usr/bin/env bash
# Generate the Xcode project and build a Release TermHere.app into build/.
set -euo pipefail
cd "$(dirname "$0")/.."

xcodegen generate
xcodebuild -project TermHere.xcodeproj -scheme TermHere -configuration Release \
  -derivedDataPath build/DerivedData \
  CONFIGURATION_BUILD_DIR="$PWD/build" \
  build

echo "Built: $PWD/build/TermHere.app"
