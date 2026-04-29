#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
NOZZLE_DIR="$PROJECT_DIR/deps/nozzle"

if [ ! -d "$NOZZLE_DIR/.git" ]; then
    echo "Initializing nozzle submodule..."
    git submodule update --init --recursive "$NOZZLE_DIR"
else
    echo "Updating nozzle submodule..."
    git submodule update --recursive --remote "$NOZZLE_DIR"
fi

echo "Building nozzle (macOS, Release)..."
cmake -S "$NOZZLE_DIR" -B "$NOZZLE_DIR/build" \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=12.0 \
    -DNOZZLE_BUILD_TESTS=OFF \
    -DNOZZLE_BUILD_EXAMPLES=OFF \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_STANDARD=17

cmake --build "$NOZZLE_DIR/build" --config Release

NOZZLE_INCLUDE_LINK="$PROJECT_DIR/Sources/CNozzle/include/nozzle"
rm -rf "$NOZZLE_INCLUDE_LINK"
ln -sf "$NOZZLE_DIR/include/nozzle" "$NOZZLE_INCLUDE_LINK"

echo ""
echo "Build complete."
echo "  Library: $NOZZLE_DIR/build/libnozzle.a"
echo ""
echo "You can now build the Swift package:"
echo "  swift build"
echo "  swift test"
