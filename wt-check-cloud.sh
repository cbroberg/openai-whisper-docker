#!/bin/bash
# wt-check-cloud.sh — AI-korrektur af Whisper-transkriptioner via Anthropic Haiku
# Usage: ./wt-check-cloud.sh <tekstfil>
#
# Examples:
#   ./wt-check-cloud.sh optagelse.txt
#   ./wt-check-cloud.sh /Users/cb/Downloads/interview.txt
#
# Kræver: ANTHROPIC_API_KEY i .env fil eller som environment variable

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ -z "$1" ]; then
  echo "Usage: ./wt-check-cloud.sh <tekstfil>"
  echo ""
  echo "Kører AI-korrektur på en Whisper-transkription via Anthropic Haiku."
  echo "Gemmer korrigeret tekst som <filnavn>-checked.txt"
  echo ""
  echo "Kræver: ANTHROPIC_API_KEY i .env eller environment"
  exit 1
fi

TXTFILE="$1"

if [ ! -f "$TXTFILE" ]; then
  echo "Fil ikke fundet: $TXTFILE"
  exit 1
fi

# Load API key from .env if not already set
if [ -z "$ANTHROPIC_API_KEY" ]; then
  if [ -f "$SCRIPT_DIR/.env" ]; then
    export $(grep -v '^#' "$SCRIPT_DIR/.env" | xargs)
  fi
fi

if [ -z "$ANTHROPIC_API_KEY" ] || [ "$ANTHROPIC_API_KEY" = "din-noegle-her" ]; then
  echo "ANTHROPIC_API_KEY mangler. Sæt den i .env filen:"
  echo "  echo 'ANTHROPIC_API_KEY=sk-ant-...' > $SCRIPT_DIR/.env"
  exit 1
fi

CONTENT="$(cat "$TXTFILE")"
DIR="$(dirname "$TXTFILE")"
BASENAME="$(basename "$TXTFILE" .txt)"
OUTFILE="$DIR/$BASENAME-checked.txt"

# Load developer dictionary if it exists
ORDBOG=""
if [ -f "$SCRIPT_DIR/ordbog.txt" ]; then
  ORDBOG=$(grep -v '^#' "$SCRIPT_DIR/ordbog.txt" | grep -v '^$')
fi

echo "Korrekturlæser: $TXTFILE"
echo "Model: claude-haiku-4-5-20251001"
if [ -n "$ORDBOG" ]; then
  echo "Ordbog: ordbog.txt"
fi
echo ""

DICT_SECTION=""
if [ -n "$ORDBOG" ]; then
  DICT_SECTION="
UDVIKLER-ORDBOG (brug denne til at rette kendte fejl):
$ORDBOG
"
fi

PROMPT="Du er en dansk korrekturlæser af Whisper tale-til-tekst transkriptioner.

Du skal svare i PRÆCIS dette format og intet andet:

KORRIGERET TEKST:
(den fulde tekst med ALLE rettelser anvendt)

ÆNDRINGER:
- \"forkert ord\" -> \"korrekt ord\" (begrundelse)

REGLER:
- Anvend ALLE rettelser i den korrigerede tekst - ingen fejl må stå urettet
- Ret kun ord der tydeligt er fejltransskriberet (lyder ens men forkert ord, f.eks. \"tekstbil\" -> \"tekstfil\")
- Bevar talesprog, slang og uformelt sprog
- Ændr IKKE sætningsstruktur eller tegnsætning
- Brug UDVIKLER-ORDBOGEN nedenfor til at genkende og rette kendte fejlhøringer
- Hvis intet skal rettes, skriv \"Ingen rettelser nødvendige\"
$DICT_SECTION
TEKST:
$CONTENT"

RESPONSE=$(curl -s https://api.anthropic.com/v1/messages \
  -H "content-type: application/json" \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -d "$(jq -n --arg prompt "$PROMPT" '{
    model: "claude-haiku-4-5-20251001",
    max_tokens: 2048,
    messages: [{ role: "user", content: $prompt }]
  }')")

# Check for API errors
ERROR=$(echo "$RESPONSE" | jq -r '.error.message // empty')
if [ -n "$ERROR" ]; then
  echo "API fejl: $ERROR"
  exit 1
fi

RESULT=$(echo "$RESPONSE" | jq -r '.content[0].text // "Fejl: Intet svar fra API"')

echo "$RESULT"
echo ""
echo "---"
echo "$RESULT" > "$OUTFILE"
echo "Resultat gemt: $OUTFILE"
