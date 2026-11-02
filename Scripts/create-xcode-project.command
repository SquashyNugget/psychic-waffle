#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "== Badminton Court Manager =="
if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "Open BadmintonCourtManager.xcodeproj on an Apple Mac with Xcode."
    exit 1
fi
if [[ ! -d BadmintonCourtManager.xcodeproj ]]; then
    echo "Regenerating the bundled Xcode project..."
    if command -v python3 >/dev/null 2>&1; then
        python3 Scripts/generate_xcodeproj.py
    elif command -v xcodegen >/dev/null 2>&1; then
        xcodegen generate --spec project.yml
    else
        echo "Install Python 3 or XcodeGen to regenerate the project."
        exit 1
    fi
fi
echo "Opening project in Xcode..."
open BadmintonCourtManager.xcodeproj
