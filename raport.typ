#set document(
  title: [WBIK Raport z projektu: Przeprowadzenie prostego ataku mocy na asymetryczny algorytm kryptograficzny],
  author: "Michał Romsicki"
)

#set heading(
  numbering: "1."
)

#let title-table(subject, topic, name, album_nr) = [
  #table(
    columns: (1fr, 1fr),
    fill: (_, y) =>
      if y == 0 { rgb("b6bab7") }
      else if y == 2 { rgb("d5dbd7") },
    inset: (x, y) =>
        if y == 0 { 10pt }
        else if y == 1 { 8pt }
        else { 6pt },
    // stroke: 1pt + black,
    align: (center),
    table.cell(
      colspan: 2,
      text(size: 16pt)[
        *#subject*
      ],
    ),
    table.cell(
      colspan: 2,
      text(size: 12pt)[
        #topic
      ],
    ),
    text(size: 12pt)[
      Imię i nazwisko: #name
    ],
    text(size: 12pt)[
      Nr albumu: #album_nr
    ],
  )
]

#show heading.where( level: 1 ): it => block(width: 100%)[
  #set align(left)
  #set text(14pt, weight: "bold")
  #it
  #v(0.4em)
]

#show heading.where( level: 2 ): it => block(width: 100%)[
  #set align(left)
  #set text(12pt, weight: "bold")
  #it
  #v(0.4em)
]

#let heading0(body) = block(width: 100%)[
  #set align(left)
  #set text(14pt, weight: "bold")
  #v(0.4em)
  0. #body
]

#show raw.where(block: true): it => [
  #set text(size: 7pt)
  #it
]

#set par(justify: true)
#show par: set text(size: 11pt)

#set figure(placement: auto, supplement: [Rysunek])

#show ref.where(
  form: "normal"
): set ref(supplement: it => {
    "Rys."
})

#let img-border-style = stroke(thickness: 0.3pt, paint: gray)

#place(
  center + top,
  dy: 30%,
  [
    #text(20pt)[ *Współczesne wyzwania bezpieczeństwa informacji i kryptografii*\ ]
    #text(2pt)[ \ ] // xd
    #text(16pt)[ Projekt: Przeprowadzenie prostego ataku mocy na asymetryczny\
    algorytm kryptograficzny ]
  ]
)

#place(
  bottom + center,
  [
    Autor: Michał Romsicki\  
    Prowadzący:\  
    Data: 30.01.2026 r.
  ]
)

#pagebreak()
#set page(
  numbering: "1"
)

// #title-table(
//   "Współczesne wyzwania bezpieczeństwa informacji i kryptografii",
//   "Projekt: Przeprowadzenie prostego ataku mocy na asymetryczny algorytm kryptograficzny",
//   "Michał Romsicki",
//   "347437"
// )
//
#heading0[Cel projektu]

Celem projektu było przeprowadzenie prostego ataku mocy na asymetryczny algorytm kryptograficzny
wykorzystującego potęgowanie w grupie multiplikatywnej w celu pozyskania klucza prywatnego. Ze względu na
względną prostotę zasady działania, zdecydowano się na wykorzystanie protokołu Diffiego-Hellmana służącego do
uzgadniania kluczy szyfrujących. Atak miał umożliwić uzyskanie klucza prywatnego jednej ze stron komunikacji,
co w konsekwencji umożliwiłoby obliczenie wspólnego klucza tajnego używanego ostatecznie do szyfrowania
wiadomości. Podatność algorytmu potęgowania na prosty atak mocy wynika z faktu, że wykonywane operacje zależą
od wartości bitu wykładnika (atakowanego klucza), co umożliwia bespośrednie powiązanie wartości bitu z
sygnaturą mocy.

= Wybór sprzętu

Ze względu na dostępność płytki, jak również dokumentacji opisującej sposób jej programowania, zdecydowano się
na wykorzystanie płytki laboratoryjnej zawierającej 8-bitowy mikrokontoler AT89S52 (Rys. 1).

Oprócz samego mikrokontolera, na płytce znajduje się również układ XC9536XL CPLD służący do generowania sygnałów
sterujących i debugowych umożliwających komunikację z komputerem PC. Mikrokontoler jest w stanie
sterować sygnałami generowanymi PLD, jak również jego wyprowadzeniami ogólnego przeznaczenia (na rysunku
zaznaczonymi jako złącza płytki wyświetlacza), za pośrednictem obecnej na płytce pamięci RAM znajdującej się w
przestrzeni zewnętrznej pamięci danych mikrokontrolera.

#figure(
  image("images/pasted_20260130_164758.png", width: 100%),
  caption: [Płytka laboratoryjna z mikrokontrolerem AT89S52.],
)

== Mikrokontroler

Obecny na płytce 8-bitowy mikrokontroler AT89S52 to przedstawieciel popularnej rodziny MCS-51 (8051) implementujących
architekturę CISC. Wyposażony jest on w 8KB pamięci Flash i 256B wewnętrzenej pamięci RAM. Umożliwia on
również adresowanie do 64KB zewnętrznej pamięci programu/danych. @at89s52

=== Programowanie

Program pisany był w asemblerze, a jego wgrywanie możliwe było dzięki obecności w pamięci programu
mikrokontrolera firmware'u określanego jako _Monitor_. Współpracuje on z oprogramowaniem _Keil µVision_
uruchamianym na komputerze PC, który oprócz asemblacji, linkowania i ładowania programu użytkownika, pozwala
również na debugowanie tegoż programu, tj. jego krokowe wykonywanie oraz podglądanie zawartości pamięci, co
jest kluczowe do weryfikacji poprawnego działania programu. @keil-software

== Stanowisko pomiarowe

Pomiar poboru prądu zrealizowany został poprzez pomiar spadku napięcia (proporcjonalnego do pobieranego prądu)
na rezystorze 10 Ω wpiętym szeregowo w linię zasilania mikrokontrolera. Niestety płytka laboratoryjna nie
posiada żadnego złącza umożliwiającego dołączenie rezystora w ten sposób, dlatego koniecznym okazało
się odlutowanie nóżki zasilania mikrokontolera i podłączenie jej do końcówki rezystora, do którego z drugiej
strony dołączono źródło zasilania (Rys. 2). Dodatkowo pomiędzy źródło zasilania a masę
układu dołączono równolegle kondensator w celu filtrowania składowej zmiennej zasilania mogącej wpływać na
stabilność pracy mikrokontrolera. Całość przedstawiono na schemacie blokowym (Rys. 3).

W toku pracy nad projektem korzystano również z wyjść ogólnego przeznaczenia, którymi mikrokontroler sterował w
celu sygnalizowania operacji (mnożenia lub podnoszenia do kwadratu) wykonywanej w danym momencie.

#figure(
  image("images/pasted_20260130_191112.png", width: 80%),
  caption: [Stanowisko pomiarowe.],
)

#figure(
  image("images/pasted_20260205_200816.png", width: 80%),
  caption: [Schemat połączenia układu pomiarowego.],
)

= Algorytm

Badany asymetryczny algorytm kryptograficzny, czyli protokół Diffiego-Hellmana @diffie-hellman w toku
działania kilkukrotnie wymaga przeprowadzenia operacji potęgowania modularnego. Standardową metodą potęgowania
skracającą liczbę mnożeń jest metoda _square-and-multiply_ polegająca na przypisaniu początkowego wyniku
równego 1 i wykonywaniu podnoszenia do kwadratu dla każdego kolejnego bitu wykładnika, a jeśli obecny bit ma
wartość 1, to dodatkowo wynik jest przemnażany przez podstawę.

#align(center,
[
  *```text
  Funkcja: Square-and-Multiply
  ```*
  ```
  Wejście: x, e
  Wyjście: x^e

  wynik = 1
  while x > 0:
    wynik = wynik · wynik
    if x & 1:
      wynik = wynik · x
    x = x >> 1
  return wynik
  ```
])

Jednak w badanym algorytmie wykonywane jest potęgowanie modulo, co oznacza, że po każdej operacji podnoszenia
do kwadratu lub mnożenia musi zostać wykonana czasochłonna operacja redukcji modulo. Z tego powodu
wykorzystano niezwykle popularny we współczesnej kryptografii algorytm mnożenia Montgomery'ego @mont-mul.

== Mnożenie Montgomery'ego

Algorytm mnożenia Montgomery'ego znajduje zastosowanie w sytuacji, gdy wiele mnożeń ma być wykonanych względem
tego samego modułu _n_ (w operacji modulo). Istotą algorytmu redukcji Montgomery'ego jest umożliwienie
obliczenia k-bitowego wyniku _z_ poprzez zastąpienie dzielenia przez _n_ dzieleniem przez dowolną liczbę _R_,
która jest względnie pierwsza z _n_. W praktyce liczba _R_ jest potęgą liczby 2, co sprawia, że wartości
dzielone są przez 2, co można łatwo przeprowadzić poprzez przesunięcie bitowe. Fakt, że _R_ ma postać _2^k_
pozwala również na spełnienie wymaganego w algorytmie warunku _nwd(R, n) = 1_, ponieważ w większości
przypadków _n_ jest liczbą nieparzystą (ze względu na trudność faktoryzacji liczb nieparzystych), czyli zawsze
będzie względnie pierwsza z potęgą liczby 2.

Jako że jednym z celów tego algorytmu jest wyeliminowanie konieczności wykonywania operacji modulo (czyli
dzielenia), to nie ma sensu jego stosowanie, gdy liczba mnożeń (względem tego samego modułu) jest niska.
Wynika to z faktu, że sama operacja transformacji (argumentów wejściowych do przestrzeni _n-reszt_ i wyniku
z przestrzeni _n-reszt_ do przestrzeni liczb naturalnych) wymaga operacji modulo, co sprawia, że standardową
operację modulo i tak trzeba przeprowadzić przynajmniej trzykrotnie.

W załączonym artykule @mont-mul przedstawiona jest również wersja algorytmu zoptymalizowana pod kątem użycia
jej na standardowym mikroprocesorze działająca na poziomie bitów, co umożliwia wyeliminowanie konieczności
korzystania ze sprzętowej instrukcji mnożenia.

To właśnie ta wersja została początkowo zaimplementowana w programie tworzonym w ramach realizacji projektu.
Jednak z punktu widzenia celu projektu jest to sytuacja niekorzystna, ponieważ sprawia ona, że operacje
mnożenia i podnoszenia do kwadratu stają się technicznie tymi sami działaniami z różnymi argumentami
wejściowymi. Co za tym idzie, zastosowanie algorytmu Montgomery'ego w tej postaci sprawia, że wykonywany
asymetryczny algorytm kryptograficzny staje się niepodatny na prosty atak mocy.

W celu zauważenia różnicy pomiędzy operacjami należałoby zaimplementować wersję algorytmu operującą na słowach
(a nie na bitach) i na dużych liczbach, tj. takich, których rozmiar przekracza rozmiar słowa procesora,
ponieważ w takiej sytuacji, w celu obliczenia wyniku mnożenia, trzeba przemnażać przez siebie kolejne słowa
składowe (o rozmiarze równym rozmiarowi słowa procesora) liczb i na bieżąco je sumować. W przypadku
podnoszenia do kwadratu mnożone byłyby ze sobą dwie te same liczby, dzięki czemu możliwe byłoby pominięcie
niektórych mnożeń, a zamiast tego dodanie ich dwukrotnie do bieżącego wyniku. Ponadto, im większy rozmiar
liczb, tym stosunkowa liczba mnożeń, które można pominąć rośnie, dzięki czemu różnica pomiędzy
operacją mnożenia a operacją podnoszenia do kwadratu staje się bardziej zauważalna.

Warto również wspomnieć, że istnieją różne wersje wykonywania algorytmu Montgomery'ego, które optymalizują ten
algorytm w przypadku działania na dużych liczbach. @mont-mul-ext

= Oprogramowanie

== Założenia działania

Program docelowo miał posiadać tryb prezentacji różnicy pomiędzy operacjami mnożenia i podnoszenia do
kwadratu. Jedna sonda oscyloskopu miała zostać dołączona pomiędzy pin zasilania mikrokontrolera i dołączony
rezystor, a masa oscyloskopu miała być podłączona do drugiej końcówki rezystora, dzięki czemu na oscylokopie
byłby widoczny przebieg spadku napięcia na rezystorze proporcjonalny do poboru prądu przez mikrokontroler.\
Dodatkowo dwie inne sondy oscyloskopu miały być dołączone do pinów GPIO sygnalizujących wykonywaną operację.

W programie miał się również znaleźć tryb umożliwiający przeprowadzenie uczestnikom laboratorium prostego
ataku mocy. W jednej wersji miał to być po prostu określony ciąg mnożeń i podnoszeń do kwadratu reprezentujący
pewną liczbę binarną, dla którego bit o wartości 0 to samo podniesienie do kwadratu, a bit o wartości 1 to
dodatkowo mnożenie. W drugiej wersji byłoby to uruchomienie przeprowadzenia protokołu Diffiego-Hellmana,
dzięki czemu uczestnicy laboratorium mogliby spróbować odczytać wartość klucza prywatnego i tym samym, znając
wartość klucza publicznego, obliczyć wartość dzielonego sekretnego klucza.

= Obserwacje

Jak wspomniano wcześniej, zaimplementowana wersja mnożenia Montgomery'ego powoduje, że operacje mnożenia i
podnoszenia do kwadratu stają się technicznie tymi samymi operacjami, więc nie widać pomiędzy nimi różnicy w
poborze prądu, co przedstawiono na rysunku 4.

#figure(
  image("images/pasted_20260201_173015.png", width: 100%),
  caption: [Wizualizacja poboru prądu (jako spadek napięcia na rezystorze) dla różnych operacji w przypadku
  zaimplementowanej wersji algorytmu Montgomery'ego. Stan wysoki sygnału niebieskiego oznacza wykonywanie
  podnoszenia do kwadratu, a stan niski oznacza wykonywanie mnożenia.],
)

W toku pracy nad projektem sprawdzono również wersję przeprowadzania algorytmu kryptograficznego bez
korzystania z algorytmu Montgomery'ego. W porównaniu do algorytmu Montgomery'ego, wymaga to przeprowadzania
operacji modulo po każdej operacji mnożenia i podnoszenia do kwadratu. W takiej sytuacji, nawet w przypadku
istnienia zauważalnej różnicy pomiędzy operacjami mnożenia i dzielenia (wzrastającej wraz z rozmiarem
wielkości liczb ze względu na możliwość pomijania mnożeń przy podnoszeniu do kwadratu), narzut związany z
działaniem modulo jest tak duży, że przeprowadzenie prostego ataku mocy byłoby niemożliwe. Przypadek ten
przedstawiono na rysunku 5.

#figure(
  image("images/pasted_20260201_174916.png", width: 100%),
  caption: [Porównanie czasu trwania standardowej  operacji mnożenia (tj. wykorzystującej
  sprzętową instrukcję mnożącą) i operacji modulo. Stan wysoki sygnału na kanale CH1 symbolizuje wykonywanie
  mnożenia, a na kanale CH2 wykonywanie operacji modulo.],
)

Ze względu na fakt, że ostatecznie nie zdążono zaimplementować odpowiedniej wersji algorytmu Montgomery'ego,
zdecydowano się uruchomić program z wykorzystaniem funkcji-atrapy liczącej modulo, czyli takiej jej wersji,
która co prawda nie zwraca poprawnej wersji, ale w porównaniu do prawidłowego algorytm jest na tyle skrócona,
że umożliwia obserwację różnic pomiędzy operacjami mnożenia i podnoszenia do kwadratu. Dzięki temu możliwe
jest przekonanie się, jak w rzeczywistości mógłby wyglądać przebieg podatny na prosty atak mocy. Sytuację tę
przedstawiono na rysunku 6.

#figure(
  image("images/pasted_20260201_174916.png", width: 100%),
  caption: [Przebieg napięcia na rezystorze umożliwiający wychwycenie różnic pomiędzy operacjami mnożenia i
  podnoszenia do kwadratu.  Stan wysoki sygnału zielonego symbolizuje wykonywanie mnożenia, a
  stan wysoki sygnału niebieskiego wykonywanie operacji modulo.],
)

#pagebreak()
= Instrukcja uruchomienia

Poniżej przedstawiono zbiorczą instrukcję do zaprogramowania mikrokontrolera i podłączenia układu pomiarowego.

+ Na komputerze z systemem Windows pobrać środowisko _Keil µVision_ @keil-software.

+ Podłączyć układ (wraz z sondami osyloskopu) wg. schematu na rysunku 3. Można również zasugerować się
  rysunkiem 2.

+ Podłączyć płytkę laboratoryjną do komputera za pomocą kabla USB, a następnie podłączyć płytkę do zasilania.

+ Dla wygody utworzyć folder projektowy np. o nazwie *wbik-spa*, a w środowiku _Keil_ utworzyć nowy projekt
  (`Project → New µVision Project`), np. pod nazwą *wbik-spa.uvproj* w folderze projektowym, po czym w oknie
  wyboru urządzenia wyszukać i wybrać AT89S52 [Rys. 7]. W przypadku pojawienia się pytania o przekopiowanie
  pliku *STARTUP.A51*, wybrać odpowiedź negatywną.

+ Dodać wybrany plik źródłowy do projektu (np. *main.asm*). W tym celu należy najpierw otworzyć plik w
  środowisku (`File → Open`), a następnie dodać go do grupy źródłowej poprzez kliknięcie PPM na _Source Group
  1_ w oknie _Project_ i wybranie opcji _Add Existing Files to Group 'Source Group 1'_ i wybranie
  odpowiedniego pliku [Rys. 8].

+ Uruchomić kompilację i linkowanie projektu (ikona _Build_; klawisz skrótu _F7_).

+ W menedżerze urządzeń systemu Windowds sprawdzić, do którego portu COM zostało przypisane urządzenie.

+ W środowisku _Keil_ skonfigurować port COM przypisany do podłączonej płytki. W tym celu należy wybrać z
  głównego menu `Project → Options for Target → Target 1`, w oknie z ustawieniami wybrać zakładkę _Debug_ i
  zaznaczyć opcję _Use_, a z listy rozwijanej obok wybrać _Keil Monitor-51 Driver_. Następnie kliknąć przycisk
  _Settings_ i ustawić odpowiedni port COM [Rys. 9].

+ Uruchomić oscyloskop i włączyć kanały 1-3.

+ [Polecenie dotyczące ustawienia skal dla sygnałów.]

+ W środowisku _Keil_ załadować program poprzez wybranie ikony _Debugging on/off_ i uruchomić go w trybie
  pracy z pełną prędkością (ikona _Run_; klawisz skrótu _F5_). Może być konieczne kilkukrotne uruchomienie
  wykonywania programu ze względu na domyślnie ustawiany przez _Monitor firmware_ breakpoint. Przy ładowaniu
  programu do mikrokontrolera konieczne może być również zresetowanie układu - w tym celu najlepiej
  przytrzymać przycisk resetu na płytce przez kilka sekund i puścić go w momencie zaakceptowania komunikatu,
  który pojawia się po kliknięciu ikony _Debugging on/off_.

+ Wstrzymać rejestrowanie przebiegu na oscyloskopie i przejść do analizy uzyskanych przebiegów.

Wyjścia GPIO sterowane są według następującego schematu:
- GPIO1: stan wysoki oznacza wykonywanie podnoszenia do kwadratu;
- GPIO2: stan wysoki oznacza wykonywanie operacji modulo;
- GPIO3: stan wysoki oznacza wykonywanie mnożenia.

#figure(
  image("images/pasted_20260205_163110.png", width: 75%),
  caption: [Okno wyboru mikrokontrolera.],
)

#figure(
  image("images/pasted_20260205_164204.png", width: 65%),
  caption: [Opcja umożliwiająca dodawanie plików do projektu.],
)

#figure(
  image("images/pasted_20260205_165100.png", width: 75%),
  caption: [Zakładka _Debug_ okna _Options for Target_ oraz okno _Target Setup_ umożliwiające wybór portu COM.],
)

#pagebreak()
= Fragmenty kodu

Poniżej przedstawiono najistotniejsze z punktu widzenia działania programu funkcje. Działają one na
wartościach 16-bitowych. W tabeli 1 zamieszczono ich krótkie opisy, a w samym kodzie również zawarte są opisy
samych funkcji, jak również operacji składowych przez nie wykonywanych.

#figure(
  table(
    columns: (auto, 1fr),
    inset: 10pt,
    align: horizon,
    table.header(
      [*Funkcja*], [*Opis*],
    ),
    [ `montgomery_convert_in16` ],
    [
      Realizuje konwersję liczby do przestrzeni Montgomery'ego (dziedziny m-reszt).
    ],
    [ `montgomery_convert_out16` ],
    [
      Realizuje konwersję liczby z przestrzeni Montgomery'ego z powrotem do dziedziny liczb naturalnych.
    ],
    [ `montgomery_convert_pro16` ],
    [
      Realizuje mnożenie liczb przeniesionych do dziedziny m-reszt za pomocą algorytmu Montgomery'ego.
    ],
    [ `montgomery_convert_mul16` ],
    [
      Oblicza modulo iloczynu dwóch liczb z dziedziny liczb naturalnych z wykorzystanim powyższych funkcji.
    ],
    [ `mod_exp16` ],
    [
      To funkcja najwyższego poziomu, która w celu obliczenia wyniku potęgowania modulo wykorzystuje pozostałe
      funkcje. Zawiera ona również sterowanie wyjściami GPIO w celu sygnalizowania obecnie wykonywanej
      operacji.
    ],
  ),
  supplement: [Tabela],
  caption: [Opis najistotniejszych funkcji.],
  placement: none
)

W celu łatwej identyfikacji liczb przeniesionych do przestrzeni Montgomery'ego (dziedziny m-reszt), zapisywane
są one z przedrostkiem `_`. Ponadto w opisach funkcji, zmienne wielkoliterowe (np. _A_hi_, _A_lo_) służą do
opisu ogólnej definicji działania wykonywango przez funkcję, a zmienne małoliterowe (np. _a_hi_, _a_lo_) to
adresy pamięci.

<montgomery_convert_in16>
```asm
;-----------------------------------------
; Przekształć liczbę 16-bitową do przestrzeni Montgomery'ego (dziedziny m-reszt).
; A * R mod M, gdzie R = 2^k i k - liczba bitów liczby M
; In:   R4:R3:R2:R1 = 0:0:A_hi:A_lo
;       m_hi:m_lo
; Out:  R2:R1 = _(A_hi:A_lo)
;-----------------------------------------
montgomery_convert_in16:
    ; zapisz liczbę bitów modułu do R7
    push    1
    push    2
    mov     R1, m_lo
    mov     R2, m_hi
    lcall   get_bit_cnt16
    pop     2
    pop     1
    mov     R7, A

    mov     R3, #0
    mov     R4, #0

    shift_loop_mont:
    mov     sl_0, R1
    mov     sl_1, R2
    mov     sl_2, R3
    mov     sl_3, R4
    lcall   shiftleft32
    mov     R1, sl_0
    mov     R2, sl_1
    mov     R3, sl_2
    mov     R4, sl_3

    djnz    R7, shift_loop_mont

    lcall   mod32_16
    mov     R1, rem_lo
    mov     R2, rem_hi

    ret
```

<montgomery_convert_out16>
```asm
;-----------------------------------------
; Przekształć liczbę 16-bitową z przestrzeni Montgomery'ego do przestrzeni liczb naturalnych.
; In:   R2:R1 = _(A_hi:A_lo)
;       m_hi:m_lo
; Out:  R2:R1 = A_hi:A_lo
;-----------------------------------------
; Uwaga:
; Przekształcenie Montgomery'ego zachowuje wartości modulo M.
; Z tego powodu wywołanie convert_out(convert_in(a)) zwróci wartość a mod M,
; a nie oryginalną wartość liczby, jeśli jest ona większa-równa od M (a >= M).
;-----------------------------------------
montgomery_convert_out16:
    mov     a_lo, R1
    mov     a_hi, R2
    mov     b_lo, #01h
    mov     b_hi, #00h
    lcall   montgomery_pro16
    mov     R1, result_0
    mov     R2, result_1

    ret
```

<montgomery_pro16>
```asm
; ---------------------------------------------------------
; Oblicz iloczyn Montgomery'ego dwóch liczb 16-bitowych przekstałconych do dziedziny m-reszt.
; _U = _A * _B * R⁻¹ (mod M)
; In:   a_hi:a_lo
;       b_hi:b_lo
;       m_hi:m_lo
; Out:  result_1:result_0 = _U
; ---------------------------------------------------------
montgomery_pro16:
    push    0
    push    1
    push    2
    push    3
    push    4
    push    5
    push    7

    ; przypisz do wyniku wartość początkową 0
    mov     result_0, #0
    mov     result_1, #0
    mov     result_2, #0

    ; zapisz liczbę bitów modułu do R7
    push    1
    push    2
    mov     R1, m_lo
    mov     R2, m_hi
    lcall   get_bit_cnt16
    pop     2
    pop     1
    mov     R7, A

    mont_loop:

    ; if (A & 1) result += B
    ; -----------------------
    mov     A, a_lo
    anl     A, #01h
    jz      skip_add_b
    ; result += B
    mov     R0, result_0
    mov     R1, result_1
    mov     R2, b_lo
    mov     R3, b_hi
    lcall   add16
    mov     result_0, R4
    mov     result_1, R5
    jnc     no_carry1
    inc     result_2
    no_carry1:

    skip_add_b:

    ; if (result & 1) result += M
    ; ----------------------------
    mov     A, result_0
    anl     A, #01h
    jz      skip_add_m

    ;result += M
    mov     R0, result_0
    mov     R1, result_1
    mov     R2, m_lo
    mov     R3, m_hi
    lcall   add16
    mov     result_0, R4
    mov     result_1, R5
    jnc     no_carry2
    inc     result_2
    no_carry2:

    skip_add_m:

    ; result >>= 1
    ; -------------
    mov     R0, result_0
    mov     R1, result_1
    ; przesuń bit17 na bit16 i bit16 do starszego bajtu wyniku (result_1)
    clr     C
    mov     A, result_2
    rrc     A
    mov     result_2, A
    lcall   shiftright16
    mov     result_0, R0
    mov     result_1, R1

    ; A >>= 1
    ; --------
    clr     C
    mov     R0, a_lo
    mov     R1, a_hi
    lcall   shiftright16
    mov     a_lo, R0
    mov     a_hi, R1

    clr     C ; wyczyść flagę Carry po każdej iteracji
    djnz    R7, mont_loop

    ; if result >= M then result -= M
    ; -------------------------------
    mov     R0, result_0
    mov     R1, result_1
    mov     R2, m_lo
    mov     R3, m_hi
    lcall   cmp16_ge
    jz      montgomery_pro16_done

    lcall   sub16 ; końcowy wynik w R5:R4
    mov     result_0, R4
    mov     result_1, R5

    montgomery_pro16_done:
    pop     7
    pop     5
    pop     4
    pop     3
    pop     2
    pop     1
    pop     0
    ret
```

<montgomery_mul16>
```asm
; ---------------------------------------------------------
; Oblicz iloczyn dwóch liczb 16-bitowych modulo M wykorzystując algorytm Montgomery'ego.
; U = A * B (mod M)
; In:   R2:R1 = A_hi:A_lo
;       R4:R3 = B_hi:B_lo
;       m_hi:m_lo
; Out:  R6:R5 = U_hi:U_lo
;-----------------------------------------
; Uwaga:
; Algorytm Montgomery'ego wymaga, aby R i M były względnie pierwsze,
; tj. nwd(R, M) = nwd(2^k, M) = 1. Warunek jest spełniony, jeśli n jest nieparzyste.
;-----------------------------------------
montgomery_mul16:
    ; przenieś A do dziedziny m-reszt i zapisz do R2:R1 (R2:R1 = _A)
    push    3
    push    4
    lcall   montgomery_convert_in16
    pop     4
    pop     3

    ; przenieś B do dziedziny m-reszt i zapisz do R4:R3 (R4:R3 = _B)
    push    1
    push    2
    mov     A, R3
    mov     R1, A
    mov     A, R4
    mov     R2, A
    push    3
    push    4
    lcall   montgomery_convert_in16
    pop     4
    pop     3
    mov     A, R1
    mov     R3, A
    mov     A, R2
    mov     R4, A
    pop     2
    pop     1

    ; _U = MonPro(_A,_B)
    mov     a_lo, R1
    mov     a_hi, R2
    mov     b_lo, R3
    mov     b_hi, R4
    lcall   montgomery_pro16

    ; _U -> U
    ; przenieś _U do dziedziny liczb naturalnych i zapisz do R6:R5 (R6:R5 = U)
    push    1
    push    2
    mov     R1, result_0
    mov     R2, result_1
    lcall   montgomery_convert_out16
    mov     A, R1
    mov     R5, A
    mov     A, R2
    mov     R6, A
    pop     2
    pop     1

    ret
```

<mod_exp16>
```asm
; ---------------------------------------------------------
; Oblicz potęgę modulo liczby 16-bitowej (gdzie wykładnik i moduł również są 16-bitowe).
; X = A^e mod M
; In:   R2:R1 = A_hi:A_lo
;       R4:R3 = E_hi:E_lo
;       m_hi:m_lo
; Out:  R6:R5 = X_hi:X_lo
;-----------------------------------------
mod_exp16:
    ; ustaw stan wysoki na GPIO0
    mov     DPTR, #GPIO_ext
    mov     A, #01h
    movx    @DPTR, A

    ; 1) _a = mont_convert_in(a, m)
    ; -----------------------
    push    3
    push    4
    lcall   montgomery_convert_in16
    pop     4
    pop     3

    ; 2) _x = mont_convert_in(1, m)
    ; -----------------------
    push    1
    push    2
    mov     R1, #01h
    mov     R2, #00h
    push    3
    push    4
    lcall   montgomery_convert_in16
    pop     4
    pop     3
    mov     A, R1
    mov     x_lo, A
    mov     A, R2
    mov     x_hi, A
    pop     2
    pop     1

    ; 3) n_bits = get_bits_cnt(e)
    ; -----------------------
    push    1
    push    2
    mov     A, R3
    mov     R1, A
    mov     A, R4
    mov     R2, A
    lcall   get_bit_cnt16
    pop     2
    pop     1
    mov     R7, A
    jz      modexp_exp_zero

    ; 4) square and multiply loop
    ; -----------------------
    mod_exp_loop:
    ; ustaw stan wysoki na GPIO0-2
    mov     DPTR, #GPIO_ext
    mov     A, #07h
    movx    @DPTR, A

    ; _x = mont_pro(_x, _x, m)
    ; -----------------------
    mov     a_lo, x_lo
    mov     a_hi, x_hi
    mov     b_lo, x_lo
    mov     b_hi, x_hi
    lcall   montgomery_pro16
    mov     x_lo, result_0
    mov     x_hi, result_1

    ; ustaw stan niski na GPIO2 i utrzymaj stan wysoki na GPIO0-1
    mov     DPTR, #GPIO_ext
    mov     A, #03h
    movx    @DPTR, A

    ; sprawdź bit wykładnika
    push    1
    push    2
    mov     A, R3
    mov     R1, A
    mov     A, R4
    mov     R2, A
    mov     A, R7
    dec     A
    lcall   get_bit32
    pop     2
    pop     1
    jz      skip_mul_a

    ; ustaw stan wysoki na GPIO3 i utrzymaj stan wysoki na GPIO0-1
    mov     DPTR, #GPIO_ext
    mov     A, #0Bh
    movx    @DPTR, A

    ;_x = mont_pro(_a, _x, m)
    ; -----------------------
    mov     a_lo, R1
    mov     a_hi, R2
    mov     b_lo, result_0
    mov     b_hi, result_1
    lcall   montgomery_pro16
    mov     x_lo, result_0
    mov     x_hi, result_1

    ; ustaw stan niski na GPIO1,3 i utrzymaj stan wysoki na GPIO0
    mov     DPTR, #GPIO_ext
    mov     A, #01h
    movx    @DPTR, A

    skip_mul_a:
    djnz    R7, mod_exp_loop

    ; 5) x = mont_convert_out(_x, m)
    ; -----------------------
    modexp_exp_zero:
    push    1
    push    2
    mov     R1, x_lo
    mov     R2, x_hi
    lcall   montgomery_convert_out16
    mov     A, R1
    mov     x_lo, A
    mov     A, R2
    mov     x_hi, A
    pop     2
    pop     1

    mov     R5, x_lo
    mov     R6, x_hi

    ; ustaw stan niski na GPIO0-1
    mov     DPTR, #GPIO_ext
    mov     A, #0
    movx    @DPTR, A

    ret
```

#bibliography("works.yml", title: [Bibliografia])
