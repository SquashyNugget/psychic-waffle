#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "This script must be run on macOS with Xcode installed."
    exit 1
fi
if ! command -v xcodebuild >/dev/null 2>&1; then
    echo "Xcode is required. Install it and run xcode-select to select Xcode."
    exit 1
fi
if [[ ! -d BadmintonCourtManager.xcodeproj ]]; then
    if ! command -v xcodegen >/dev/null 2>&1; then
        echo "First run Scripts/create-xcode-project.command"
        exit 1
    fi
    xcodegen generate --spec project.yml
fi

echo "Building unsigned Release IPA for SideStore's on-device signing..."
# An unsigned IPA is NOT an installable signed app by itself. SideStore must
# sign *both* main app and extension, which may or may not allow Live Activities.
xcodebuild \
    -project BadmintonCourtManager.xcodeproj \
    -scheme BadmintonCourtManager \
    -configuration Release \
    -sdk iphoneos \
    -destination 'generic/platform=iOS' \
    -derivedDataPath "$PWD/.build/DerivedData" \
    CODE_SIGNING_ALLOWED=NO \
    build

app="$PWD/.build/DerivedData/Build/Products/Release-iphoneos/BadmintonCourtManager.app"
if [[ ! -d "$app" ]]; then
    echo "Expected app bundle not found: $app"
    exit 1
fi
mkdir -p "$PWD/Output"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/Payload"
ditto "$app" "$tmp/Payload/BadmintonCourtManager.app"
(cd "$tmp" && zip -qry -X "$OLDPWD/Output/BadmintonCourtManager-UNSIGNED.ipa" Payload)

echo ""
echo "Unsigned IPA created: Output/BadmintonCourtManager-UNSIGNED.ipa"
echo "SideStore must re-sign the app AND embedded Live Activity extension."
echo "If SideStore cannot sign the extension, use Xcode > Run for a personal test."
