# Mārketinga un tūrisma nodaļas fokusā — TV dashboard

Viena-faila HTML dashboard biroja ekrānam/TV: kreisajā pusē aktuālie darbi (no
publiska Google Sheets CSV), labajā pusē tuvāko 14 dienu kalendāra notikumi
(no ICS faila). Domāts skatīšanai no attāluma, bez peles/tastatūras —
dati atsvaidzinās automātiski.

## Dzīvā versija

Dashboard ir izvietots publiski, hostējot GitHub Pages ([repo:
raitisroze/marketinga-dashboard](https://github.com/raitisroze/marketinga-dashboard)),
ar pielāgotu domēnu:

```
http://tablo.saliedeties.lv/
```

Kalendāra dati (`calendar.ics`) automātiski sinhronizējas mākonī reizi 5
minūtēs ar GitHub Actions ([.github/workflows/sync-calendar.yml](.github/workflows/sync-calendar.yml))
— nekāds vietējais dators (cron u.tml.) vairs nav vajadzīgs šai sinhronizācijai.
Katru reizi, kad `calendar.ics` mainās, GitHub Pages automātiski pārbūvē lapu.

**DNS priekšnoteikums:** `saliedeties.lv` DNS jāpievieno CNAME ieraksts:

```
Nosaukums (host):  tablo
Tips:               CNAME
Vērtība (target):   raitisroze.github.io.
```

Pēc ieraksta pievienošanas DNS izplatās parasti dažu minūšu līdz ~1 stundas
laikā. GitHub pēc tam automātiski izsniedz arī HTTPS sertifikātu (var paiet
līdz pāris stundām) — līdz tam lapa būs pieejama tikai ar `http://`, ne
`https://`.

## Faili

- `index.html` — viss dashboard (HTML + CSS + JS vienā failā, bez build soļa)
- `calendar.ics` — kalendāra dati; GitHub Actions to automātiski pārraksta
  (sk. "Dzīvā versija" augstāk)
- `CNAME` — GitHub Pages pielāgotā domēna konfigurācija
- `.github/workflows/sync-calendar.yml` — mākoņa sinhronizācijas uzdevums

## Palaišana kiosk režīmā (biroja TV)

Vienkāršākais veids — TV/kiosk pārlūkā tieši atver dzīvo adresi:

```
http://tablo.saliedeties.lv/
```

**Google Chrome kiosk režīmā (Windows/macOS/Linux):**

```bash
google-chrome --kiosk --incognito http://tablo.saliedeties.lv/
```

Windows: izmanto `chrome.exe` ceļu (parasti
`C:\Program Files\Google\Chrome\Application\chrome.exe`). Ieteicams arī
pievienot karodziņus `--noerrdialogs --disable-session-crashed-bubble`, lai
neparādītos uzlecošie logi pēc negaidītas restartēšanas.

Lai dashboard palaistos automātiski pēc datora restarta, pievieno šo komandu
autostartā (Windows: Task Scheduler / Startup mape; macOS: Login Items vai
`launchd`; Linux: autostart `.desktop` fails vai `systemd` serviss).

Ekrānam ieteicams atslēgt miega/screensaver režīmu, lai TV nenoslēdzas.

### Alternatīva: lokāla palaišana (izstrādei/testēšanai)

Ja vēlies palaist un testēt lokāli (nevis caur dzīvo adresi), atver failu
caur HTTP(S), nevis tieši kā `file://` — pretējā gadījumā pārlūks bloķēs
datu ielādi (CORS):

```bash
cd /ceļš/uz/marketinga-dashboard
python3 -m http.server 8080
```

Tad atver `http://localhost:8080/index.html`.

## Kā mainīt datu avotus un atsvaidzes intervālu

Visi iestatījumi ir vienuviet faila `index.html` sākumā, sadaļā
`CONFIG = { ... }`:

```js
const CONFIG = {
  CSV_URL: "...",              // publiskā CSV saite (Aktuālie darbi)
  ICS_URL: "calendar.ics",     // kalendāra ICS fails vai saite
  REFRESH_INTERVAL_MS: 5 * 60 * 1000,  // atsvaidzes intervāls (ms)
  CALENDAR_DAYS_AHEAD: 14,     // cik dienas uz priekšu rādīt kalendārā
  AUTOSCROLL_PX_PER_TICK: 1,   // autoscroll ātrums
  AUTOSCROLL_TICK_MS: 40,
  AUTOSCROLL_PAUSE_MS: 3500,   // pauze augšā/apakšā pirms scroll virziena maiņas
  PAGE_RELOAD_INTERVAL_MS: 6 * 60 * 60 * 1000, // pilnas lapas pārlāde reizi N ms
};
```

`PAGE_RELOAD_INTERVAL_MS` liek visai lapai (ne tikai datiem) pilnībā
pārlādēties reizi noteiktā laikā (pēc noklusējuma reizi 6 stundās) — tas ir
atsevišķi no `REFRESH_INTERVAL_MS` (kas atsvaidzina tikai CSV/ICS datus bez
lapas pārlādes). Kiosk ekrāns parasti darbojas nedēļām/mēnešiem bez
restarta, tāpēc periodiska pilna pārlāde pasargā no iespējamas pārlūka
atmiņas noplūdes vai iestrēguša JS stāvokļa ilgtermiņā. Uzstādi uz `0`,
lai šo izslēgtu.

Atver `index.html` jebkurā teksta redaktorā, izmaini vērtības, saglabā un
pārlādē lapu pārlūkā (vai gaidi nākamo automātisko atsvaidzi).

### CSV formāts (Aktuālie darbi)

CSV pirmajā "īstajā" galvenes rindā jābūt kolonnām tieši šādā secībā:
`Datums, Uzdevums, Atbildīgais, Statuss`. Dashboard automātiski atrod šo
rindu, tāpēc virs tās var būt papildu virsraksta/instrukciju rindas (kā
pašreizējā lapā) — tās tiek ignorētas. Rādās tikai rindas ar
`Statuss = "Aktīvs"`, kārtotas hronoloģiski pēc `Datums` (formātā
`YYYY-MM-DD`).

## Kalendāra dati — SVARĪGI

Sākotnēji dotā SOGo kalendāra saite neatgrieza datus (kalendāra publiskā
koplietošana bija izslēgta). Testēšanas laikā koplietošana tika ieslēgta, un
tagad **strādājoša publiskā ICS saite ir atrasta**:

```
https://mx.ventspils.lv/SOGo/dav/public/raitis.roze/Calendar/51014-69007300-10D-3EA6D300.ics
```

Šī saite atgriež standarta ICS tekstu ar visiem kalendāra notikumiem
(pārbaudīts ar reāliem datiem — 678 notikumi, tai skaitā atkārtotie/RRULE
notikumi, korekti parsējas un rādās dashboard).

**Vienīgā problēma: CORS.** Šis SOGo serveris atbildē nesūta
`Access-Control-Allow-Origin` headeri, tāpēc pārlūks bloķē `fetch()`
pieprasījumu tieši uz šo saiti, ja `index.html` tiek atvērts no cita domēna.
Tāpēc dashboard pēc noklusējuma (`CONFIG.ICS_URL = "calendar.ics"`) lasa
kalendāru no **vietēja faila** blakus `index.html`, nevis tieši no SOGo.

**Risinājums: automātiska sinhronizācija mākonī.** Repozitorijā ir GitHub
Actions uzdevums ([.github/workflows/sync-calendar.yml](.github/workflows/sync-calendar.yml)),
kas ik pēc 5 minūtēm (arī manuāli palaižams no repo "Actions" cilnes):

1. Lejupielādē svaigāko ICS no augstāk minētās SOGo saites.
2. Ja lejupielāde izdevusies un fails ir derīgs, pārraksta `calendar.ics`
   repozitorijā un izveido commit.
3. Push uz `main` automātiski izraisa GitHub Pages pārbūvi — nākamajā
   `REFRESH_INTERVAL_MS` reizē (5 min) TV ekrānā parādās jaunākie dati.

Tas darbojas pilnībā GitHub serveros — nav atkarīgs no neviena vietēja
datora vai cron uzdevuma. Uzdevuma vēsture un iespējamas kļūdas redzamas
repo → **Actions** cilnē.

Ja koplietošana SOGo pusē kādreiz tiktu izslēgta un saite pārstātu strādāt,
sinhronizācijas uzdevums paturēs iepriekšējo derīgo `calendar.ics` versiju
(neieraksta tukšu/kļūdainu failu), un dashboard turpinās rādīt pēdējos
veiksmīgi ielādētos datus (sk. "Kļūdu apstrāde" zemāk).

## Kļūdu apstrāde

Ja CSV vai ICS avotu neizdodas ielādēt (tīkla kļūda, servera kļūda u.tml.),
dashboard **nerāda tukšu lapu** — paliek redzami pēdējie veiksmīgi ielādētie
dati, un ekrāna apakšā parādās diskrēts brīdinājums (piem., "⚠ Darbu
saraksts neatjaunojās (14:32) — rāda iepriekšējos datus"). Nākamajā
atsvaidzes reizē (pēc `REFRESH_INTERVAL_MS`) mēģinājums atkārtojas
automātiski.

## Tehniskās piezīmes

- Bibliotēkas ielādētas no CDN (PapaParse CSV parsēšanai, ical.js ICS
  parsēšanai un atkārtoto notikumu (RRULE) izvēršanai) — nepieciešams
  interneta pieslēgums, lai lapa ielādētos pirmo reizi.
- "Aktuālie darbi" un "Kalendārs" saraksti automātiski lēnām autoscrollē
  (uz leju, pauze, uz augšu, pauze...), ja saturs nesatilpst ekrānā —
  manuāla ritināšana nav nepieciešama.
- Nokavēto termiņu (sarkans akcents) un šodienas termiņu (dzeltens/oranžs
  akcents) iezīmējums pārrēķinās reizi minūtē, lai atbilstu pašreizējam
  datumam pat starp CSV atsvaidzes reizēm.
