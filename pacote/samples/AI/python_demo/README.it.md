# Python Connector Demo (`python_demo`)

Documentazione del sample **`python_demo`**, creato per dimostrare l'uso del componente **`TPythonConnector`** in applicazioni Lazarus/Free Pascal.

## 🌐 Traduzioni

| Lingua | File |
|---|---|
| Português | `README.md` |
| English | `README.en.md` |
| Español | `README.es.md` |
| العربية | `README.ar.md` |
| Italiano | `README.it.md` |
| 日本語 | `README.ja.md` |
| 中文 | `README.zh.md` |
| Русский | `README.ru.md` |
| हिन्दी | `README.hi.md` |

---

## 1. Obiettivo

Questo esempio mostra come integrare un interprete Python in un'applicazione Lazarus usando **`TPythonConnector`**. Il sample permette di attivare Python, eseguire script, catturare l'output, valutare espressioni e scambiare variabili tra Pascal e Python.

È utile per verificare che il runtime Python sia installato o incorporato correttamente prima di usare componenti più complessi di IA, visione artificiale, audio o machine learning nel progetto **CHATGPT**.

---

## 2. Cosa dimostra questo sample

- Selezione di una libreria o di un eseguibile Python compatibile con l'architettura dell'applicazione.
- Attivazione e disattivazione dell'interprete Python.
- Due modalità di esecuzione:
  - **`pemDLL`**: carica `python3.dll`, `python312.dll`, `libpython3.so` o una libreria equivalente.
  - **`pemProcess`**: esegue Python come processo esterno persistente.
- Esecuzione di script con **`ExecString`**.
- Cattura di stdout e stderr tramite **`LastOutput`** e **`LastError`**.
- Lettura e scrittura di variabili globali con **`GetVar`** e **`SetVar`**.
- Valutazione dinamica di espressioni con **`Eval`**.
- Report diagnostico con architettura, versione, modalità di esecuzione, libreria caricata e fase di errore.

---

## 3. Struttura del sample

```text
pacote/samples/AI/python_demo/
├── python_demo.lpi      # Progetto Lazarus
├── python_demo.lpr      # Programma principale
├── main.pas             # Logica del form e integrazione con TPythonConnector
├── main.lfm             # Definizione visuale del form
└── README.md            # Documentazione in portoghese
```

Il progetto dipende dai pacchetti **`LCL`** e **`openai_core`**.

---

## 4. Requisiti

### Lazarus / Free Pascal

- Lazarus installato.
- Pacchetto **`openai_core`** disponibile nel percorso del progetto.
- Progetto aperto tramite **`python_demo.lpi`**.

### Python

Il componente è configurato per accettare Python **da 3.8 a 3.14**.

L'architettura deve corrispondere:

| Applicazione compilata | Python richiesto |
|---|---|
| Windows 64 bit | Python 64 bit |
| Windows 32 bit | Python 32 bit |
| Linux 64 bit | `libpython`/`python3` 64 bit |
| Linux ARM/ARM64 | `libpython`/`python3` della stessa architettura |

Per la modalità **DLL/SO**, installare anche la libreria di sviluppo Python quando necessario.

Esempio su Debian/Ubuntu:

```bash
sudo apt install python3 python3-dev libpython3-dev
```

---

## 5. Come compilare

1. Aprire Lazarus.
2. Aprire il file:

```text
pacote/samples/AI/python_demo/python_demo.lpi
```

3. Compilare con:

```text
Run > Build
```

o premere:

```text
Ctrl + F9
```

4. Eseguire il binario generato:

- Windows: `python_demo.exe`
- Linux: `python_demo`

---

## 6. Come usare

1. Selezionare una DLL, SO o un eseguibile Python dalla lista.
2. Lasciare **Usa Processo Esterno** selezionato per il primo test.
3. Fare clic su **Attiva interprete Python**.
4. Controllare il pannello **Log Operazioni**.
5. Eseguire lo script predefinito o scrivere uno script nel memo.
6. Usare **SetVar**, **GetVar** e **Eval** per testare lo scambio di dati tra Pascal e Python.

---

## 7. Test rapido consigliato

### Script

Incollare nel memo dello script:

```python
x = 10
print("Hello from Python")
print("x =", x)
```

Fare clic su **Esegui Script in Python**.

### Leggere una variabile

Nel campo **Nome Variabile**, inserire:

```text
x
```

Fare clic su **GetVar**.

Valore atteso:

```text
10
```

### Valutare un'espressione

Nel campo dell'espressione, usare:

```python
x + 50
```

Risultato atteso:

```text
60
```

### Nota importante su `SetVar`

Attualmente **`SetVar` salva i valori come stringhe**. Se si usa:

```text
Nome: y
Valore: 10
```

usare questa espressione in Eval:

```python
int(y) + 50
```

invece di:

```python
y + 50
```

---

## 8. Modalità di esecuzione

### `pemProcess` — Processo esterno

È la modalità consigliata per iniziare.

Vantaggi:

- Isola meglio Python dal processo Lazarus.
- Riduce i blocchi causati da conflitti di DLL/SO.
- È più adatta come primo test con librerie pesanti come TensorFlow, OpenCV, Torch o Keras.
- Usa `python.exe`, `python3.exe`, `python3` o un altro eseguibile trovato nel sistema.

### `pemDLL` — Libreria dinamica

Carica Python direttamente nel processo dell'applicazione.

Vantaggi:

- Integrazione più diretta con la Python C API.
- Può essere più veloce per chiamate semplici.

Attenzioni:

- L'architettura deve coincidere esattamente.
- La libreria deve esportare le funzioni obbligatorie della C API.
- Un errore nella libreria Python può chiudere il processo Lazarus.

---

## 9. Diagnostica

Quando Python viene attivato, il sample stampa nel pannello dei log un report con:

- sistema operativo rilevato;
- architettura di Lazarus;
- modalità di esecuzione;
- percorso configurato;
- libreria o eseguibile caricato;
- versione di Python;
- compatibilità dell'architettura;
- funzioni obbligatorie trovate;
- ultima fase di caricamento;
- ultimo errore, se presente.

Usare questo report prima di concludere che il componente non funziona. Nella maggior parte dei casi il problema è un'incompatibilità di architettura, una libreria mancante o Python fuori dal PATH.

---

## 10. Problemi comuni

| Sintomo | Causa probabile | Correzione |
|---|---|---|
| `Failed to load python3.dll` | Python non installato, DLL mancante o architettura errata | Installare Python con la stessa architettura dell'eseguibile |
| `Failed to load libpython` | Pacchetto di sviluppo mancante su Linux | Installare `python3-dev`/`libpython3-dev` |
| Python si attiva, ma `GetVar` fallisce | Funzioni opzionali della C API non disponibili in modalità DLL | Provare con `pemProcess` |
| `y + 50` fallisce dopo `SetVar` | `SetVar` inserisce una stringa | Usare `int(y) + 50` o definire `y = 10` nello script |
| Nessun output | Lo script non usa `print` o l'esecuzione è fallita | Controllare `LastError` e il log |
| Funziona nel terminale ma non in Lazarus | PATH diverso nell'ambiente IDE | Usare il percorso assoluto di Python |

---

## 11. Buone pratiche

- Testare prima con **`pemProcess`**.
- Usare **`pemDLL`** solo quando serve integrazione diretta con la C API.
- Mantenere Python e Lazarus sulla stessa architettura.
- Per la distribuzione, collocare il runtime Python nella cartella dell'applicazione o in una sottocartella `libs`.
- Copiare sempre il report diagnostico quando si segnala un errore.
- Evitare script lunghi direttamente nel memo; preferire test brevi e incrementali.

---

## 12. Relazione con il progetto CHATGPT

Questo sample valida il ponte Lazarus ↔ Python. Prepara la base per altri componenti Python del progetto, come:

- classificazione di immagini;
- modelli CNN;
- YOLO;
- OpenCV;
- rilevamento facciale;
- elaborazione audio;
- librerie di machine learning.

Prima di investigare errori in componenti IA più complessi, eseguire questo sample per confermare che Python venga caricato correttamente.

---

## 13. Miglioramenti futuri suggeriti

- Aggiungere un pulsante per individuare manualmente `python.exe`, `python3`, DLL, SO o dylib.
- Mostrare chiaramente se l'elemento selezionato è un eseguibile o una libreria.
- Separare l'interfaccia in schede: Configurazione, Script, Variabili, Eval e Diagnostica.
- Aggiungere un pulsante **Copia diagnostica**.
- Salvare l'ultima configurazione usata.
- Validare prima dell'attivazione che il file selezionato esista.
- Mostrare un avviso quando `SetVar` è usato con un valore numerico, spiegando che sarà trattato come stringa.

---

## 14. Riepilogo

**`python_demo`** è il primo test consigliato per qualsiasi integrazione Python nel pacchetto CHATGPT. Se questo sample attiva l'interprete, esegue script, legge variabili e valuta espressioni, la base di integrazione Python funziona.