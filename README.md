# Mārketinga un tūrisma nodaļas fokusā — TV dashboard

Viena-faila HTML dashboard biroja ekrānam/TV: kreisajā pusē aktuālie darbi (no
publiska Google Sheets CSV), labajā pusē aktuālās nedēļas kalendāra notikumi
(no ICS faila). Domāts skatīšanai no attāluma, bez peles/tastatūras —
dati atsvaidzinās automātiski.

## Dzīvā versija

Dashboard ir izvietots publiski Namecheap koplietotajā hostingā (cPanel
lietotājs `salibsve`), ar pielāgotu domēnu:

```
https://tablo.saliedeties.lv/
```

Kalendāra dati (`calendar.ics`) automātiski sinhronizējas **tieši serverī**
ar cPanel Cron Job (reizi 5 minūtēs — koplietotā hostinga minimālais
iespējamais intervāls), kas lejupielādē svaigāko ICS no SOGo un pārraksta
failu vietā. Nekāds vietējais dators vai GitHub Actions vairs nav
iesaistīts šajā sinhronizācijā.

cPanel Cron Job komanda (Minute=`*/5`, pārējie=`*`):
```
/usr/bin/curl -s "https://mx.ventspils.lv/SOGo/dav/public/raitis.roze/Calendar/51014-69007300-10D-3EA6D300.ics" -o /home/salibsve/tablo.saliedeties.lv/calendar.ics.tmp && mv /home/salibsve/tablo.saliedeties.lv/calendar.ics.tmp /home/salibsve/tablo.saliedeties.lv/calendar.ics
```
(pilns ceļš `/usr/bin/curl` obligāts — cPanel cron videi nav `curl` PATH bez tā.
Lejupielāde iet uz `.tmp` failu un tikai pēc tam `mv` pārvieto to vietā —
tas ir atomisks, lai dashboard nekad nenolasītu daļēji uzrakstītu failu.)

DNS (`saliedeties.lv`) tiek pārvaldīts **Cloudflare** (NS: bowen.ns.cloudflare.com,
carlane.ns.cloudflare.com — nevis NIC.LV vai Namecheap tieši). `tablo` ieraksts
tur ir tips **A**, vērtība `66.29.132.18` (Namecheap koplietotā IP), proxy
status "DNS only".

### GitHub repo — tikai versiju vēsture

[github.com/raitisroze/marketinga-dashboard](https://github.com/raitisroze/marketinga-dashboard)
satur šo pašu kodu versiju kontrolei, bet **vairs nav dzīvais hostings** —
sākotnēji tika izmantots GitHub Pages + GitHub Actions, taču to plānoto
uzdevumu izpildes kavēšanās (līdz pat ~60 min, nevis konfigurētās 5 min)
bija iemesls pārcelties uz Namecheap ar reālu servera cron. Attiecīgie
GitHub Pages faili (`CNAME`, `.github/workflows/`) tāpēc dzēsti no repo.

### Izvietošana (deploy) pēc izmaiņām

```bash
cd /Users/raitisroze/marketinga-dashboard
./scripts/deploy.sh index.html
```

Skripts izmanto FTPS pieejas datus no `.env.deploy` (gitignored, lokāls
fails, nav repo). `--disable-epsv` karodziņš ir obligāts — bez tā šī servera
FTPS dati savienojums intermitējoši atgriež "451 Transfer aborted" kļūdu.

## Faili

- `index.html` — viss dashboard (HTML + CSS + JS vienā failā, bez build soļa)
- `calendar.ics` — kalendāra dati; servera cron to automātiski pārraksta
  (sk. "Dzīvā versija" augstāk)
- `scripts/deploy.sh` — augšupielādē failus uz Namecheap pa FTPS
- `.env.deploy` — FTPS pieejas dati (gitignored, tikai lokāli)

## Palaišana kiosk režīmā (biroja TV)

Vienkāršākais veids — TV/kiosk pārlūkā tieši atver dzīvo adresi:

```
https://tablo.saliedeties.lv/
```

**Google Chrome kiosk režīmā (Windows/macOS/Linux):**

```bash
google-chrome --kiosk --incognito https://tablo.saliedeties.lv/
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

**Risinājums: automātiska sinhronizācija tieši serverī.** Namecheap cPanel
Cron Job (sk. "Dzīvā versija" augstāk) ik pēc 5 minūtēm lejupielādē svaigāko
ICS no augstāk minētās SOGo saites un pārraksta `calendar.ics` — tā kā abi
(cron un dashboard) darbojas uz tā paša servera/domēna, CORS problēma
vienkārši neparādās.

(Vēsturiski šeit tika izmantots GitHub Actions mākoņa uzdevums, taču GitHub
plānoto uzdevumu izpildes kavēšanās — reizēm līdz ~60 min, nevis
konfigurētās 5 min — bija iemesls pārcelties uz reālu servera cron.)

Ja koplietošana SOGo pusē kādreiz tiktu izslēgta un saite pārstātu strādāt,
`curl` komanda vienkārši neizdosies un `calendar.ics` paliks iepriekšējā
(pēdējā veiksmīgi lejupielādētā) stāvoklī, un dashboard turpinās rādīt
pēdējos veiksmīgi ielādētos datus (sk. "Kļūdu apstrāde" zemāk).

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
