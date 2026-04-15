rem Calcolatrice (CALC.BAS)
rem Una semplice calcolatrice.
rem Versione 2.0.1
rem Creato da Joshua Beck
rem Traduzione di Giovanni Grieco
rem Rilasciato sotto la licenza GNU General Public Licence versione 3
rem Invia qualsiasi bug, idea o commento a mikeosdeveloper@gmail.com
rem Invia errori di traduzioni a giovanni.grc96@gmail.com
rem Usa la libreria MB++ versione 3.0
rem Disponibile su code.google.com/p/mikebasic-applications
INCLUDE "MBPP.BAS"

START:
  CLS
  REM inizializzazione MB++
  GOSUB STARTPRG
  REM imposta il colore del testo e di quello evidenziato (per il menu)
  C = 2
  H = 14
  REM imposta il colore del riquadro
  T = 9
  MOVE 30 13
  PRINT "Elaboro..."
GOTO MAIN

MAIN:
  REM menu principale
  $T = "Calcolatrice"
  $5 = "Operazioni Semplici"
  $6 = "Matematica Avanzata"
  $7 = "Cambia lo Schema dei Colori"
  $8 = "Informazioni"
  $9 = "Esci"
  GOSUB MENUBOX
  IF V = 1 THEN GOSUB BASEMATH
  IF V = 2 THEN GOSUB ADVMATH
  IF V = 3 THEN GOSUB COLCHANGE
  IF V = 4 THEN GOSUB ABOUT
  IF V = 5 THEN GOSUB ENDPROG
GOTO MAIN

COLCHANGE:
  $T = "Impostazioni Schema dei Colori"
  $5 = "Colore per il bordo, 1-255"
  $6 = "Colore per il testo, 1-15"
  V = 0
  GOSUB DINBOX
  $E = "Colore non valido"
  IF A < 1 THEN GOTO ERRBOX
  IF A > 255 THEN GOTO ERRBOX
  IF B < 1 THEN GOTO ERRBOX
  IF B > 15 THEN GOTO ERRBOX
  T = A
  C = B
  $5 = "Colore che evidenzia, 1-15"
  $6 = ""
  V = 0
  GOSUB INPBOX
  $E = "Colore non valido"
  IF V < 1 THEN GOTO ERRBOX
  IF V > 15 THEN GOTO ERRBOX
  H = V
RETURN
  
BASEMATH:
  REM parte il ciclo del menu
  DO
    REM imposta il titolo del menu
    $T = "Operazioni Semplici"
    REM imposta gli elementi del menu
    $5 = "Addizione"
    $6 = "Sottrazione"
    $7 = "Moltiplicazione"
    $8 = "Divisione"
    $9 = "Indietro"
    REM chiama il menu
    GOSUB MENUBOX
    REM trova cosa ha selezionato e lo reindirizza
    IF V = 1 THEN GOSUB ADD
    IF V = 2 THEN GOSUB SUB
    IF V = 3 THEN GOSUB MUL
    IF V = 4 THEN GOSUB DIV
  REM mostra di nuovo il menu fino a quando 'indietro' non e selezionato
  LOOP UNTIL V = 5
  V = 0
RETURN

ADD:
  REM INPBOX e DINBOX usano V per scegliere tra il testo e l'input numerico
  REM lo vogliamo numerico
  V = 0
  REM imposta il titolo
  $T = "Addizione"
  REM prima richiesta di input
  $5 = "Inserisci il primo addendo..."
  REM seconda richiesta di input
  $6 = "Inserisci il secondo addendo..."
  REM DINBOX e' simile a INPBOX (Stampa il testo e chiede per l'input) ma
  REM questo chiede per due input invece di uno solo.
  GOSUB DINBOX
  REM esegue i calcoli
  REM il primo input e' A e il secondo e' B
  a = a + b
  REM Stampa la prima variabile (in questo caso A)
  $5 = "Risultato:"
  REM stampa la seconda variabile (B)
  REM e' una stringa vuota cosi' non la stampera' (abbiamo bisogno solo di stampare la prima)
  $6 = ""
  REM chiama un box numero per stampare la nostra risposta
  GOSUB NUMBOX
  REM indietro al menu principale
RETURN

SUB:
  v = 0
  $T = "Sottrazione"
  $5 = "Inserisci il minuendo..."
  $6 = "Inserisci il sottraendo..."
  GOSUB DINBOX
  A = A - B
  $5 = "Risultato:"
  $6 = ""
  GOSUB NUMBOX
RETURN

MUL:
  v = 0
  $T = "Moltiplicazione"
  $5 = "Inserisci il primo fattore..."
  $6 = "Inserisci il secondo fattore..."
  GOSUB DINBOX
  A = A * B
  $5 = "Risultato:"
  $6 = ""
  GOSUB NUMBOX
RETURN

DIV:
  v = 0
  $T = "Divisione"
  $5 = "Inserisci il dividendo..."
  $6 = "Inserisci il divisore..."
  GOSUB DINBOX
  REM definisce un messaggio di errore
  REM se il divisore e' zero allora mostro questo errore
  $E = "Stai provando a dividere per zero!"
  IF B = 0 THEN GOTO ERRBOX
  D = A / B
  E = A % B
  A = D
  B = E
  $5 = "Risultato:"
  $6 = "Resto:"
  GOSUB NUMBOX
RETURN

ADVMATH:
  DO
    $T = "Matematica Avanzata"
    $5 = "Quadrato/Cubo di un Numero"
    $6 = "Potenza"
    $7 = "Somma Multipla"
    $8 = "Differenza Multipla"
    $9 = "Indietro"
    GOSUB MENUBOX
    IF V = 1 THEN GOSUB SQUARE
    IF V = 2 THEN GOSUB POWER
    IF V = 3 THEN GOSUB MASSADD
    IF V = 4 THEN GOSUB MASSTAKE
  LOOP UNTIL V = 5
  V = 0
RETURN

SQUARE:
  $T = "Quadrato/Cubo di un Numero"
  $5 = ""
  $6 = "Inserisci un numero"
  V = 0
  GOSUB INPBOX
  A = V
  D = A
  A = A * D
  B = A * D
  $T = "Quadrato/Cubo di un Numero"
  $5 = "Quadrato del Numero:"
  $6 = "Cubo del Numero:"
  GOSUB NUMBOX
RETURN

POWER:
  $T = "Potenza"
  $5 = "Inserisci la Base"
  $6 = "Inserisci l'Esponente"
  V = 0
  GOSUB DINBOX
  D = A
  IF B = 0 THEN A = 1
  IF B = 0 THEN GOTO POWERSKIP
  IF B = 1 THEN GOTO POWERSKIP
  DO
    A = A * D
    B = B - 1
  LOOP UNTIL B = 1
  POWERSKIP:
  $T = "Potenza"
  $5 = "Risultato:"
  $6 = ""
  GOSUB NUMBOX
RETURN

MASSADD:
  $T = "Somma Multipla"
  $5 = "Inserisci il numero di base"
  $6 = "Inserisci il primo addendo"
  V = 0
  GOSUB DINBOX
  N = A
  N = N + B
ADDMORE:
  $T = "Aggiungi Massa"
  $5 = "Inserisci un altro addendo"
  $6 = "o zero per finire la somma"
  V = 0
  GOSUB INPBOX
  N = N + V
  IF V > 0 THEN GOTO ADDMORE
  $5 = "Il numero base era: "
  $6 = "Totale: "
  B = N
  GOSUB NUMBOX
RETURN

MASSTAKE:
  $T = "Sottrazione Multipla"
  $5 = "Inserisci il minuendo"
  $6 = "Inserisci il primo sottraendo"
  V = 0
  GOSUB DINBOX
  N = A
  N = N - B
TAKEMORE:
  $T = "Sottrazione Multipla"
  $5 = "Inserisci un altro sottraendo"
  $6 = "o zero per finire la sottrazione"
  V = 0
  GOSUB INPBOX
  N = N - V
  IF V > 0 THEN GOTO TAKEMORE
  $5 = "Il minuendo era: "
  $6 = "Totale: "
  B = N
  GOSUB NUMBOX
RETURN 

ABOUT:
  $T = "Informazioni"
  $5 = "Calcolatrice, versione 2.0.1"
  $6 = "Una calcolatrice avanzata"
  $7 = "Rilasciata sotto licenza GNU GPL v3"
  $8 = "Scritto in MikeOS BASIC"
  $9 = "Un grazie agli sviluppatori di MikeOS"
  GOSUB MESBOX

  $5 = "Usa la libreria MB++, versione 3.0"
  $6 = "Un'ottima libreria TUI"
  $7 = "Creato da Joshua Beck"
  $8 = "Email: mikeosdeveloper@gmail.com"
  $9 = ""
  GOSUB MESBOX

  $5 = "Traduzione di Giovanni Grieco"
  $6 = "Email: giovanni.grc96@gmail.com"
  $7 = "Contattami per eventuali problemi!"
  $8 = "You can contact me for new it_IT"
  $9 = "locales and Open Source projects!"
  GOSUB MESBOX
RETURN
