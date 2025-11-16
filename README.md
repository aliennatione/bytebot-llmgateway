# Bytebot — LLMGateway Integration

## 🔹 Introduzione

Questo progetto integra **LLMGateway** con **Bytebot**, permettendo a Bytebot di utilizzare modelli LLM locali (GGUF) e provider remoti come Hugging Face o OpenRouter.  
Bytebot diventa così un **agent AI desktop self-hosted**, capace di:

- Automatizzare attività su desktop Linux containerizzato
- Usare modelli locali potenti senza dipendere esclusivamente da API cloud
- Effettuare fallback verso modelli remoti se necessario

---

## 🌳 Struttura della repository

```

bytebot-llmgateway/
├── llmgateway/
│   ├── config.yaml          # Configurazione server LLMGateway
│   └── Dockerfile           # Dockerfile custom LLMGateway
├── .env.example              # Esempio di variabili d'ambiente
├── compose.yml               # File principale Podman / Docker Compose
├── docker-compose.yml        # Variante alternativa Compose
├── download_models.sh        # Script per scaricare modelli GGUF
├── select_model.sh           # Script per selezionare il modello locale
├── README_compose.md         # Documentazione legacy / aggiuntiva
└── README.md                  # Questo README principale

````

---

## 🔍 Cos’è Bytebot + LLMGateway

### Bytebot
Bytebot è un **agent AI desktop containerizzato** che può:

- Digitare, cliccare, navigare e interagire con applicazioni
- Automatizzare flussi complessi come un umano
- Esporre API per task management e interfaccia web UI

### LLMGateway
LLMGateway è un **server ponte** tra modelli locali (GGUF / LLaMA.cpp) e provider remoti (Hugging Face, OpenRouter).  
Permette a Bytebot di:

- Usare modelli locali con fallback automatico verso modelli remoti
- Controllare parametri di modello (threads, contesto, GPU)
- Cache delle risposte e rate-limiting

**Vantaggi dell’integrazione:**

- Privacy e sicurezza → self-hosted
- Risparmio sui costi delle API
- Controllo completo sui modelli
- Flessibilità di cambiare modello locale o provider remoto facilmente

---

## 🔧 Guida di configurazione

### 1. Clona il progetto
```bash
git clone <URL_DEL_REPO> bytebot-llmgateway
cd bytebot-llmgateway
````

### 2. Prepara il file `.env`

```bash
cp .env.example .env
```

Aggiorna i valori:

* `HF_API_KEY` e `HF_MODEL` → Hugging Face
* `OPENROUTER_API_KEY` e `OPENROUTER_MODEL` → OpenRouter
* `LOCAL_MODEL_PATH` → percorso modello GGUF locale
* Altri valori: database, URL dei servizi Bytebot

### 3. Scarica modelli locali

```bash
chmod +x download_models.sh
./download_models.sh
```

I modelli saranno salvati in `./models`.

### 4. Seleziona il modello locale

```bash
chmod +x select_model.sh
./select_model.sh
```

Lo script aggiorna automaticamente `LOCAL_MODEL_PATH` in `.env`.

### 5. Avvia i container

```bash
podman compose -f compose.yml up -d
# oppure con Docker
docker-compose -f docker-compose.yml up -d
```

**Container attivi:**

* Bytebot Desktop
* LLMGateway
* Bytebot Agent
* PostgreSQL (DB)

### 6. Verifica funzionamento

* LLMGateway: `http://localhost:7000/health`
* UI Bytebot: `http://localhost:9992` (o porta configurata)

---

## ⚙️ Configurazione LLMGateway (`llmgateway/config.yaml`)

Esempio:

```yaml
server:
  host: 0.0.0.0
  port: 7000
  log_level: info

providers:
  - name: local
    type: llama.cpp
    model_path: ${LOCAL_MODEL_PATH}
    enabled: true
    params:
      n_ctx: 4096
      n_threads: 4
      n_gpu_layers: 0
      f16_kv: true
      use_mlock: true

  - name: hf
    type: huggingface
    api_key: ${HF_API_KEY}
    model: ${HF_MODEL}
    enabled: true

  - name: openrouter
    type: openrouter
    api_key: ${OPENROUTER_API_KEY}
    model: ${OPENROUTER_MODEL}
    enabled: true

auto_pick:
  enabled: true
  priority: [local, hf, openrouter]
  timeout_ms: 30000
  max_retries: 2

cache:
  enabled: true
  max_size: 1000
  ttl_seconds: 3600

rate_limit:
  enabled: true
  requests_per_minute: 60
```

**Significato:**

* `providers`: tutti i provider da usare
* `auto_pick`: seleziona automaticamente il provider secondo la priorità
* `cache`: memorizza risposte ripetute
* `rate_limit`: limita richieste per protezione risorse

---

## 🔐 Gestione più provider remoti

* Definisci più provider nella sezione `providers`
* Imposta chiavi API nel `.env`
* Ordina la priorità in `auto_pick.priority` (es. `[local, openrouter, hf]`)
* Regola `timeout_ms` per fallback rapido o lento
* Per disabilitare il fallback: `auto_pick.enabled: false` e usa esplicitamente `provider: local` o `provider: hf`

---

## 🧪 Architettura e flusso dati

```
+----------------+        +-------------------+        +----------------------+
| Bytebot Agent  | -----> | LLMGateway Server | -----> | Modello Locale GGUF  |
| (task / API)   |        | (Local + Remote)  |        | (LLaMA.cpp / GGUF)   |
+----------------+        +-------------------+        +----------------------+
         |                          |
         |                          v
         |                    +----------------------+
         |                    | Provider Remoti      |
         |                    | HuggingFace / OpenR  |
         |                    +----------------------+
         |
         v
   +----------------+
   | PostgreSQL DB  |
   +----------------+
```

**Flusso operativo:**

1. Bytebot invia richiesta LLM a LLMGateway
2. LLMGateway valuta i provider secondo priorità
3. Risultato memorizzato in cache se abilitato
4. Rate limiting protegge risorse locali o remote

---

## 🧰 Comandi utili

| Comando                               | Descrizione                                                          |
| ------------------------------------- | -------------------------------------------------------------------- |
| `./download_models.sh`                | Scarica modelli GGUF definiti nello script nella cartella `./models` |
| `./select_model.sh`                   | Mostra e seleziona modelli `.gguf`, aggiorna `.env`                  |
| `podman compose -f compose.yml up -d` | Avvia container Bytebot, LLMGateway e DB                             |
| `podman compose -f compose.yml down`  | Ferma e rimuove container                                            |
| `podman logs llmgateway`              | Mostra log di LLMGateway per debug e diagnostica                     |

---

## 📌 Scenari d’uso

* **Automazione desktop intelligente**: Bytebot esegue task complessi usando il modello locale
* **Privacy first**: dati sensibili restano in locale
* **Riduzione costi**: evita chiamate API continue
* **Fallback intelligente**: se locale non sufficiente, usa provider remoto
* **Ambiente di sviluppo/test**: test di modelli remoti o locali senza cambiare codice

---

## 🔒 Best practices

* Esegui su macchine o VM sicure
* Proteggi le chiavi API (`.env`)
* Monitora utilizzo API per evitare costi imprevisti
* Assicurati di avere RAM sufficiente per modelli GGUF grandi

---

## Ottimizzazioni per la produzione

### `.dockerignore` ottimizzato produzione

```dockerignore
# File di sistema
*.swp
*.swo
*.DS_Store
Thumbs.db
.idea/
.vscode/

# Configurazioni locali / segreti
.env
.env.local
.env.*.backup

# Modelli GGUF: li monteremo via volume
models/

# Database locali
*.db
*.sqlite
data/

# Cache / file temporanei
__pycache__/
*.pyc
*.pyo
*.pyd
*.egg-info/
*.pytest_cache/
*.mypy_cache/
*.coverage
.cache/
.tmp/

# Documentazione locale
*.md.bak

# Docker / Compose locali
docker-compose.override.yml
compose.override.yml

# File di archivio e backup
*.zip
*.tar.gz
*.bak
```

---

### Suggerimenti per Dockerfile leggero

1. **Usare immagini base minime**

   ```dockerfile
   FROM python:3.12-slim
   ```
2. **Installare solo dipendenze necessarie**

   ```dockerfile
   RUN pip install --no-cache-dir -r requirements.txt
   ```
3. **Montare modelli via volume invece di copiarli**

   ```yaml
   volumes:
     - ./models:/app/models
   ```
4. **Non includere `.env` nel container**, passarlo come variabile d’ambiente in `docker-compose.yml` o runtime.

---

### O ancora...

Ecco un esempio di **`docker-compose.yml` pronto per produzione** per la tua app, con montaggio dei modelli, gestione sicura delle variabili d’ambiente e immagini leggere:


##@# `docker-compose.yml` esempio

```yaml
version: "3.9"

services:
  app:
    image: my-llm-app:latest  # oppure build: ./ se vuoi costruirlo localmente
    build:
      context: .
      dockerfile: Dockerfile
    container_name: llm_app
    restart: unless-stopped
    environment:
      - APP_ENV=production
      - API_KEY=${API_KEY}      # variabile d'ambiente locale
      - MODEL_PATH=/app/models  # path dentro il container
    volumes:
      - ./models:/app/models   # monta i modelli senza copiarli nell'immagine
    ports:
      - "8000:8000"            # esponi la porta della tua app
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
```

---

##### Come usarlo

1. Metti i modelli nella cartella `./models` **locale**.
2. Crea un file `.env` (che non va nel repo) con le variabili sensibili:

   ```
   API_KEY=la_tua_chiave
   ```
3. Avvia l’app:

   ```bash
   docker compose up -d --build
   ```
4. L’app sarà accessibile su `http://localhost:8000` (o altra porta se modificata).

---

#### `Dockerfile`

```dockerfile
# Immagine base leggera
FROM python:3.12-slim

# Setta la cartella di lavoro
WORKDIR /app

# Copia solo i file necessari per le dipendenze
COPY pyproject.toml poetry.lock* /app/

# Installa pip e Poetry senza cache
RUN pip install --no-cache-dir poetry \
    && poetry config virtualenvs.create false \
    && poetry install --no-dev --no-interaction --no-ansi

# Copia il codice dell'app
COPY . /app

# Espone la porta dell'app FastAPI
EXPOSE 8000

# Variabile d'ambiente per i modelli
ENV MODEL_PATH=/app/models

# Comando per avviare Uvicorn in modalità produzione
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "2", "--log-level", "info"]
```

---

##### Spiegazioni delle scelte

1. **Uvicorn con workers**: `--workers 2` permette di gestire più richieste in parallelo senza bisogno di Gunicorn (leggero e semplice).
2. **`log-level info`**: log leggibili senza spam da debug.
3. **FastAPI app**: assume che il tuo file principale sia `main.py` con `app = FastAPI()`.
4. **MODEL_PATH**: variabile d’ambiente per puntare ai modelli, così non li inserisci nell’immagine.

---


#### `Dockerfile` multi-stage

Oppure una versione multi-stage build ottimizzata per ridurre drasticamente la dimensione dell’immagine Docker:

```dockerfile
# --------------------------
# Stage 1: Build
# --------------------------
FROM python:3.12-slim AS builder

WORKDIR /app

# Copia i file di dipendenze
COPY pyproject.toml poetry.lock* /app/

# Installa Poetry e le dipendenze
RUN pip install --no-cache-dir poetry \
    && poetry config virtualenvs.create false \
    && poetry install --no-dev --no-interaction --no-ansi

# Copia il codice sorgente
COPY . /app

# --------------------------
# Stage 2: Runtime leggero
# --------------------------
FROM python:3.12-slim

WORKDIR /app

# Copia solo il necessario dal builder
COPY --from=builder /app /app

# Espone la porta dell'app
EXPOSE 8000

# Variabile d’ambiente per i modelli
ENV MODEL_PATH=/app/models

# Comando per avviare FastAPI con Uvicorn
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "2", "--log-level", "info"]
```

---

##### ✅ Vantaggi

1. L’immagine finale **non contiene Poetry né cache di build**, quindi molto più leggera.
2. Mantiene la gestione dei workers e il logging ottimale.
3. Rimane semplice da leggere e da modificare.

---

#### `.dockerignore`

Ecco una `.dockerignore` ottimizzata per il tuo progetto Python/FastAPI con Poetry:

```gitignore
# File di sistema e cache
__pycache__/
*.pyc
*.pyo
*.pyd
*.swp
*.DS_Store
*.egg-info/
*.egg
.env

# Cartelle di build locali
build/
dist/
*.log

# Virtualenv locali (se ne hai)
.venv/
venv/

# File di configurazione IDE
.vscode/
.idea/
*.iml

# Modelli temporanei o dati grandi (se li rigeneri a runtime)
*.sqlite
*.db
*.tmp

# Git
.git/
.gitignore

# Docker
Dockerfile*
docker-compose*.yml
```

---

##### ✅ Note

* Ignora tutto ciò che **non serve nel container**, riducendo la dimensione finale.
* Puoi **aggiungere modelli grandi o dataset** se vuoi copiarli solo in runtime, così il container resta leggero.
* Mantiene comunque tutto ciò che serve per l’esecuzione dell’app e dei modelli.

