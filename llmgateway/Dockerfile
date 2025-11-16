# Dockerfile LLMGateway custom
FROM ghcr.io/theopenco/llmgateway-unified:latest

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        python3-venv \
        python3-pip \
        curl \
        ca-certificates \
        libgl1 \
        libglib2.0-0 \
        build-essential && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Crea virtualenv
RUN python3 -m venv /app/venv

# Installa pacchetti nel virtualenv
RUN /app/venv/bin/pip install --upgrade pip && \
    /app/venv/bin/pip install huggingface_hub tqdm

COPY config.yaml .
COPY download_models.sh /app/download_models.sh
RUN chmod +x /app/download_models.sh

EXPOSE 7000

CMD ["/app/venv/bin/python", "llm_gateway.py", "--config", "config.yaml", "--cpu"]
