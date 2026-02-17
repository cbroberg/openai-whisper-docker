FROM python:3.11-slim

# Install system dependencies for ffmpeg and whisper
RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install OpenAI Whisper
RUN pip install --no-cache-dir openai-whisper

# Create working directory for media files
WORKDIR /media

# Default command: show help
ENTRYPOINT ["whisper"]
CMD ["--help"]
