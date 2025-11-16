# Bytebot — LLMGateway Integration

## 🔹 Introduzione

Questo progetto integra **LLMGateway** con **Bytebot**, permettendo a Bytebot di utilizzare modelli LLM locali (in formato GGUF) e provider remoti come Hugging Face, OpenRouter, o altri compatibili.  
L’integrazione offre flessibilità, privacy, e resilienza: puoi eseguire modelli localmente oppure usare API esterne, definire priorità e fallback, ed evitare costi e latenza inutili.

---

## 🌳 Struttura della repository

```

bytebot-llmgateway/
├── llmgateway/
│   ├── config.yaml          # Configurazione del gateway LLM
│   └── Dockerfile           # Dockerfile custom per LLMGateway
├── .env.example              # Template per variabili d’ambiente
├── compose.yml               # Podman / Docker Compose principale
├── docker-compose.yml        # Variante alternativa di Compose
├── download_models.sh        # Script per scaricare modelli GGUF
├── select_model.sh           # Script per scegliere il modello locale
├── README_compose.md         # Documentazione legacy o aggiuntiva
└── README.md                  # Questo documento README principale

````

---

## 🔍 Perché Bytebot + LLMGateway

- **Bytebot**: un agent AI basato su container che può controllare un desktop virtuale, digitare, navigare, automatizzare interazioni.  
- **LLMGateway**: un server che esegue LLM, con supporto per modelli locali (GGUF) e provider remoti (Hugging Face, OpenRouter, ecc.).  
- Con l’integrazione:
  - Puoi usare **modelli locali** in modo efficiente e **risparmiare** denaro.  
  - Definire **fallback automatici**: se un modello locale non è disponibile, il gateway può passare a un modello remoto configurato.  
  - Configurare **più provider remoti** e dare priorità tra loro (ad esempio: locale → HF → OpenRouter).

---

## 🔧 Guida di configurazione

1. **Clona il repository**  
   ```bash
   git clone <url-repo> bytebot-llmgateway
   cd bytebot-llmgateway
````

2. **Copia `.env.example` e modificalo**

   ```bash
   cp .env.example .env
   ```

   Imposta:

   * `HF_API_KEY` e `HF_MODEL` per Hugging Face
   * `OPENROUTER_API_KEY` e `OPENROUTER_MODEL` per OpenRouter
   * `LOCAL_MODEL_PATH` per il modello GGUF locale
   * Altri campi (DB, URL Bytebot) come richiesto

3. **Scarica modelli locali**

   ```bash
   chmod +x download_models.sh
   ./download_models.sh
   ```

   I modelli verranno salvati in `./models`.

4. **Seleziona il modello locale da usare**

   ```bash
   chmod +x select_model.sh
   ./select_model.sh
   ```

   Il comando aggiorna `.env` con `LOCAL_MODEL_PATH=/models/<nome_modello>.gguf`.

5. **Avvia i container**

   ```bash
   podman compose -f compose.yml up -d
   # oppure con Docker
   docker-compose -f docker-compose.yml up -d
   ```

6. **Verifica lo stato**

   * Gateway LLM: `http://localhost:7000/health`
   * Interfaccia Bytebot UI: `http://localhost:9992` (o porta configurata)

---

## ⚙️ Configurazione di LLMGateway (llmgateway/config.yaml)

Esempio di configurazione:

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

### Cosa significa:

* **providers**: definisci tutti i provider che vuoi usare (locale + remoti).
* **auto_pick**: se attivo, LLMGateway sceglie in base alla priorità definita (`priority`). Se un provider non risponde entro `timeout_ms`, passa al prossimo.
* **cache**: memorizza risposte per non ricomputare continuamente la stessa richiesta.
* **rate_limit**: limita le richieste per proteggere server locali o limiti API remoti.

---

## 🔐 Uso di più provider remoti

### Esempi di scenari:

* Vuoi usare un **modello locale** per la maggior parte delle richieste, ma se la macchina è sovraccarica, vuoi che Bytebot usi **Hugging Face** come fallback.
* Hai licenze API su **OpenRouter** e **Hugging Face**, e vuoi dividere il carico tra i due provider.
* Vuoi testare più modelli remoti senza cambiare il codice di Bytebot, solo cambiando la configurazione di LLMGateway.

### Come configurare:

1. Aggiungi un provider nella sezione `providers` in `config.yaml`.
2. Assicurati di avere le variabili d’ambiente corrispondenti (`HF_API_KEY`, `OPENROUTER_API_KEY`, ecc.).
3. Imposta l’ordine di priorità in `auto_pick.priority`, ad esempio: `[local, openrouter, hf]`.
4. Regola il `timeout_ms` se vuoi dare più tempo ai modelli remoti più lenti, o meno se vuoi che il fallback avvenga rapidamente.
5. Se vuoi disabilitare il fallback, puoi mettere `auto_pick.enabled: false` e usare esplicitamente un provider chiamando LLMGateway con `provider: local` o `provider: hf`.

---

## 🧪 Scenari d’uso avanzati

* **Agent Bytebot con fallback intelligente**: Bytebot può usare il modello locale per task normali, ma per task complessi o molto costosi di calcolo può usare un modello remoto quando necessario.
* **Bilanciamento costi / prestazioni**: usa un modello più “leggero” locale e un modello “di backup” remoto, evitando sempre di pagare per ogni richiesta.
* **Ambienti di test e sviluppo**: puoi testare nuovi modelli remoti (es. modelli HF sperimentali) senza interrompere il flusso di produzione, grazie alla configurazione dinamica di LLMGateway.
* **Deploy aziendale**: mantieni i dati sensibili in locale, ma mantieni la flessibilità di usare API esterne quando serve.

---

## 🧰 Comandi utili

| Comando                               | Cosa fa                                                                   |
| ------------------------------------- | ------------------------------------------------------------------------- |
| `./download_models.sh`                | Scarica modelli GGUF definiti nello script                                |
| `./select_model.sh`                   | Lista i modelli `.gguf` e aggiorna `.env` con quello scelto               |
| `podman compose -f compose.yml up -d` | Avvia tutti i container necessari: Bytebot Desktop, LLMGateway, Agent, DB |
| `podman compose -f compose.yml down`  | Ferma e rimuove i container                                               |

---

## 📌 Note

* Assicurati di avere **sufficiente spazio disco**: i modelli GGUF possono essere molto grandi.
* Se usi LLM locale su CPU, regola `n_threads` e `n_gpu_layers` in `config.yaml` per ottimizzare le prestazioni.
* Se usi più provider remoti, monitora il tuo utilizzo API (es. HF) per evitare costi imprevisti.
* Controlla i log di LLMGateway (es. `podman logs llmgateway`) per debug di problemi di connessione con i provider remoti.

---
---

Ecco un **README.md unico, completo e aggiornato**, che include: introduzione, struttura della repo, configurazione, uso, architettura, scenari d’uso e sezione avanzata su provider remoti.

```markdown
# Bytebot + LLMGateway — README Completo

Questo progetto integra **LLMGateway** con **Bytebot**, permettendo a Bytebot di usare modelli LLM locali (GGUF) e provider remoti (Hugging Face, OpenRouter). In questo modo puoi avere un agent AI potente, flessibile e self‑hosted.

---

## 1. Introduzione

- **Bytebot** è un agent AI desktop containerizzato: può digitare, cliccare, navigare su un desktop virtuale e automatizzare flussi complessi.  
- **LLMGateway** è un server che fa da ponte tra modelli LLM locali (es. GGUF / LLaMA.cpp) e provider remoti (es. Hugging Face, OpenRouter).  
- Grazie a questa integrazione puoi:  
  - Usare modelli **locali**, riducendo costi e dipendenza da API esterne  
  - Definire **fallback automatici** su provider remoti se il modello locale è lento o non disponibile  
  - Gestire **più provider remoti**, dando loro priorità e configurando modelli diversi

---

## 2. Struttura del progetto

```

bytebot-llmgateway/
├── llmgateway/
│   ├── config.yaml          # File di configurazione di LLMGateway
│   └── Dockerfile           # Dockerfile per costruire il container LLMGateway
├── .env.example              # Esempio di variabili d’ambiente
├── compose.yml               # Docker / Podman Compose principale
├── docker-compose.yml        # Variante alternativa di Compose
├── download_models.sh        # Script per scaricare modelli GGUF locali
├── select_model.sh           # Script per selezionare il modello GGUF da usare
├── README_compose.md         # Documentazione legacy / aggiuntiva
└── README.md                  # Questo file README completo

````

---

## 3. Configurazione iniziale

1. Clona il repository:  
   ```bash
   git clone <URL_DEL_REPO> bytebot-llmgateway
   cd bytebot-llmgateway
````

2. Copia il file di esempio delle variabili d’ambiente:

   ```bash
   cp .env.example .env
   ```

   Modifica `.env` con i valori corretti per:

   * `HF_API_KEY`, `HF_MODEL` → Hugging Face
   * `OPENROUTER_API_KEY`, `OPENROUTER_MODEL` → OpenRouter
   * `LOCAL_MODEL_PATH` → percorso del modello locale `.gguf`
   * `DATABASE_URL` e URL di Bytebot (`BYTEBOT_DESKTOP_BASE_URL`, `BYTEBOT_AGENT_BASE_URL`, ecc.)

---

## 4. Download dei modelli localmente

Esegui lo script:

```bash
chmod +x download_models.sh
./download_models.sh
```

Questo scaricherà alcuni modelli GGUF nella directory `./models`.

---

## 5. Selezione del modello locale

Per scegliere quale modello locale usare:

```bash
chmod +x select_model.sh
./select_model.sh
```

Lo script mostrerà tutti i modelli `.gguf` presenti in `./models`, ti permetterà di selezionarne uno e aggiornerà automaticamente la variabile `LOCAL_MODEL_PATH` nel file `.env`.

---

## 6. Avvio dei container

Puoi avviare tutto con Podman o Docker:

```bash
podman compose -f compose.yml up -d
```

o:

```bash
docker-compose -f docker-compose.yml up -d
```

I container che verranno avviati includono:

* Bytebot Desktop
* LLMGateway
* Bytebot Agent
* PostgreSQL (database)

---

## 7. Verifica che tutto funzioni

* Controlla l'health di LLMGateway:

  ```
  http://localhost:7000/health
  ```
* Verifica l’interfaccia di Bytebot UI (se configurata): ad esempio su `http://localhost:9992` (dipende dalla configurazione del tuo `docker-compose` / `compose.yml`).

---

## 8. Configurazione avanzata di LLMGateway

Nel file `llmgateway/config.yaml` puoi definire:

* Provider di modelli (locale e remoti)
* Parametri per il modello locale (es. contesto, threads, GPU)
* Priorità e fallback automatico
* Cache delle risposte
* Rate limiting

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

### Come gestire più provider remoti:

* Aggiungi ciascun provider nella sezione `providers`.
* Imposta le chiavi API nel `.env`.
* Controlla l’ordine di priorità con `auto_pick.priority`. Se il provider più alto non risponde, gateway passerà al successivo.
* Usa `timeout_ms` per decidere quando fallbackare.
* Se vuoi disabilitare il fallback, puoi impostare `auto_pick.enabled` su `false` e specificare il provider nelle chiamate.

---

## 9. Architettura e flusso dati

Di seguito un diagramma logico del flusso tra Bytebot, LLMGateway e i modelli:

```
+----------------+        +-------------------+        +----------------------+
| Bytebot Agent  | -----> | LLMGateway Server | -----> | Modello Locale GGUF  |
| (Task / API)   |        | (Local + Remote)  |        | (LLaMA.cpp / GGUF)   |
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

**Flusso operativo**:

1. Bytebot Agent invia una richiesta LLM (es. completamento) a LLMGateway.
2. LLMGateway valuta i provider in base alla priorità configurata:

   * Se il modello locale è abilitato e “abbastanza veloce”, lo usa.
   * Altrimenti, passa a un provider remoto.
3. Il risultato può essere **cachato** per risposte future identiche.
4. Rate limiting protegge la risorsa (locale o remota) da sovraccarichi.

---

## 10. Scenari d’uso

* **Automazione Desktop Intelligente**: Bytebot esegue task complessi, usa il modello locale per la generazione di prompt, istruzioni o analisi.
* **Privacy First**: Tutto il modello può risiedere localmente, senza dipendere da servizi cloud esterni.
* **Riduzione dei Costi**: Usare modelli GGUF locali può essere più economico di chiamate API continue.
* **Fallback Intelligente**: Se il modello locale ha prestazioni scarse o è saturato, LLMGateway può fare fallback verso un modello API, garantendo resilienza.
* **Ambiente di Sviluppo / Test**: Puoi testare modelli remoti o locali in parallelo, senza cambiare codice di Bytebot, solo configurazione.

---

## 11. Sicurezza e best practices

* Esegui Bytebot e LLMGateway su macchine o VM sicure, se vuoi mantenere la riservatezza.
* Proteggi le tue chiavi API (HF, OpenRouter) nel file `.env` e non condividerle.
* Monitora l’utilizzo API se usi provider remoti per evitare costi imprevisti.
* Se usi modelli GGUF locali di grandi dimensioni, assicurati di avere sufficiente RAM per evitare swapping lento.

---

## 12. Comandi utili

| Comando                               | Descrizione                                                            |
| ------------------------------------- | ---------------------------------------------------------------------- |
| `./download_models.sh`                | Scarica i modelli GGUF definiti nello script nella cartella `./models` |
| `./select_model.sh`                   | Mostra i modelli `.gguf`, ne permette la selezione e aggiorna `.env`   |
| `podman compose -f compose.yml up -d` | Avvia i container Bytebot, LLMGateway, DB                              |
| `podman compose -f compose.yml down`  | Ferma e rimuove i container                                            |
| `podman logs llmgateway`              | Mostra i log di LLMGateway per debugging e diagnostica                 |

---
---

Perfetto! Ti creo un **README.md unico, completo e aggiornato**, che include:

* Introduzione ai progetti Bytebot e LLMGateway
* Motivazioni per l’integrazione
* Struttura della repository (grafo testuale)
* Installazione e configurazione passo passo
* Descrizione dei file principali
* Comandi utili
* Architettura dei flussi dati
* Scenari d’uso e sicurezza

---

```markdown
# Bytebot — LLMGateway Integration

## 🔹 Introduzione

Questo progetto integra **LLMGateway** con **Bytebot**, permettendo a Bytebot di utilizzare modelli LLM locali (in formato GGUF) e provider remoti come Hugging Face o OpenRouter.  
In pratica, Bytebot può diventare un **agent AI desktop self-hosted** capace di:

- Automatizzare attività sul desktop Linux containerizzato
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
Bytebot è un **agent AI desktop open-source**, eseguito in container Linux isolati, che può:

- Digitare, cliccare, navigare sul web e interagire con applicazioni  
- Automatizzare flussi complessi come farebbe un umano  
- Esporre API per la gestione di task e un’interfaccia web UI  

[Documentazione Bytebot](https://docs.bytebot.ai)

### LLMGateway
LLMGateway è un **server ponte** tra:

- Modelli LLM locali (GGUF, LLaMA.cpp)  
- Provider remoti (Hugging Face, OpenRouter)  

Permette a Bytebot di:

- Usare modelli locali con fallback verso modelli remoti  
- Controllare configurazioni di modello (thread, contesto, GPU)  
- Cache delle risposte e rate-limiting  

**Vantaggi principali dell’integrazione:**  

- Self-hosted → privacy e sicurezza  
- Risparmio sui costi delle API  
- Controllo completo sui modelli  
- Flessibilità: puoi cambiare facilmente modello locale o provider remoto

---

## 🔧 Guida di configurazione

### 1. Clona il progetto
```bash
git clone <url-del-repo> bytebot-llmgateway
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

Salva i modelli in `./models`.

### 4. Seleziona il modello da usare

```bash
chmod +x select_model.sh
./select_model.sh
```

Lo script aggiorna `LOCAL_MODEL_PATH` in `.env`.

### 5. Avvia i container

```bash
podman compose -f compose.yml up -d
# oppure
docker-compose -f docker-compose.yml up -d
```

Container attivi:

* Desktop Bytebot
* LLMGateway
* Agent Bytebot
* Database PostgreSQL

### 6. Verifica funzionamento

* LLMGateway → `http://localhost:7000/health`
* UI Bytebot → `http://localhost:9992`

---

## ⚙️ Configurazione LLMGateway (`llmgateway/config.yaml`)

Definisce:

* Provider LLM: locale + remoti
* Parametri modello locale: `n_ctx`, threads, GPU
* Fallback automatico
* Cache e rate limiting

---

## 🔐 Sicurezza e benefici

* Self-hosted → dati rimangono locali
* Modelli GGUF → costi ridotti e bassa latenza
* Fallback integrato → resilienza
* Modulabile → facile cambiare modelli o configurazioni

---

## 🧰 Comandi utili

| Comando                               | Descrizione                               |
| ------------------------------------- | ----------------------------------------- |
| `./download_models.sh`                | Scarica modelli GGUF in `./models`        |
| `./select_model.sh`                   | Seleziona modello e aggiorna `.env`       |
| `podman compose -f compose.yml up -d` | Avvia container Bytebot + LLMGateway + DB |
| `podman compose -f compose.yml down`  | Ferma e rimuove container                 |

---

## 🏗️ Architettura e flusso dati

```
+----------------+        +-------------------+        +----------------------+
| Bytebot Agent  | -----> | LLMGateway Server | -----> | Modello Locale GGUF  |
| (Task & UI)    |        | (Local + Remote)  |        | (LLaMA.cpp / GGUF)   |
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

**Flusso**:

1. L’agent Bytebot riceve un task dalla UI/API
2. Invia la richiesta a LLMGateway
3. LLMGateway prova modello locale → fallback remoto se necessario
4. Risposta torna a Bytebot e, se necessario, salvata nel DB

---

## 🧪 Scenari d’uso

* Automazione desktop complessa
* Document analysis e riassunto di PDF
* Test di agent AI interattivi
* Automazione interna in azienda con privacy garantita

---

## 📌 Note

* Aggiorna `.env` prima di ogni cambio modello
* Assicurati di avere spazio sufficiente per modelli GGUF (>2–20GB a seconda del modello)
* Controlla log dei container per debug (`podman logs <container>`)

---

```
README.md generato con tutte le informazioni per installare, configurare e usare Bytebot + LLMGateway.
```


