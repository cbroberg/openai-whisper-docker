#!/bin/bash
# whisper-transcribe.sh
# Usage: ./whisper-transcribe.sh <video-file> [model] [language]
#
# Examples:
#   ./whisper-transcribe.sh video.mp4
#   ./whisper-transcribe.sh video.mp4 large-v3
#   ./whisper-transcribe.sh video.mp4 medium en
#
# Output files (.txt, .srt, .vtt, .json) are saved next to the input file.

set -e

if [ -z "$1" ]; then
  echo "Usage: ./whisper-transcribe.sh <video-file> [model] [language]"
  echo ""
  echo "Models (smallest → largest, better quality):"
  echo "  tiny, base, small, medium, large-v3"
  echo ""
  echo "Default: medium model, auto-detect language"
  exit 1
fi

FILE="$1"
MODEL="${2:-medium}"
LANG="${3:-en}"

# Resolve absolute path of the input file
FULL_PATH="$(cd "$(dirname "$FILE")" 2>/dev/null && pwd)/$(basename "$FILE")"
DIR="$(dirname "$FULL_PATH")"
FILENAME="$(basename "$FULL_PATH")"

# Verify file exists before running Docker
if [ ! -f "$FULL_PATH" ]; then
  echo "❌ File not found: $FULL_PATH"
  exit 1
fi

echo "🎙️  Transcribing: $FILENAME"
echo "📦  Model: $MODEL"
echo "🌍  Language: $LANG"
echo "📂  Output dir: $DIR"
echo ""

docker run --rm \
  -v "$DIR:/media" \
  -v whisper-models:/root/.cache/whisper \
  whisper-local \
  "/media/$FILENAME" \
  --model "$MODEL" \
  --language "$LANG" \
  --output_dir /media \
  --output_format all

if [ $? -ne 0 ]; then
  echo ""
  echo "❌ Transcription failed!"
  exit 1
fi

echo ""
echo "✅ Done! Output files are in: $DIR"
