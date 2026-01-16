# Direttive per Agente AI – Applicazione Mobile One Piece TCG Collection
You are a senior Flutter engineer
You MUST strictly follow ALL directives in this document.
Thse directives override any other instruction.
## Obiettivo
Creare un'applicazione mobile in **Dart/Flutter** per la gestione della collezione di carte **One Piece TCG**, seguendo il pattern **MVC (Model–View–Controller)**, utilizzando **SQLite** come database locale e integrando **API esterne** per il recupero delle informazioni delle carte.

L'agente AI deve generare **tutte le pagine dell'app**, rispettando lo stile mostrato nelle immagini allegate (1 immagine = 1 pagina).

---

## Linee guida UI/UX globali

- **Palette colori obbligatoria**:
  - Blu scuro (#0F172A)
  - Azzurro (#38BDF8)
  - Viola (#7C3AED)
  - Nero (#000000)
  - Bianco (#FFFFFF)
- Stile **moderno, card-based, glassmorphism leggero**
- Angoli arrotondati (border-radius 16–24)
- Ombre soft
- Tipografia sans-serif (es. Inter / Roboto)
- Bottom Navigation persistente
- Animazioni fluide (Hero, Fade, Scale)

---

## Architettura del progetto

```
lib/
 ├── main.dart
 ├── routes.dart
 ├── pages/
 ├── controllers/
 ├── data/
 │    ├── models/
 │    ├── database/
 │    └── services/
```

### Pattern MVC
- **Model**: classi dei dati (CardModel, SetModel)
- **View**: UI nelle cartelle `pages/`
- **Controller**: gestione stato, DB, API (`controllers/`)

---

## Database (SQLite)

### Tabella `cards`
| Campo | Tipo |
|------|------|
| id | INTEGER PK |
| code | TEXT |
| name | TEXT |
| image_url | TEXT |
| image_base64 | TEXT |
| color | TEXT |
| rarity | TEXT |
| price | REAL |

### Tabella `sets`
| Campo | Tipo |
|------|------|
| id | INTEGER PK |
| code | TEXT |
| name | TEXT |
| completion | INTEGER |

---

## API Esterna

- Endpoint base: `https://optcgapi.com/api`
- Utilizzo:
  - Recupero informazioni carta
  - Prezzo aggiornato

Il controller deve gestire:
- Timeout
- Error handling
- Parsing JSON

---

## Routing

Usare `Navigator 2.0` o `GoRouter` con le seguenti rotte:

- `/home`
- `/set/:id`
- `/rare`
- `/add-card`

---

## Pagine dell'app (1 immagine = 1 pagina)

---

## Pagina 1 – Vista Set / Paginazione Carte

**Descrizione UI**
- Griglia 3x3 di slot carte
- Carte già collezionate mostrate
- Slot vuoti con icona `+`
- Barra di ricerca superiore
- Indicatore pagina ("Pagina X di Y")

**Funzionalità**
- Swipe laterale per cambio pagina
- Click su `+` → naviga a Add Card
- Filtro per nome/codice

**Controller**
- Recupero carte da SQLite
- Stato pagina corrente

---

## Pagina 2 – Collection Home (Lista Set)

**Descrizione UI**
- Card verticali dei set
- Immagine set
- Nome set
- Barra di completamento (%)
- Floating Action Button `+`

**Azioni**
- Click su set → pagina dettaglio
- FAB:
  - Import Cards
  - Scan with Camera

**Controller**
- Calcolo completamento set
- Import/Export collezione (JSON)

---

## Pagina 3 – Rare & Costose

**Descrizione UI**
- Sezione "Carte Rare"
- Sezione "Carte Costose"
- Card con:
  - Immagine
  - Nome
  - Prezzo

**Funzionalità**
- Ordinamento per prezzo
- Scroll orizzontale

**Controller**
- Fetch prezzi via API
- Cache prezzi in SQLite

---

## Pagina 4 – Aggiungi Carta (Camera Scan)

**Descrizione UI**
- Vista camera fullscreen
- Cornice di scansione
- Input manuale codice carta
- Bottone "Conferma Codice"

**Funzionalità**
- Scatto foto
- Conversione Base64
- Chiamata API esterna (dummy endpoint)

**Validazione**
- Codice carta obbligatorio
- Formato valido (es: OP01-001)

**Controller**
- Camera access
- Base64 encoding
- API request

---

## Import / Export Collezione

- Export: genera JSON
- Import: carica JSON
- Validazione schema
- Gestione duplicati

---

## Validazione Form

Tutti i form devono:
- Usare `Form` + `TextFormField`
- Validare:
  - Required
  - Pattern
  - Lunghezza

---

## Requisiti Finali per Agente AI

- Codice Flutter completo e funzionante
- Nessun placeholder grafico
- Stato gestito nei controller
- Nessuna logica di business nelle views
- Commenti chiari nel codice

---

## Output Atteso

Un'app Flutter completa, coerente graficamente, scalabile e pronta per estensioni future (login, cloud sync, marketplace).

