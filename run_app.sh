#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT_DIR"

SDK_PATH=""
for candidate in \
  "/Library/Developer/CommandLineTools/SDKs/MacOSX15.5.sdk" \
  "/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk" \
  "/Library/Developer/CommandLineTools/SDKs/MacOSX15.2.sdk" \
  "/Library/Developer/CommandLineTools/SDKs/MacOSX15.sdk" \
  "/Library/Developer/CommandLineTools/SDKs/MacOSX14.5.sdk" \
  "/Library/Developer/CommandLineTools/SDKs/MacOSX14.sdk" \
  "/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk"
do
  if [[ -d "$candidate" ]]; then
    SDK_PATH="$candidate"
    break
  fi
done

if [[ -z "$SDK_PATH" ]]; then
  echo "No usable macOS SDK found in CommandLineTools." >&2
  exit 1
fi

mkdir -p build
swiftc \
  -sdk "$SDK_PATH" \
  -parse-as-library \
  Sources/*.swift \
  -o build/InternTracker \
  -framework SwiftUI \
  -framework AppKit

./build/InternTracker
