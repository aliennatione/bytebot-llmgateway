#!/bin/bash
set -e

ENV_FILE=".env"
MODELS_DIR="./models"

echo "==============================="
echo "  Bytebot - Selettore Modelli"
echo "==============================="
echo ""

# Controllo cartella modelli
if [ ! -d "$MODELS_DIR" ]; then
    echo "❌ La cartella $MODELS_DIR non esiste!"
    exit 1
fi

# Trova file .gguf
models=( "$MODELS_DIR"/*.gguf )

if [ ${#models[@]} -eq 0 ]; then
    echo "❌ Nessun modello trovato in $MODELS_DIR"
    exit 1
fi

echo "📁 Modelli trovati:"
echo ""

# Mostra lista numerata
for i in "${!models[@]}"; do
    echo "  $((i+1))) $(basename "${models[$i]}")"
done

echo ""
read -p "👉 Seleziona il numero del modello: " choice
echo ""

if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt ${#models[@]} ]; then
    echo "❌ Scelta non valida."
    exit 1
fi

index=$((choice - 1))
selected=$(basename "${models[$index]}")

echo "🔧 Modello selezionato: $selected"
echo ""

# Backup .env
if [ -f "$ENV_FILE" ]; then
    cp "$ENV_FILE" "${ENV_FILE}.backup"
    echo "📦 Backup creato: ${ENV_FILE}.backup"
fi

# Aggiorna LOCAL_MODEL_PATH
if grep -q "^LOCAL_MODEL_PATH=" "$ENV_FILE"; then
    sed -i "s|^LOCAL_MODEL_PATH=.*|LOCAL_MODEL_PATH=/models/$selected|" "$ENV_FILE"
else
    echo "LOCAL_MODEL_PATH=/models/$selected" >> "$ENV_FILE"
fi

echo "✅ .env aggiornato con:"
echo "   LOCAL_MODEL_PATH=/models/$selected"
echo ""
echo "🚀 Ora puoi avviare Bytebot:"
echo "   podman compose -f compose.yml up -d"
echo ""
