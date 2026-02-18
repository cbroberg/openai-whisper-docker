# Whisper Docker Transcriber

Transkribér video/audio filer med OpenAI Whisper — uden at installere noget på din Mac ud over Docker. Inkluderer AI-korrektur via Ollama (lokal, gratis).

## Setup (en gang)

```bash
# Build Whisper Docker image
docker compose build

# Gor scripts executable
chmod +x wt.sh wt-da.sh wt-check.sh
```

### AI-korrektur (valgfrit)

```bash
# Installer Ollama (lokal AI — gratis, ingen API-nogle)
brew install ollama
brew services start ollama
ollama pull gemma3:4b
```

## Scripts

| Script | Formaal |
| ------------ | -------------------------------------------- |
| `wt.sh` | Generel transkription (alle sprog) |
| `wt-da.sh` | Dansk transkription (optimeret) |
| `wt-check.sh`| AI-korrektur af transkription via Ollama |

## Brug

### Transkription (engelsk)

```bash
./wt.sh interview.mp4
./wt.sh interview.mp4 large-v3
./wt.sh interview.mp4 medium auto
```

### Dansk transkription

```bash
# Apple lydfil (.m4a) -> dansk tekst
./wt-da.sh optagelse.m4a

# Brug mindre model for hurtigere resultat
./wt-da.sh optagelse.m4a medium
```

### AI-korrektur

```bash
# Korrekturlaes transkription (retter fejlhorte ord)
./wt-check.sh optagelse.txt
```

Gemmer korrigeret tekst som `optagelse-checked.txt` med en liste over rettelser.

### Fuld pipeline: optag -> transkriber -> korriger

```bash
./wt-da.sh ~/Downloads/meeting.m4a && ./wt-check.sh ~/Downloads/meeting.txt
```

## Output

| Fil | Beskrivelse |
| ------------ | ---------------------------------- |
| `.txt` | Ren tekst |
| `-checked.txt` | AI-korrigeret tekst (fra wt-check) |
| `.srt` | Undertekster (SubRip format) |
| `.vtt` | Undertekster (WebVTT format) |
| `.json` | Detaljeret JSON med timestamps |
| `.tsv` | Tab-separeret med timestamps |

`wt-da.sh` genererer kun `.txt`. `wt.sh` genererer alle formater.

## Modeller

### Whisper (transkription)

| Model | Storrelse | RAM | Kvalitet |
| --------- | --------- | ------ | -------------- |
| `tiny` | 39 MB | ~1 GB | Hurtig, lav |
| `base` | 74 MB | ~1 GB | OK |
| `small` | 244 MB | ~2 GB | God |
| `medium` | 769 MB | ~5 GB | Meget god |
| `large-v3`| 1550 MB | ~10 GB | Bedst |

Whisper-modeller downloades automatisk og caches i et Docker volume.

### Ollama (AI-korrektur)

| Model | Storrelse | Brug |
| ------------ | --------- | ---------------------- |
| `gemma3:4b` | ~3 GB | Default, god til dansk |

Ollama korer nativt paa Mac (Apple Silicon acceleration). Kan overstyre model med:
```bash
OLLAMA_MODEL=gemma3:12b ./wt-check.sh optagelse.txt
```

## Understottede formater

Alle formater som ffmpeg understotter, herunder:
`.m4a`, `.mp3`, `.wav`, `.mp4`, `.mov`, `.flac`, `.ogg`, `.webm`, `.mkv`, `.avi`

## Docker

Containeren korer **ikke** i baggrunden — den starter, transkriberer, og stopper automatisk.

```bash
# Build image (kun forste gang eller efter aendringer i Dockerfile)
docker compose build

# Se om imaget findes
docker image ls whisper-local

# Fjern imaget helt (hvis du vil frigore plads)
docker image rm whisper-local

# Fjern cached modeller (frigor op til ~10 GB)
docker volume rm whisper-models
```

## Arkitektur

```
lydfil (.m4a/.mp3/...)
        |
        v
  [wt-da.sh / wt.sh]       <- bash script
        |
        v
  [Docker: whisper-local]   <- OpenAI Whisper i Docker container
        |
        v
    tekst (.txt)
        |
        v
  [wt-check.sh]             <- bash script
        |
        v
  [Ollama: gemma3:4b]       <- lokal AI paa Mac (Metal GPU)
        |
        v
  korrigeret tekst (-checked.txt)
```
