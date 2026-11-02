#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
if ! command -v swiftc >/dev/null 2>&1; then
  echo "swiftc not installed. Install Swift on Windows or use a Mac."
  exit 1
fi
find App Core Services Shared UI WidgetExtension Tests -name '*.swift' -print0 | while IFS= read -r -d '' file; do
  swiftc -frontend -parse "$file"
done
printf 'All Swift sources parsed successfully.\n'
