# coffee-tuner

Notes, data and tools for dialing in espresso, one bag of beans at a time.

Shots are logged in **Beanconqueror** on an Android tablet with a Bluetooth scale. The machine is a MiiCoffee Apex V2 and the grinder is a DF64 Gen 2. Exports go from the tablet to this computer with **KDE Connect**. `just` tasks turn them into CSV files, and Claude uses those to suggest the next shot.

## Where to find the current recipes

**Every bag that is being dialed in has an open GitHub issue labelled `dial-in`.** Each issue holds the bag's **current recipe**, a table of every shot so far, and the next shot to try. That makes the open issues the place to look for the latest recipe for each active bag.

- On GitHub: [open dial-in issues](https://github.com/jconlon/coffee-tuner/issues?q=is%3Aissue+is%3Aopen+label%3Adial-in)
- In the terminal: `gh issue list --label dial-in`, then `gh issue view <n>`

Issue titles look like `Dial-in: <Bean> (<Roaster>, roasted <YYYY-MM-DD>)`. There is one issue per bag, because each bag is a different roast batch. A new bag of the same coffee gets its own issue, starting from the last bag's best recipe.

When a bag is dialed in, the final recipe is posted as a comment on its issue and the issue is closed. The recipe is also copied to **`beans/<coffee>.md`**, which keeps the best recipe and history for that coffee across all of its bags.

## Procedure: after pulling some shots

### 1. Full export in Beanconqueror (tablet)
1. Go to **Settings → Full export to directory** and choose **Download**.
2. This writes `Beanconqueror.zip` (beans, brews, settings) and a `brews/` folder of flow profiles, one file per shot.

### 2. Zip the `brews` folder (tablet)
1. In the file manager, open **Download**.
2. Delete any old `brews.zip`.
3. Long-press `brews`, then choose **Compress** and name it `brews.zip`.

Do this *after* the export, so the zip is newer than `Beanconqueror.zip`.

### 3. Send both files with KDE Connect (tablet → this computer)
1. Share **`Beanconqueror.zip`** first, then **`brews.zip`**.
2. Both land in `~/Downloads`. A rename like `Beanconqueror (1).zip` is fine.

### 4. Import (this computer)
```
just inbox
```
This copies the newest export into `data/raw/<timestamp>-inbox/`, merges in the flow profiles, and rebuilds `data/derived/` (`beans.csv`, `brews.csv`, `shots.csv`).

- `N flow files, N usable, N joined` means the flow curves came through.
- `no brews*.zip newer than this export` means you should re-zip the folder, send `brews.zip` again, and rerun `just inbox`.

### 5. Review and plan the next shot
Ask Claude to review the new shots. For each active bag, Claude:
- posts one comment per attempt on the bag's `dial-in` issue, with the numbers, the flow curve, what it means and the **one change** to make next,
- updates the issue body with the current recipe and the next shot to try,
- opens a new issue when a new bag shows up, and closes the issue (copying the final recipe to `beans/`) when the bag is dialed in.

Then check the open `dial-in` issues for what to pull next.

### Housekeeping
- Before the next export, delete the old `brews/` folder and `brews.zip` on the tablet.
- The export contains your Visualizer password in plain text. It stays in `data/raw/`, which is gitignored. Don't send the zip anywhere else, because this repo is public.

## Tasks

Run `just --list` for the full list.

| Task | Use |
|------|-----|
| `just inbox` | Import the newest export from `~/Downloads` and parse it |
| `just import <file>` | Import an export file from somewhere else on this computer |
| `just parse` / `just flows` | Rebuild the CSVs from the newest import |
| `just brews [bean] [n]` | Show the last *n* shots, e.g. `just brews rwanda 10` |
| `just new-bean "<name>"` | Start a `beans/<slug>.md` file for a new coffee |
| `just beans` | List the bean files |

## Layout

```
beans/          best recipe + history per coffee
notes/          equipment log (grinder zero, OPV, baskets) and technique notes
data/raw/       untouched exports (gitignored, contains app settings)
data/derived/   beans.csv, brews.csv, shots.csv
scripts/        nushell scripts behind the just tasks
```

The dial-in method, the equipment details and the data notes are in `CLAUDE.md`.
