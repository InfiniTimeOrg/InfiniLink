#!/bin/sh
set -e

echo "GITHUB_CLIENT_SECRET = $GITHUB_CLIENT_SECRET" > "$CI_PRIMARY_REPOSITORY_PATH/InfiniLink/Secrets.xcconfig"
