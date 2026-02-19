#!/bin/bash
# wt-da.sh — Dansk transkription af lydfiler (m4a, mp3, wav, etc.)
# Usage: ./wt-da.sh <lydfil> [model]
#
# Examples:
#   ./wt-da.sh optagelse.m4a
#   ./wt-da.sh optagelse.m4a large-v3
#   ./wt-da.sh memo.mp3 small
#
# Output: En .txt fil med dansk tekst, placeret ved siden af lydfilen.

set -e

if [ -z "$1" ]; then
  echo "Usage: ./wt-da.sh <lydfil> [model]"
  echo ""
  echo "Transkriberer lydfiler til dansk tekst via Whisper i Docker."
  echo ""
  echo "Understøttede formater: .m4a, .mp3, .wav, .mp4, .mov, .flac, .ogg, .webm"
  echo ""
  echo "Modeller (mindste → største, bedre kvalitet):"
  echo "  tiny, base, small, medium, large-v3"
  echo ""
  echo "Default: large-v3 (bedst til dansk)"
  exit 1
fi

FILE="$1"
MODEL="${2:-medium}"

# Resolve absolute path
FULL_PATH="$(cd "$(dirname "$FILE")" 2>/dev/null && pwd)/$(basename "$FILE")"
DIR="$(dirname "$FULL_PATH")"
FILENAME="$(basename "$FULL_PATH")"
BASENAME="${FILENAME%.*}"

if [ ! -f "$FULL_PATH" ]; then
  echo "Fil ikke fundet: $FULL_PATH"
  exit 1
fi

echo "Transkriberer: $FILENAME"
echo "Model: $MODEL"
echo "Sprog: dansk"
echo "Output: $DIR/$BASENAME.txt"
echo ""

docker run --rm \
  -v "$DIR:/media" \
  -v whisper-models:/root/.cache/whisper \
  whisper-local \
  "/media/$FILENAME" \
  --model "$MODEL" \
  --language da \
  --output_dir /media \
  --output_format txt

if [ $? -ne 0 ]; then
  echo ""
  echo "Transkription fejlede!"
  exit 1
fi

echo ""
echo "Dansk transkription gemt: $DIR/$BASENAME.txt"
echo ""
cat "$DIR/$BASENAME.txt"
