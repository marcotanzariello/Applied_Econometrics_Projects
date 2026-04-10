# Plan: Restructure Applied_Econometrics_Projects repository

## Context

The repo has grown organically across 3 weeks. Raw data lives in `datasets/` but is manually copied into `week_x/build/input/` and `week_x/analysis/input/`, creating a 5-step duplication chain. "Puglia" is hardcoded in ~30 places (variable names, filenames, paths), making it hard to pivot the analysis to another region. AI-generated neighborhood scores are buried in `week_2/analysis/input/agents/` instead of being treated as data. The `.gitignore` has inconsistencies (tracked files that match ignore rules).

**Goal**: single source of truth for data, parametrized scripts, clean git state, consistent structure across all weeks.

---

## Step 1 — Crea config per dataset

### 1a. `datasets/airbnb/_config_airbnb.R`
```r
# _config_airbnb.R — parametri dataset Airbnb
REGION     <- "Puglia"
DATA_RAW   <- here::here("datasets", "airbnb", "listings",
                          paste0("listings_", REGION, ".csv"))
DATA_PROC  <- here::here("datasets", "airbnb", "processed")
SCORES_DIR <- here::here("datasets", "airbnb", "neigh_scores")
```

### 1b. `datasets/US_state_year/_config_fatality.R`
```r
# _config_fatality.R — parametri dataset fatality
YEAR_RANGE  <- c(1982, 1988)
DATA_FATAL  <- here::here("datasets", "US_state_year", "fatality.dta")
DATA_PROC   <- here::here("datasets", "US_state_year", "processed")
```

week_1 e week_2: `source(here::here("datasets","airbnb","_config_airbnb.R"))`
week_3+: `source(here::here("datasets","US_state_year","_config_fatality.R"))`

---

## Step 2 — Reorganize `datasets/`

Move AI-generated score CSVs into `datasets/`, add `processed/` dirs:

```
datasets/
├── airbnb/
│   ├── listings/*.csv              (unchanged — 10 cities)
│   ├── neigh_ratings/              (unchanged — Milan)
│   ├── neigh_scores/               (NEW — AI scores moved here)
│   │   ├── puglia_scores_chatgpt.csv
│   │   ├── puglia_scores_gemini.csv
│   │   └── puglia_scores_perplexity.csv
│   └── processed/                  (NEW — all cleaned/derived datasets)
│       ├── listings_puglia_cleaned.rds      (from week_1 build)
│       ├── listings_puglia_week2.rds        (from week_2 build)
│       └── listings_puglia_final.rds        (from week_2 analysis)
└── US_state_year/
    ├── fatality.dta                (unchanged)
    └── processed/                  (NEW — for week_3 outputs)
```

Keep `week_2/analysis/input/agents/` with only the documentation files (prompt.txt, process_*.txt).

---

## Step 3 — Eliminate copy chain, delete redundant input folders

Delete these copies:
- `week_1/build/input/listings_Puglia.csv`
- `week_1/build/output/listings_Puglia_cleaned.rds`
- `week_2/build/input/listings_Puglia_cleaned.rds`
- `week_2/build/output/listings_Puglia_week2_cleaned.rds`
- `week_2/analysis/input/listings_Puglia_week2_cleaned.rds`
- `week_2/analysis/output/datasets/listings_Puglia_final.rds`

Remove empty dirs:
- `week_1/build/input/`
- `week_1/build/output/`
- `week_1/analysis/input/`
- `week_2/build/input/`
- `week_2/build/output/`
- `week_2/analysis/output/datasets/`

Keep `week_2/analysis/input/agents/` (has methodology docs).

**New data flow** (no cross-week dependencies):
```
datasets/airbnb/listings/{region}.csv
  → week_1/build/code reads directly, writes to datasets/airbnb/processed/
    → datasets/airbnb/processed/listings_{region}_cleaned.rds
      → week_2/build/code reads from datasets/airbnb/processed/
        → datasets/airbnb/processed/listings_{region}_week2.rds
          → week_2/analysis/code reads from datasets/airbnb/processed/
            → datasets/airbnb/processed/listings_{region}_final.rds
```

All processed data lives in `datasets/`, eliminating inter-week path dependencies. Each script reads/writes only from `datasets/`.

---

## Step 4 — Refactor R scripts

### 4a. `week_1/build/code/clean_data_task1.R`

- Add `source(here::here("datasets","airbnb","_config_airbnb.R"))`
- Read from `DATA_RAW` direttamente (già definito nel config — non ricostruire il path)
- Rename variables: `listings_Puglia` → `listings_raw`, `listings_Puglia_cleaned` → `listings_cleaned`
- Output to `datasets/airbnb/processed/listings_{tolower(REGION)}_cleaned.rds`

### 4b. `week_1/analysis/code/price_analysis.R`

> ⚠️ Rinominato da `code_analysis_task2345.R` → `price_analysis.R` (vedi Step 9)

- Add `source(here::here("datasets","airbnb","_config_airbnb.R"))`
- Read from `datasets/airbnb/processed/` using REGION in filename
- Rename: `listings_Puglia_cleaned` → `listings_cleaned`
- Keep filter-based names (`listings_acc2`, `listings_acc6`, `neigh_clean`) — they describe logic, not region
- Figures/tables still go to `week_1/analysis/output/`

### 4c. `week_2/build/code/data_prep.R`

- Add `source(here::here("datasets","airbnb","_config_airbnb.R"))`
- Read from `datasets/airbnb/processed/` (no cross-week dependency!)
- Rename: `listings_Puglia_week2` → `listings_base`, `listings_Puglia_week2_r` → `listings_week2`
- Output to `datasets/airbnb/processed/listings_{tolower(REGION)}_week2.rds`

### 4d. `week_2/analysis/code/data_analysis.R`

- Add `source(here::here("datasets","airbnb","_config_airbnb.R"))`
- Read cleaned data from `datasets/airbnb/processed/` using REGION
- Read AI scores from `SCORES_DIR` (già definito nel config) usando `paste0(tolower(REGION), "_scores_", agent, ".csv")`
- Rename: `listings_Puglia_week2_r` → `listings_week2`, `listings_Puglia_final` → `listings_final`
- Output dataset to `datasets/airbnb/processed/listings_{tolower(REGION)}_final.rds`
- Figures/tables still go to `week_2/analysis/output/`

### 4e. `week_3/build/code/data_setup.R`

- Add `source(here::here("datasets","US_state_year","_config_fatality.R"))`
- Read from `DATA_FATAL` (già definito nel config)
- Write processed output to `DATA_PROC` (già definito nel config)

---

## Step 5 — Fix `.gitignore` and git state

### 5a. Update `.gitignore`

- Remove `analysis/output` rule — for a course project, tracking generated figures/tables is fine and makes outputs visible on GitHub
- Keep `CLAUDE.md` in `.gitignore` (user preference)
- Remove `.here` rule (needed by the `here` package)
- Add `datasets/*/processed/` and `datasets/*/*/processed/` (generated artifacts, reproducible from scripts)
- Ensure `.Rhistory` stays ignored

### 5b. Clean tracked files that should be ignored

```bash
git rm --cached week_1/analysis/code/.Rhistory
git rm --cached week_1/build/code/.Rhistory
git rm --cached .Rhistory
```

---

## Step 6 — Set up week_3 scaffold

```
week_3/
├── build/
│   ├── code/data_setup.R      (moved from week_3/build/)
│   └── output/
├── analysis/
│   ├── code/
│   └── output/
│       ├── figures/
│       └── tables/
└── report/
```

Add `.gitkeep` to empty dirs so git tracks them.

---

## Step 7 — Update README.md

Expand the README to document:
- Project description and course context
- Repository structure (the new clean layout)
- Data flow diagram (text-based)
- Note on AI-generated variables (manual process, docs in `week_2/analysis/input/agents/`)

### Come cambiare regione/parametri

- **Analisi Airbnb** (week_1, week_2): modifica `REGION` in
  `datasets/airbnb/_config_airbnb.R`
- **Analisi fatality** (week_3+): modifica `YEAR_RANGE` in
  `datasets/US_state_year/_config_fatality.R`

---

## Step 8 — Crea `run_all.R` nella root

Script da eseguire per verificare end-to-end l'intera pipeline:

```r
# run_all.R — eseguire in ordine per riprodurre tutti i risultati
library(here)
source(here("week_1","build","code","clean_data_task1.R"))
source(here("week_1","analysis","code","price_analysis.R"))
source(here("week_2","build","code","data_prep.R"))
source(here("week_2","analysis","code","data_analysis.R"))
source(here("week_3","build","code","data_setup.R"))
```

---

## Step 9 — Aggiungi header-commento a ogni script

Formato da applicare all'inizio di ciascun file `.R`:

```r
# Script:  clean_data_task1.R
# Purpose: Legge listings raw, rimuove outlier prezzo, filtra n_reviews
# Input:   datasets/airbnb/listings/listings_{REGION}.csv
# Output:  datasets/airbnb/processed/listings_{region}_cleaned.rds
```

Rinomina anche: `code_analysis_task2345.R` → `price_analysis.R`

---

## Step 10 — Vault notes

### 10a. Create project index

**Path**: `Projects/Applied_Econometrics_Projects.md`

Contents: project overview, repo link, structure summary, per-week status, link to decision note.

### 10b. Create decision note

**Path**: `Decisions/2026-04-10_repo_restructuring_applied_econometrics.md`

Contents: what was restructured and why (copy chain elimination, parametrization, dataset centralization). Links back to project index.

---

## Verification

After implementation, verify end-to-end:
1. **Run week_1 pipeline**: source `clean_data_task1.R` then `price_analysis.R` — confirm cleaned RDS appears in `datasets/airbnb/processed/` and figures/tables in `week_1/analysis/output/`
2. **Run week_2 pipeline**: source `data_prep.R` then `data_analysis.R` — confirm it reads from `datasets/airbnb/processed/` (no cross-week path), AI scores loaded from `datasets/airbnb/neigh_scores/`, outputs generated
3. **Region pivot test**: change `REGION` in `datasets/airbnb/_config_airbnb.R` to `"Milan"`, run week_1 build — confirm it reads `listings_Milan.csv` from `datasets/` and outputs `listings_milan_cleaned.rds` in `datasets/airbnb/processed/`
4. **Git state**: `git status` shows clean working tree (no unexpected untracked files)
5. **Quarto render**: render `Week_1.qmd` and `Week_2.qmd` — confirm figures/tables are found at relative paths
6. **Vault**: verify notes exist and are linked

---

## Files modified (summary)

| Action | File |
|--------|------|
| CREATE ✅ | `datasets/airbnb/_config_airbnb.R` |
| CREATE ✅ | `datasets/US_state_year/_config_fatality.R` |
| CREATE | `datasets/airbnb/processed/` (dir) |
| CREATE | `datasets/US_state_year/processed/` (dir) |
| CREATE | `run_all.R` |
| MOVE   | `week_2/analysis/input/agents/*.csv` → `datasets/airbnb/neigh_scores/` |
| MOVE   | `week_3/build/data_setup.R` → `week_3/build/code/data_setup.R` |
| RENAME | `week_1/analysis/code/code_analysis_task2345.R` → `price_analysis.R` |
| DELETE | `week_1/build/input/` (entire folder + copy) |
| DELETE | `week_1/build/output/` (RDS moves to datasets/airbnb/processed/) |
| DELETE | `week_2/build/input/` (entire folder + copy) |
| DELETE | `week_2/build/output/` (RDS moves to datasets/airbnb/processed/) |
| DELETE | `week_2/analysis/input/listings_Puglia_week2_cleaned.rds` |
| DELETE | `week_2/analysis/output/datasets/` (RDS moves to datasets/airbnb/processed/) |
| EDIT   | `week_1/build/code/clean_data_task1.R` |
| EDIT   | `week_1/analysis/code/price_analysis.R` |
| EDIT   | `week_2/build/code/data_prep.R` |
| EDIT   | `week_2/analysis/code/data_analysis.R` |
| EDIT   | `week_3/build/code/data_setup.R` |
| EDIT   | `.gitignore` |
| EDIT   | `README.md` |
| CREATE | `.gitkeep` in empty week_3 dirs |
| CREATE | Vault: `Projects/Applied_Econometrics_Projects.md` |
| CREATE | Vault: `Decisions/2026-04-10_repo_restructuring_applied_econometrics.md` |
