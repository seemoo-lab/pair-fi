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

PATCH_DIRECTORY="${REPOSITORY_ROOT}/pairfi-nexmon-patch"
OUTPUT_DIRECTORY="${REPOSITORY_ROOT}/out"
DOCKERFILE="${SCRIPT_DIR}/Dockerfile"

if ! command -v docker >/dev/null 2>&1; then
    echo "Error: Docker is not installed or is not available in PATH." >&2
    exit 1
fi

if ! docker info >/dev/null 2>&1; then
    echo "Error: Docker is installed, but the Docker daemon is not running." >&2
    exit 1
fi

rm -rf "${OUTPUT_DIRECTORY}"
mkdir -p "${OUTPUT_DIRECTORY}"

docker buildx build \
    --pull \
    --platform linux/amd64 \
    --file "${DOCKERFILE}" \
    --target export \
    --output "type=local,dest=${OUTPUT_DIRECTORY}" \
    "${REPOSITORY_ROOT}"

echo
echo "Build successful:"
echo "Magisk module at ${OUTPUT_DIRECTORY}/"


