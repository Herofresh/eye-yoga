#!/usr/bin/env bash
# Builds the app, zips it, tags v$(cat VERSION) and publishes a GitHub release.
set -euo pipefail

cd "$(dirname "$0")/.."
version="$(cat VERSION)"
tag="v$version"
zip="build/EyeYoga-$version.zip"

[ -z "$(git status --porcelain)" ] || { echo "Working tree not clean" >&2; exit 1; }
git rev-parse "$tag" >/dev/null 2>&1 && { echo "$tag already exists; bump VERSION" >&2; exit 1; }

swift test
scripts/build-app.sh
rm -f "$zip"
# ditto keeps the bundle's code signature intact, unlike plain zip.
ditto -c -k --keepParent build/EyeYoga.app "$zip"

git tag -a "$tag" -m "Eye Yoga $version"
git push origin "$tag"
gh release create "$tag" "$zip" --repo Herofresh/eye-yoga --title "Eye Yoga $version" --notes-file RELEASE_NOTES.md
