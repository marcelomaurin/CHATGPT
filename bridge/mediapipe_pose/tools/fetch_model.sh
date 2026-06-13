#!/bin/bash
# Bash script to download MediaPipe Pose Landmarker models.
# Usage: ./fetch_model.sh

set -e

declare -A MODELS
MODELS["pose_landmarker_lite.task"]="https://storage.googleapis.com/mediapipe-models/pose_landmarker/pose_landmarker_lite/float16/1/pose_landmarker_lite.task"
MODELS["pose_landmarker_full.task"]="https://storage.googleapis.com/mediapipe-models/pose_landmarker/pose_landmarker_full/float16/1/pose_landmarker_full.task"
MODELS["pose_landmarker_heavy.task"]="https://storage.googleapis.com/mediapipe-models/pose_landmarker/pose_landmarker_heavy/float16/1/pose_landmarker_heavy.task"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"
ROOT_PROJECT_DIR="$(dirname "$BASE_DIR")"

DEST_PLATFORMS=("windows-x86_64" "linux-x86_64")
VERSION_DIR="mp_0_10_35"

echo "Starting MediaPipe model downloader..."

for PLATFORM in "${DEST_PLATFORMS[@]}"; do
    MODELS_DIR="$ROOT_PROJECT_DIR/runtime/mediapipe/pose/$VERSION_DIR/$PLATFORM/models"
    if [ ! -d "$MODELS_DIR" ]; then
        mkdir -p "$MODELS_DIR"
        echo "Created target folder: $MODELS_DIR"
    fi

    for MODEL_NAME in "${!MODELS[@]}"; do
        URL="${MODELS[$MODEL_NAME]}"
        OUT_PATH="$MODELS_DIR/$MODEL_NAME"

        if [ -f "$OUT_PATH" ]; then
            echo "Model $MODEL_NAME already exists at $OUT_PATH. Skipping."
            continue
        fi

        echo "Downloading $MODEL_NAME from $URL..."
        if command -v curl >/dev/null 2>&1; then
            curl -L -o "$OUT_PATH" "$URL"
        else
            wget -O "$OUT_PATH" "$URL"
        fi

        echo "Computing SHA256..."
        if command -v sha256sum >/dev/null 2>&1; then
            sha256sum "$OUT_PATH"
        else
            shasum -a 256 "$OUT_PATH"
        fi
    done
done

echo "All downloads completed successfully."
