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
