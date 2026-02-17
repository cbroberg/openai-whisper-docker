# Whisper Docker Transcriber

Transkribér video/audio filer med OpenAI Whisper — uden at installere noget på din Mac ud over Docker.

## Setup (én gang)

```bash
# Build image
docker compose build

# Gør scriptet executable
chmod +x whisper-transcribe.sh
```

## Brug

```bash
# Transkribér en fil (medium model, engelsk)
./whisper-transcribe.sh ~/Videos/interview.mp4

# Brug large-v3 for bedste kvalitet (kræver ~3GB RAM ekstra)
./whisper-transcribe.sh ~/Videos/interview.mp4 large-v3

# Auto-detect sprog
./whisper-transcribe.sh ~/Videos/interview.mp4 medium auto
```

## Output

Whisper genererer flere output-filer ved siden af din video:

| Fil          | Beskrivelse                        |
| ------------ | ---------------------------------- |
| `.txt`       | Ren tekst                          |
| `.srt`       | Undertekster (SubRip format)       |
| `.vtt`       | Undertekster (WebVTT format)       |
| `.json`      | Detaljeret JSON med timestamps     |
| `.tsv`       | Tab-separeret med timestamps       |

## Modeller

| Model     | Størrelse | RAM    | Kvalitet       |
| --------- | --------- | ------ | -------------- |
| `tiny`    | 39 MB     | ~1 GB  | Hurtig, lav    |
| `base`    | 74 MB     | ~1 GB  | OK             |
| `small`   | 244 MB    | ~2 GB  | God            |
| `medium`  | 769 MB    | ~5 GB  | Meget god      |
| `large-v3`| 1550 MB   | ~10 GB | Bedst          |

Modeller downloades automatisk første gang og caches i et Docker volume.

## Docker Compose (alternativ brug)

```bash
# Kør direkte via compose (mount ~/Media som default)
docker compose run --rm whisper video.mp4 --model medium --language en --output_dir /media
```
