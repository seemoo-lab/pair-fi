#!/usr/bin/env sh

set -eu

SCRIPT_DIR="$(
    CDPATH= cd -- "$(dirname -- "$0")" &&
    pwd
)"

REPOSITORY_ROOT="$(
    CDPATH= cd -- "${SCRIPT_DIR}/.." &&
    pwd
)"

APP_DIRECTORY="${REPOSITORY_ROOT}/app"
OUTPUT_DIRECTORY="${REPOSITORY_ROOT}/dist"
DOCKERFILE="${SCRIPT_DIR}/Dockerfile"

if ! command -v docker >/dev/null 2>&1; then
    echo "Error: Docker is not installed or is not available in PATH." >&2
    exit 1
fi

if ! docker info >/dev/null 2>&1; then
    echo "Error: Docker is installed, but the Docker daemon is not running." >&2
    exit 1
fi

if [ ! -f "${APP_DIRECTORY}/pubspec.yaml" ]; then
    echo "Error: Flutter project not found." >&2
    echo "Expected: ${APP_DIRECTORY}/pubspec.yaml" >&2
    exit 1
fi

if [ ! -d "${APP_DIRECTORY}/android" ]; then
    echo "Error: Android project directory not found." >&2
    echo "Expected: ${APP_DIRECTORY}/android" >&2
    exit 1
fi

rm -rf "${OUTPUT_DIRECTORY}"
mkdir -p "${OUTPUT_DIRECTORY}"

docker buildx build \
    --platform linux/amd64 \
    --file "${DOCKERFILE}" \
    --target release-apks \
    --output "type=local,dest=${OUTPUT_DIRECTORY}" \
    "${REPOSITORY_ROOT}"

echo
echo "Build successful:"
echo "Apk at ${OUTPUT_DIRECTORY}/"
