# Whisper Docker Transcriber

Transkriber video/audio filer med OpenAI Whisper via Docker. Inkluderer AI-korrektur med udvikler-ordbog — via Ollama (lokal, gratis) eller Anthropic Haiku (cloud, ~$0.001/kald).

## Setup (en gang)

```bash
# Build Whisper Docker image
docker compose build

# Gor scripts executable
chmod +x wt.sh wt-da.sh wt-yt.sh wt-check.sh wt-check-cloud.sh
```

### AI-korrektur

Vaelg en af de to metoder:

**Ollama (lokal, gratis):**
```bash
brew install ollama
brew services start ollama
ollama pull gemma3:4b
```

**Anthropic Haiku (cloud, kræver API-noegle):**
```bash
# Opret noegle paa https://console.anthropic.com/settings/keys
echo 'ANTHROPIC_API_KEY=sk-ant-...' > .env
```

## Scripts

| Script | Formaal | AI |
| ------------------ | ---------------------------------------- | ---------------------- |
| `wt.sh` | Generel transkription (alle sprog) | — |
| `wt-da.sh` | Dansk transkription (optimeret) | — |
| `wt-yt.sh` | YouTube undertitler -> ren tekst | — |
| `wt-check.sh` | AI-korrektur via Ollama | Lokal, gratis |
| `wt-check-cloud.sh`| AI-korrektur via Anthropic Haiku | Cloud, ~$0.001/kald |

### Sammenligning af AI-korrektur

| | `wt-check.sh` (Ollama) | `wt-check-cloud.sh` (Haiku) |
|---|---|---|
| Pris | Gratis | ~$0.001/kald |
| Hastighed | ~10 sek | ~2 sek |
| Internet | Nej | Ja |
| Kvalitet | God | Lidt bedre |
| Production | Tung (RAM) | Ideel til Fly.io |

## Brug

### Dansk transkription

```bash
# Apple lydfil (.m4a) -> dansk tekst
./wt-da.sh optagelse.m4a

# Brug mindre model for hurtigere resultat
./wt-da.sh optagelse.m4a medium
```

### AI-korrektur

```bash
# Via Ollama (lokal)
./wt-check.sh optagelse.txt

# Via Anthropic Haiku (cloud)
./wt-check-cloud.sh optagelse.txt
```

### Fuld pipeline

```bash
# Transkriber + korriger (cloud)
./wt-da.sh ~/Downloads/meeting.m4a && ./wt-check-cloud.sh ~/Downloads/meeting.txt

# Transkriber + korriger (lokal)
./wt-da.sh ~/Downloads/meeting.m4a && ./wt-check.sh ~/Downloads/meeting.txt
```

### Transkription (engelsk)

```bash
./wt.sh interview.mp4
./wt.sh interview.mp4 large-v3
./wt.sh interview.mp4 medium auto
```

### YouTube undertitler

Henter auto-genererede undertitler direkte fra YouTube — ingen Whisper/Docker nødvendigt.

```bash
# Hent undertitler og gem som .txt
./wt-yt.sh https://www.youtube.com/watch?v=abc123

# Med valgfrit output-navn
./wt-yt.sh https://www.youtube.com/watch?v=abc123 mit-output-navn
```

Kræver `yt-dlp`:
```bash
brew install yt-dlp
```

**Hvornår bruge hvad:**

| Situation | Script |
|---|---|
| Lokal lydfil/video (møde, diktat) | `wt-da.sh` / `wt.sh` |
| YouTube-video med auto-captions | `wt-yt.sh` |

## Udvikler-ordbog

Filen `ordbog.txt` indeholder kendte fejlhoringer fra Whisper, saerligt engelsk udvikler-jargon brugt paa dansk:

```
mokke -> mocke (at lave mock/staffage i kode)
tekstbil -> tekstfil (en fil med tekst)
merche -> merge (at sammenflette kode)
deploye -> deploye (at udgive kode til production)
```

Begge check-scripts laeser automatisk ordbogen og sender den med til AI-modellen. Tilfoej nye ord efterhaanden som de opdages under brug.

## Output

| Fil | Beskrivelse |
| --------------- | ---------------------------------- |
| `.txt` | Ren tekst |
| `-checked.txt` | AI-korrigeret tekst |
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

### Ollama (lokal AI-korrektur)

| Model | Storrelse | Brug |
| ------------ | --------- | ---------------------- |
| `gemma3:4b` | ~3 GB | Default, god til dansk |

Ollama korer nativt paa Mac (Apple Silicon acceleration). Kan overstyre model med:
```bash
OLLAMA_MODEL=gemma3:12b ./wt-check.sh optagelse.txt
```

### Lokale stier (demo/udvikling)

Ollama gemmer modeller lokalt her:
```
~/.ollama/models/blobs/    # selve model-vaegt filerne (gemma3:4b = ~3.1 GB)
~/.ollama/models/manifests/ # model metadata
```

Whisper-modeller caches i Docker volume:
```bash
docker volume inspect whisper-models   # se hvor Docker gemmer det
```

Oprydning naar demo er faerdig:
```bash
# Slet Ollama og alle modeller (~3+ GB)
brew services stop ollama
brew uninstall ollama
rm -rf ~/.ollama

# Slet Whisper Docker image og cached modeller
docker image rm whisper-local
docker volume rm whisper-models
```

> **Note:** I production koerer dette i Docker paa Fly.io — se separat deployment-config.

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
lydfil (.m4a/.mp3/...)              YouTube URL
        |                                |
        v                                v
  [wt-da.sh / wt.sh]            [wt-yt.sh + yt-dlp]
        |                                |
        v                                |
  [Docker: whisper-local]               |
        |                                |
        v                                v
                    tekst (.txt)
                         |
                         v
  [wt-check.sh]                 <- Ollama (lokal, gratis)
  [wt-check-cloud.sh]           <- Anthropic Haiku (cloud, ~$0.001)
                         |
                         +-- ordbog.txt  <- udvikler-jargon ordbog
                         |
                         v
              korrigeret tekst (-checked.txt)
```
