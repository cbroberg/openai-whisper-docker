#!/bin/bash
# wt-yt.sh — Hent YouTube undertitler og gem som ren tekst
# Usage: ./wt-yt.sh <youtube-url> [output-navn]
#
# Examples:
#   ./wt-yt.sh https://www.youtube.com/watch?v=abc123
#   ./wt-yt.sh https://www.youtube.com/watch?v=abc123 min-video
#
# Output: <output-navn>.txt i nuværende mappe

set -e

if [ -z "$1" ]; then
  echo "Usage: ./wt-yt.sh <youtube-url> [output-navn]"
  exit 1
fi

URL="$1"
DIR="$(pwd)"
TMPDIR=$(mktemp -d)

# Hent video-titel som fallback navn
TITLE=$(yt-dlp --print title "$URL" 2>/dev/null | tr ' ' '-' | tr -cd '[:alnum:]-_' | cut -c1-60)
OUTNAME="${2:-$TITLE}"
OUTFILE="$DIR/$OUTNAME.txt"

echo "Henter undertitler: $OUTNAME"
echo "URL: $URL"
echo ""

# Download auto-genererede engelske undertitler (ingen video)
yt-dlp \
  --skip-download \
  --write-auto-sub \
  --sub-lang en \
  --sub-format vtt \
  --output "$TMPDIR/sub" \
  "$URL" 2>&1 | grep -v "^\[debug\]"

VTTFILE=$(find "$TMPDIR" -name "*.vtt" | head -1)

if [ -z "$VTTFILE" ]; then
  echo "Ingen undertitler fundet!"
  rm -rf "$TMPDIR"
  exit 1
fi

# Rens VTT til ren tekst: fjern headers, tidskoder og duplikerede linjer
python3 - "$VTTFILE" "$OUTFILE" <<'PYEOF'
import sys, re

with open(sys.argv[1], 'r', encoding='utf-8') as f:
    content = f.read()

# Fjern WEBVTT header og tidskodelinjer
lines = content.split('\n')
text_lines = []
for line in lines:
    line = line.strip()
    if not line:
        continue
    if line.startswith('WEBVTT') or line.startswith('Kind:') or line.startswith('Language:'):
        continue
    if re.match(r'^\d{2}:\d{2}', line):  # tidskode
        continue
    if re.match(r'^\d+$', line):  # sekvensnummer
        continue
    # Fjern VTT-tags som <00:00:01.000><c> osv.
    line = re.sub(r'<[^>]+>', '', line)
    line = line.strip()
    if line:
        text_lines.append(line)

# Fjern duplikerede på hinanden følgende linjer (YouTube gentager linjer i VTT)
deduped = []
for line in text_lines:
    if not deduped or line != deduped[-1]:
        deduped.append(line)

result = ' '.join(deduped)
# Sæt linjeskift ved sætningsafslutninger for læsbarhed
result = re.sub(r'([.!?])\s+', r'\1\n', result)

with open(sys.argv[2], 'w', encoding='utf-8') as f:
    f.write(result.strip() + '\n')

print(f"Linjer i output: {len(result.splitlines())}")
PYEOF

rm -rf "$TMPDIR"

echo ""
echo "Undertitler gemt: $OUTFILE"
echo ""
cat "$OUTFILE"
