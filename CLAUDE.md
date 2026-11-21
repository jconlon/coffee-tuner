# coffee-tuner

This folder holds data files, tools and notes for dialing in espresso with several different coffee beans. The work is mostly data analysis and advice. It is not a software product.

## Purpose

- Track espresso shots for each bean and work out the best recipe for each (dose, grind, yield, time, temperature, pre-infusion).
- Suggest one change at a time for the next shot, based on logged results and taste notes.
- Keep a short record of the best recipe for each bean so it can be repeated.

## Equipment

### Logging: Beanconqueror (Android)
App: https://beanconqueror.com/
- Shots are logged in the **Beanconqueror** app, which is connected to a **Bluetooth scale**. The scale records the weight curve and flow during the shot.
- The app runs on an **Android tablet** (package `com.beanconqueror.app`). The data stays on the tablet, because the app has no cloud sync.
- Data comes into this folder over **adb**, driven by `just` tasks (see "Getting data off the tablet" below).
- Beanconqueror records **beans** (roaster, roast date, origin, process), **brews** (grind setting, dose in, yield out, brew time, temperature, rating, notes) and **flow profiles** from the scale.
- Treat export files as source data. Never edit them in place. Put derived or cleaned data in separate files.

### Espresso machine: MiiCoffee Apex V2
Product page: https://miicoffee.shop/products/miicoffee-apex-espresso-machine
- 550 ml stainless brew boiler with **PID**. The brew temperature can be set from **85–102 °C**.
- Separate thermoblock for steam, with its own PID.
- Vibratory pump that targets 9 bar. It has a **pressure gauge** and an **OPV**, so the maximum brew pressure can be adjusted.
- **Pre-infusion can be set** (water amount and time).
- Built-in **shot timer** and a 3-way solenoid valve, which leaves the puck dry.
- **58 mm** portafilter. The machine ships with single and double baskets.
- The product page does not list pressure or flow profiling. Do not assume either is available.
- Warm-up takes about 5 minutes according to the maker. For consistent shots, let the group heat up longer than that.

### Grinder: DF64 Gen 2 (single dose)
Product page: https://df64coffee.com/products/df64-gen-2-single-dose-coffee-grinder
- 64 mm flat burrs. Grind adjustment is **stepless** using a numbered dial.
- Single-dose workflow: weigh the beans, grind everything, use the bellows to purge what is left in the grinder.
- Dial numbers are **relative to this grinder's zero point** (where the burrs touch). They do not carry over to another DF64. Record the grind setting exactly as the dial reads (for example `12.5`), and note any re-zeroing or burr change in `notes/equipment-log.md`.
- Finer grind means a lower number, which slows the shot. Coarser grind means a higher number, which speeds it up.

> The grinder specs above are general DF64 Gen 2 knowledge, not read from the product page (the page could not be fetched). Check them against this unit before relying on them.

## Dial-in method

Starting recipe for a 58 mm double basket, unless the bean's notes say otherwise:
- **Dose:** 18 g (match the basket's rated size)
- **Ratio:** 1:2, so about 36 g out
- **Time:** 25–32 s from pump start (say whether pre-infusion time is included)
- **Temperature:** 93 °C. Go hotter (94–96 °C) for light roasts and cooler (90–92 °C) for dark roasts.
- **Pressure:** 9 bar on the gauge

Rules:
1. **Change one variable per shot.** Most of the time that variable is the grind.
2. Adjust in this order: **grind → ratio/yield → temperature → pre-infusion → dose**.
3. Base each decision on taste:
   - Sour, thin or salty means under-extracted. Grind finer, increase the yield, or raise the temperature.
   - Bitter, harsh or drying means over-extracted. Grind coarser, decrease the yield, or lower the temperature.
   - Channeling (spurting, a fast or uneven flow curve) points to puck prep (WDT, level tamp, distribution), not grind.
4. Account for roast age. Beans are usually best 7–21 days after roasting for espresso. Expect the grind to drift finer as beans age.
5. When the shot curve and the taste disagree, go with the taste and note the disagreement.

## What Claude should do here

- When new exports arrive, parse them and summarize recent brews per bean: grind, ratio, time, temperature, rating, and flow behavior.
- Recommend the **next shot** with one specific change and the reason for it.
- Keep `beans/<bean-slug>.md` current with: bean details, roast date, the best recipe so far, and a short dial-in history.
- Flag outliers such as a dose that does not match the basket, an unusual flow curve, or a missing roast date.
- Use charts (the easel chart tool, if available) to show grind against time, ratio or rating across shots.
- Do not invent shot data. If a value is missing from the export, say so.

## Layout

```
data/raw/<timestamp>/  # Beanconqueror exports, untouched, gitignored (one folder per import)
data/derived/          # beans.csv, brews.csv (`just parse`), shots.csv (`just flows`)
beans/                 # one markdown file per bean: details + best recipe + history
notes/                 # equipment-log.md (grinder zero, OPV, baskets), technique notes
scripts/               # nushell scripts (lib.nu holds shared helpers)
justfile               # tasks wired to scripts
devbox.json            # just, nushell, unzip, android-tools (adb)
```

## Getting data off the tablet

Beanconqueror writes two kinds of export:

| Kind | Where on the tablet | Contents |
|------|---------------------|----------|
| Automatic daily backup | `/sdcard/Android/data/com.beanconqueror.app/files/Download/Beanconqueror_export/Beanconqueror_automatic_export_DD_MM_YYYY.zip` (7 days kept) | JSON only: **no flow profiles or photos** |
| Manual full export | `Beanconqueror.zip` in the folder you pick (choose **Download**) | JSON + flow profiles + images |

Make a full export in the app: **Settings → Full export to directory → Download**.

**Main path today: KDE Connect.** This computer has no Bluetooth. Share the export from the tablet to this computer with KDE Connect. It lands in `~/Downloads/Beanconqueror.zip`, and `just inbox` imports and parses the newest copy. The adb tasks below are the alternative.

Seen in a real export (2026-11-21, confirmed in the app source): **Full export to directory** writes `Beanconqueror.zip`, which holds **only JSON**, plus a separate **`brews/` folder** next to it containing `<brew-uuid>_flow_profile.json`, one file per shot. So send **both**: the zip, and the `brews` folder compressed (`brews.zip`) with the tablet's file manager. `just inbox` merges any `brews*.zip` newer than the export into the same import, then runs `parse` and `flows`. Top-level JSON keys: `BEANS, BREWS, MILL, PREPARATION, SETTINGS, VERSION`.

Flow profile files contain **scale data only**: `weight` (`brew_time`, `actual_smoothed_weight`, …) and `realtimeFlow` (`flow_value` in g/s), at about 10 Hz. `pressureFlow` and `temperatureFlow` are empty because the Apex does not report to the app. The scale timer starts when weight is first detected, so "first drip" is about 0 s and pre-infusion is not visible.

**`SETTINGS` holds the Visualizer username and password in plain text.** That is why `data/raw/` is gitignored. Never copy settings into `data/derived/`, notes, or any file that gets committed.

Inside each zip: `Beanconqueror.json`, plus chunk files `Beanconqueror_Brews_N.json` (500 brews each) and `Beanconqueror_Beans_N.json`. `parse.nu` merges the chunk files.

Connecting (one-time setup, then reconnect as needed):
1. On the tablet, turn on Developer options, then **Wireless debugging**. The tablet must be on the same Wi-Fi network as this computer.
2. Tap **Pair device with pairing code**, then run `just tablet-pair <ip:pairport> <code>`.
3. Run `just tablet-connect <ip:port>`, using the port shown on the main Wireless debugging screen, which is different from the pairing port. The address is saved in `.tablet` (gitignored). The port changes when Wireless debugging restarts, so run `tablet-connect` again after that.
4. Or plug in USB with USB debugging on. No pairing is needed.

Then run `just pull`. It uses the newest full export if there is one, otherwise the newest automatic backup (`just pull --auto` always takes the newest). It copies the zip into `data/raw/<timestamp>-full|auto/`, unzips it and runs `parse`.

## Tasks

| Task | What it does |
|------|--------------|
| `just tablet-pair <ip:port> <code>` | Pair with the tablet's Wireless debugging |
| `just tablet-connect <ip:port>` | Connect over Wi-Fi and remember the address |
| `just tablet-status` | Show the connected tablet, its Android version, and whether Beanconqueror is installed |
| `just tablet-list` | List the Beanconqueror export zips on the tablet |
| `just pull [--auto] [--no-parse]` | Pull the newest export into `data/raw/` and parse it |
| `just inbox [--no-parse]` | Import the newest `~/Downloads/Beanconqueror*.zip` (sent with KDE Connect) and parse it |
| `just import <file>` | Import an export that is already on this computer |
| `just parse` | Flatten the newest import into `data/derived/beans.csv` and `brews.csv` |
| `just flows` | Turn flow profiles into `data/derived/shots.csv`: per shot `main_flow_gps` (g/s between 20–80% of the final weight), `flow_cv` (flow steadiness), `flow_spikes` (readings above 2× the mean, a sign of gushing or channeling), `t_to_95pct_s`, `scale_final_g` |
| `just brews [bean] [n]` | Show the last *n* brews, optionally filtered by part of a bean name (e.g. `just brews ethiopia 10`) |
| `just new-bean "<name>"` | Create `beans/<slug>.md` from the template |
| `just beans` | List bean files |

Field names in `scripts/parse.nu` were **checked against a real export** on 2026-11-21: `grind_size` (a string, e.g. `"12.5"`), `grind_weight` (dose), `brew_beverage_quantity` (yield), `brew_time` (s), `brew_temperature` (often 0, meaning not recorded), `rating`, `note`, `bean` (uuid → BEANS), `mill` and `method_of_preparation` (uuids; only one of each: DF64 Gen 2, MiiCoffee Apex V2). Flow curves are summarized by `scripts/flows.nu`.

Data quirks to handle when analyzing:
- The same bean name sometimes appears with a trailing space (`"Apollo"` vs `"Apollo "`). These are separate bean entries, often different bags, so do not merge them blindly.
- Some grind values have typos (`"8. 5"`).
- Some brews are not espresso (e.g. Nestor Lasso at about a 1:15 ratio). Filter by ratio or time before analyzing espresso.

## Tooling conventions

- Dependencies come from **devbox**, and the environment is already active. Do not prefix commands with `devbox run`.
- Write reusable commands as **nushell scripts** in `scripts/` and run them as **`just`** tasks. Do not use bash scripts or inline justfile shell commands.
- Run `just --list` before suggesting how to run something.
