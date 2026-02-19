# Udviklingslog

## Session: 2026-02-18

### 1. Dansk transkriptions-script (`wt-da.sh`)

**Opgave:** Udvid projektet med et script der kan tage Apple lydfiler (.m4a) og lave dansk transkription.

**Resultat:**
- Oprettet `wt-da.sh` — dedikeret dansk transkription
- Default model: `large-v3` (bedst til dansk), kan overrides med `medium` for hurtigere resultat
- Output: kun `.txt` (i modsaetning til `wt.sh` der genererer alle formater)
- Printer transkriptionen direkte i terminalen
- Tilfojet `.m4a` og `.aac` til `.gitignore`

**Test:** Koert paa `/Users/cb/Downloads/intetview.m4a` (405 KB Apple memo-optagelse). `large-v3` download (2.88 GB) afbrudt — `medium` brugt i stedet. Resultat paa ~10 sek med god dansk transkription, dog med fejl som "tekstbil" og "mokke".

---

### 2. AI-korrektur via Ollama (`wt-check.sh`)

**Opgave:** Tilfoej AI-baseret korrekturlaesning af transkriptioner for at fange fejlhorte ord.

**Beslutning:** Ollama (lokal, gratis) valgt over Anthropic API for at spare omkostninger.

**Setup:**
- `brew install ollama` + `ollama pull gemma3:4b` (~3 GB model)
- Ollama koerer nativt paa Mac med Apple Silicon acceleration (bedre end Docker pga. Metal GPU)

**Resultat:**
- Oprettet `wt-check.sh` — sender transkription til Ollama for korrektur
- Gemmer resultat som `<filnavn>-checked.txt`
- Forste test fangede "mokke" og "tekstbil" men rettede kun eet ord i teksten
- Forbedret prompt til at kraeve ALLE rettelser anvendt i output — anden test OK

---

### 3. Cloud AI-korrektur via Anthropic Haiku (`wt-check-cloud.sh`)

**Opgave:** Supplement til lokal Ollama — cloud-baseret korrektur til production/Fly.io.

**Begrundelse:** Ollama er for tung til Fly.io (4-5 GB RAM, ingen GPU). Haiku koster ~$0.001 per kald og er hurtigere.

**Resultat:**
- Oprettet `wt-check-cloud.sh` — bruger Anthropic Messages API med `claude-haiku-4-5-20251001`
- Oprettet `.env` fil til API-noegle (tilfojet til `.gitignore`)
- API-noegle oprettes manuelt paa https://console.anthropic.com/settings/keys (Anthropic har ingen API til at oprette noegler programmatisk)
- Test: Haiku fangede "tekstbil" -> "tekstfil" og lod korrekt "mokke" staa (talesprog)

**Sammenligning:**

| | Ollama (lokal) | Haiku (cloud) |
|---|---|---|
| Pris | Gratis | ~$0.001/kald |
| Hastighed | ~10 sek | ~2 sek |
| Internet | Nej | Ja |
| Production | Tung | Ideel |

---

### 4. Udvikler-ordbog (`ordbog.txt`)

**Opgave:** Ordbog med dansk udvikler-jargon som Whisper fejlhoerer, saa AI-korrekturen kan slaa op.

**Baggrund:** "mokke" er et forsoeg paa det engelske "mock" som udviklere bruger. Whisper kender ikke denne Danglish-jargon.

**Resultat:**
- Oprettet `ordbog.txt` med ~65 opslag i 6 kategorier
- Begge check-scripts laeser automatisk ordbogen og sender den med i AI-prompten
- Kategorier: Git, kode, DevOps, agilt, generelle IT-udtryk, forkortelser

**Eksempler paa opslag:**
```
mokke -> mocke (at lave mock/staffage i kode)
tekstbil -> tekstfil (en fil med tekst)
kloster -> cluster (en server-klynge)
skram -> scrum (agil metode)
pipelansen -> pipelinen (CI/CD pipeline)
```

**Test:** Med ordbogen retter Haiku nu korrekt "mokke" -> "mocke" og "tekstbil" -> "tekstfil" i samme koersel.

---

### 5. README opdateringer

README opdateret loebenede med:
- Script-oversigt og sammenlignings-tabel
- Setup-instruktioner for baade Ollama og Anthropic Haiku
- Fuld pipeline-eksempler
- Dokumentation af udvikler-ordbogen
- Lokale filstier til Ollama-modeller (til oprydning efter demo)
- Arkitektur-diagram

---

## Session: 2026-02-19

### 1. Transkription af `app-ports-db.m4a`

**Opgave:** Transkriber en ny lydfil med spec for en port-management app.

**Problem:** `large-v3` crashede med exit code 137 (OOM kill) — Docker er begraenset til 7.6 GB RAM, men large-v3 kraever ~10 GB.

**Loesning:** Skiftet til `medium` model (kraever ~5 GB), som tidligere er bevist at virke godt til dansk.

**Kommando:**
```bash
./wt-da.sh app-ports-db.m4a medium
./wt-check-cloud.sh app-ports-db.txt
```

**Transkription:** Spec for en app der skal:
- Scanne `cbroberg/` og `Webhouse/` for apps og porte (via `package.json`)
- Oprette en database med GitHub-appnavne og portnumre
- Vise et Next.js interface til at rette portnumre
- Udstille et API der returnerer ledige portnumre og registrerer nye apps

**Haiku-rettelse:**
- `to vejs` -> `tovejs` (stavning)

**Konklusion:** `medium` er nu default-valg til denne pipeline pga. Docker RAM-begraensningen. `large-v3` kraever Docker Memory sat til 12+ GB i Docker Desktop Settings.

---

### Git commits (kronologisk)

| Commit | Beskrivelse |
|---|---|
| `ed582cc` | Add Danish transcription and AI correction scripts |
| `8955725` | Add local file paths and cleanup instructions to README |
| `6fa152a` | Add cloud AI correction (Haiku) and developer dictionary |
| `5aef0ce` | Expand developer dictionary to ~65 entries across 6 categories |

### Filer oprettet/aendret

| Fil | Status | Beskrivelse |
|---|---|---|
| `wt-da.sh` | Ny | Dansk transkription af lydfiler |
| `wt-check.sh` | Ny | AI-korrektur via Ollama (lokal) |
| `wt-check-cloud.sh` | Ny | AI-korrektur via Anthropic Haiku (cloud) |
| `ordbog.txt` | Ny | Udvikler-ordbog til fejlhoeringer |
| `.env` | Ny | Anthropic API-noegle (gitignored) |
| `README.md` | Opdateret | Fuld dokumentation |
| `.gitignore` | Opdateret | .m4a, .aac, .env tilfojet |

### Vaerktoejer installeret

| Vaerktoej | Metode | Storrelse |
|---|---|---|
| Ollama | `brew install ollama` | ~34 MB |
| gemma3:4b model | `ollama pull gemma3:4b` | ~3.1 GB i `~/.ollama/models/blobs/` |
