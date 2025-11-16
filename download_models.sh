#!/bin/bash
set -e

echo "🤖 Bytebot LLMGateway - Download modelli locali"
echo "==============================================="
echo ""

# Installazione Python packages senza venv
python3 -m pip install --upgrade huggingface_hub tqdm

MODEL_DIR="./models"
mkdir -p "$MODEL_DIR"

download() {
    local REPO=$1
    local FILE=$2
    local DESC=$3

    echo "📥 $DESC"
    echo "   Repo: $REPO"
    echo "   File: $FILE"

    if [ -f "$MODEL_DIR/$FILE" ]; then
        echo "   ✅ Già presente, salto"
        return
    fi

    echo "   ⏳ Download..."
    python3 - <<EOF
from huggingface_hub import hf_hub_download
hf_hub_download(
    repo_id="$REPO",
    filename="$FILE",
    local_dir="$MODEL_DIR",
    local_dir_use_symlinks=False,
    resume_download=True
)
EOF
    echo "   ✅ Completato!"
}

# Lista modelli consigliati
download "bartowski/Phi-3.1-mini-4k-instruct-GGUF" "Phi-3.1-mini-4k-instruct-Q4_K_M.gguf" "🔹 Phi-3.1 Mini 3.8B"
download "TheBloke/MPT-7B-Instruct-GGUF"           "mpt-7b-instruct.Q4_K_M.gguf"            "🔹 MPT-7B-Instruct"
download "TheBloke/Falcon-7B-Instruct-GGUF"        "falcon-7b-instruct.Q4_K_M.gguf"         "🔹 Falcon-7B-Instruct"

echo ""
echo "✅ Download modelli completato!"
echo "📁 Salvati in: $MODEL_DIR"

