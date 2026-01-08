#!/usr/bin/env bash
set -euo pipefail

# build_ipa.sh - helper to build/upload an App Store .ipa
# Usage:
#  export APP_STORE_CONNECT_API_KEY_PATH=/path/to/AuthKey_ABC123XYZ.json
#  export APP_STORE_CONNECT_KEY_ID=ABC123XYZ
#  export APP_STORE_CONNECT_ISSUER_ID=00000000-0000-0000-0000-000000000000
#  # then from repo root:
#  ./ios/build_ipa.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="${SCRIPT_DIR}/.."
cd "$ROOT_DIR"

echo "Running flutter pub get..."
flutter pub get

if [ -n "${APP_STORE_CONNECT_API_KEY_PATH:-}" ]; then
  echo "App Store Connect API key found; attempting Fastlane release flow"
  cd ios
  if [ -f Gemfile ]; then
    echo "Installing gems via Bundler (bundle install)..."
    bundle install
    echo "Running: bundle exec fastlane release"
    bundle exec fastlane release
  else
    if command -v fastlane >/dev/null 2>&1; then
      echo "Running: fastlane release"
      fastlane release
    else
      echo "Fastlane not found. Install Fastlane or create a Gemfile. Falling back to 'flutter build ipa'"
      cd "$ROOT_DIR"
      flutter build ipa --export-method app-store
    fi
  fi
else
  echo "No App Store Connect API key set; building .ipa with Flutter (requires local signing set in Xcode)."
  flutter build ipa --export-method app-store
fi

echo "Done."
