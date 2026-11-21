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
- Data comes into this folder as Beanconqueror exports: the app's backup/export (JSON in a ZIP), plus any CSV or brew-graph exports.
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
data/raw/<timestamp>/  # Beanconqueror exports, untouched (one folder per import)
data/derived/          # beans.csv, brews.csv: flattened by `just parse`
beans/                 # one markdown file per bean: details + best recipe + history
notes/                 # equipment-log.md (grinder zero, OPV, baskets), technique notes
scripts/               # nushell scripts (lib.nu holds shared helpers)
justfile               # tasks wired to scripts
devbox.json            # just, nushell, unzip
```

## Tasks

| Task | What it does |
|------|--------------|
| `just import <file>` | Copy a Beanconqueror export (.zip or .json) into `data/raw/<timestamp>/`, unzipping it if needed |
| `just parse` | Flatten the newest import into `data/derived/beans.csv` and `brews.csv` |
| `just brews [bean] [n]` | Show the last *n* brews, optionally filtered by part of a bean name (e.g. `just brews ethiopia 10`) |
| `just new-bean "<name>"` | Create `beans/<slug>.md` from the template |
| `just beans` | List bean files |

`scripts/parse.nu` assumes the Beanconqueror backup layout (`BEANS`, `BREWS`, and brew fields such as `grind_size`, `grind_weight`, `brew_beverage_quantity`, `brew_time`, `brew_temperature`, `rating`). These names have **not yet been checked against a real export**. Check them against the first real export and fix the script if they differ. Flow-profile data from the scale is not parsed yet.

## Tooling conventions

- Dependencies come from **devbox**, and the environment is already active. Do not prefix commands with `devbox run`.
- Write reusable commands as **nushell scripts** in `scripts/` and run them as **`just`** tasks. Do not use bash scripts or inline justfile shell commands.
- Run `just --list` before suggesting how to run something.
