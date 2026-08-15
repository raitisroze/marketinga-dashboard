# Mārketinga un tūrisma nodaļas fokusā — TV dashboard

Viena-faila HTML dashboard biroja ekrānam/TV: kreisajā pusē aktuālie darbi (no
publiska Google Sheets CSV), labajā pusē tuvāko 14 dienu kalendāra notikumi
(no ICS faila). Domāts skatīšanai no attāluma, bez peles/tastatūras —
dati atsvaidzinās automātiski.

## Faili

- `index.html` — viss dashboard (HTML + CSS + JS vienā failā, bez build soļa)
- `calendar.ics` — demo/vietturis kalendāra dati (sk. "Kalendāra dati" zemāk)

## Palaišana kiosk režīmā

Dashboard jāatver caur HTTP(S), nevis tieši kā `file://` — pretējā gadījumā
pārlūks var bloķēt datu ielādi (CORS). Vienkāršākais veids — atvērt failu no
web servera vai palaist vietējo serveri tajā pašā mapē:

```bash
cd /ceļš/uz/marketinga-dashboard
python3 -m http.server 8080
```

Tad kioskā atver `http://localhost:8080/index.html`.

**Google Chrome kiosk režīmā (Windows/macOS/Linux):**

```bash
google-chrome --kiosk --incognito http://localhost:8080/index.html
```

Windows: izmanto `chrome.exe` ceļu (parasti
`C:\Program Files\Google\Chrome\Application\chrome.exe`). Ieteicams arī
pievienot karodziņus `--noerrdialogs --disable-session-crashed-bubble`, lai
neparādītos uzlecošie logi pēc negaidītas restartēšanas.

Lai dashboard palaistos automātiski pēc datora restarta, pievieno šo komandu
autostartā (Windows: Task Scheduler / Startup mape; macOS: Login Items vai
`launchd`; Linux: autostart `.desktop` fails vai `systemd` serviss).

Ekrānam ieteicams atslēgt miega/screensaver režīmu, lai TV nenoslēdzas.

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

**Vienīgā atlikusī problēma: CORS.** Šis SOGo serveris atbildē nesūta
`Access-Control-Allow-Origin` headeri, tāpēc pārlūks bloķēs `fetch()`
pieprasījumu tieši uz šo saiti, ja `index.html` tiek atvērts no cita domēna
(piem., no vietējā `localhost` servera vai jebkuras citas mājaslapas).
Fetch tieši no `mx.ventspils.lv` domēna (t.i., ja pats dashboard tiktu
izvietots tajā pašā serverī) šo ierobežojumu neskartu.

Tāpēc dashboard pēc noklusējuma (`CONFIG.ICS_URL = "calendar.ics"`) lasa
kalendāru no **vietēja faila** blakus `index.html`, nevis tieši no SOGo —
tas ir gan CORS-drošs, gan ātrāks. Izvēlies vienu no diviem variantiem, lai
šis fails saturētu aktuālus datus:

**A) Ieplāno automātisku sinhronizāciju (ieteicams, jau uzstādīts šajā datorā)**
— uz datora/servera, kur atrodas `index.html`, uzstādi periodisku uzdevumu,
kas pārraksta `calendar.ics` ar svaigiem datiem no strādājošās saites:

```bash
curl -s "https://mx.ventspils.lv/SOGo/dav/public/raitis.roze/Calendar/51014-69007300-10D-3EA6D300.ics" \
  -o /ceļš/uz/marketinga-dashboard/calendar.ics
```

- **macOS/Linux (cron)** — `crontab -e` un pievieno rindu, kas to darbina ik
  minūti (šajā datorā tas jau ir uzstādīts tieši šādi):
  ```
  * * * * * curl -s "https://mx.ventspils.lv/SOGo/dav/public/raitis.roze/Calendar/51014-69007300-10D-3EA6D300.ics" -o /Users/raitisroze/Documents/marketinga-dashboard/calendar.ics
  ```
  Pārbaudi ar `crontab -l`, izmaini ar `crontab -e`, izņem ar
  `crontab -e` un izdzēs attiecīgo rindu.
- **Windows (Task Scheduler)** — izveido uzdevumu, kas ik minūti palaiž
  `curl.exe` (iebūvēts Windows 10/11) ar tiem pašiem parametriem.

Atbilstoši dashboard pats (`CONFIG.REFRESH_INTERVAL_MS` faila `index.html`
CONFIG sadaļā) tagad arī pārbauda `calendar.ics`/CSV ik minūti, lai
sinhronizācijas ātrums un lapas atsvaidze būtu saskaņoti.

**B) Izvieto `index.html` tajā pašā domēnā** (`mx.ventspils.lv`) — tad var
tieši iestatīt `CONFIG.ICS_URL` uz augstāk minēto saiti bez lokālas kopēšanas,
jo tas vairs nebūs starpdomēnu (cross-origin) pieprasījums. Šim variantam
nepieciešama IT palīdzība, lai failu izvietotu tajā serverī.

Ja koplietošana SOGo pusē kādreiz atkal tiktu izslēgta un saite pārstātu
strādāt, dashboard automātiski turpinās rādīt pēdējos veiksmīgi ielādētos
datus (sk. "Kļūdu apstrāde" zemāk) — jāatjauno tikai koplietošana SOGo
saskarnē (kalendārs → "Share"/"Kopīgot" → publiska piekļuve).

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
