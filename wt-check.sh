#!/bin/bash
# wt-check.sh — AI-korrektur af Whisper-transkriptioner via Ollama (lokal, gratis)
# Usage: ./wt-check.sh <tekstfil>
#
# Examples:
#   ./wt-check.sh optagelse.txt
#   ./wt-check.sh /Users/cb/Downloads/interview.txt
#
# Kræver: Ollama installeret med gemma3:4b model
#   brew install ollama && brew services start ollama && ollama pull gemma3:4b

set -e

MODEL="${OLLAMA_MODEL:-gemma3:4b}"

if [ -z "$1" ]; then
  echo "Usage: ./wt-check.sh <tekstfil>"
  echo ""
  echo "Kører AI-korrektur på en Whisper-transkription via Ollama (lokal, gratis)."
  echo "Gemmer korrigeret tekst som <filnavn>-checked.txt"
  echo ""
  echo "Kræver: ollama med gemma3:4b model"
  echo "  brew install ollama && brew services start ollama && ollama pull gemma3:4b"
  exit 1
fi

TXTFILE="$1"

if [ ! -f "$TXTFILE" ]; then
  echo "Fil ikke fundet: $TXTFILE"
  exit 1
fi

# Check Ollama is running
if ! curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
  echo "Ollama kører ikke. Start den med: brew services start ollama"
  exit 1
fi

CONTENT="$(cat "$TXTFILE")"
DIR="$(dirname "$TXTFILE")"
BASENAME="$(basename "$TXTFILE" .txt)"
OUTFILE="$DIR/$BASENAME-checked.txt"

echo "Korrekturlæser: $TXTFILE"
echo "Model: $MODEL"
echo ""

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
- Hvis intet skal rettes, skriv \"Ingen rettelser nødvendige\"

TEKST:
$CONTENT"

RESPONSE=$(curl -s http://localhost:11434/api/generate \
  -d "$(jq -n --arg model "$MODEL" --arg prompt "$PROMPT" '{
    model: $model,
    prompt: $prompt,
    stream: false,
    options: { temperature: 0.3 }
  }')")

RESULT=$(echo "$RESPONSE" | jq -r '.response // "Fejl: Intet svar fra Ollama"')

echo "$RESULT"
echo ""
echo "---"
echo "$RESULT" > "$OUTFILE"
echo "Resultat gemt: $OUTFILE"
