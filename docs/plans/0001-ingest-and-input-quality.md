> **Status:** in progress. 2026-09-30: §2 done for **finance** — `excel-loader` writes straight to Postgres, Airbyte finance connections retired (ADR 0005); validation is a hard-coded contract in the loader, not yet `contracts/*.yml`. Capil still on Airbyte. Execute the rest phase by phase; see "Suggested order".

# Evaluation: input quality, Airbyte memory, and multi-division growth

## Context

This is an architecture review, not a code change yet. Three concerns:
1. Excel input is error-prone, but a rigid web form with ~50 fields per record would slow staff down.
2. Airbyte (abctl → kind/Kubernetes, `airbyte/values.yaml`) uses a lot of memory and sometimes OOMs.
3. Other divisions will add their own input pipelines later.

What the repo shows:
- Every raw capil column is `varchar` (`raw_a1`: 50+ columns: `Tgl_/Bln_/Th_Lahir`, `Status_*`, `Alamat_*`, `LMG`…). Staging has to `LOWER()` addresses and filter `"K" IS NOT NULL`, which means the cleanup happens *after* bad data has already landed.
- The volume is small: 14 offices × (capil + 2 finance sheets), a few thousand rows each.
- The current path is Nextcloud → `split_excel.py` (downloads + parses with openpyxl) → **re-uploads per-sheet files to Nextcloud** → Airbyte downloads them again → Postgres. So Airbyte only does a job that `split_excel.py` has already half-done.
- The connections run in **Full refresh | Append**. Each pull copies the whole dataset again, even when the file hasn't changed, so the raw tables and `hist_*` scans keep growing.

---

## 1. Input: keep Excel, but make it a "smart form" + validate on ingest

A strict web form isn't needed. The best trade-off is **the same Excel sheet with guard rails, plus fast automatic feedback**. People keep a grid they already know. Errors get caught at two points: while typing, and at load time.

**A. Template generated from a data contract (prevents most errors while typing)**
- Write one YAML contract per dataset (`contracts/capil.yml`, `contracts/finance_rincian.yml`). Each column gets: type, required, allowed values / lookup list, min/max, regex.
- A script builds the official `.xlsx` template from the contract:
  - Dropdown Data Validation for every categorical field (`Status_*`, `JK`, `Alamat_Provinsi/Kabupaten/Kecamatan` as dependent dropdowns, `LMG`/instansi, `Jenis_*`). The dropdowns read from a hidden, locked `_lists` sheet, which is refreshed from master tables in Postgres.
  - A real date cell instead of three `Tgl/Bln/Th` text columns. Whole-number / decimal validation on money and area fields.
  - Header row and structure locked (sheet protection), data entered in an Excel Table, conditional formatting that turns a row red when a required cell is empty.
- This works in OnlyOffice, which is already in the stack, and in desktop Excel. Nobody has to learn a new tool.

**B. Ingest-time validation with feedback (catches what slips through)**
- The loader (see §2) checks every row against the same contract. Good rows load. Bad rows are **quarantined, not dropped**: they go to `raw_rejects` with the office, row number, column and reason.
- Feedback goes to the person who can fix it: a per-office Telegram message through the existing relay ("A1: 7 rows rejected — row 45 `Tgl_Lahir` not a date…"). Optionally, a `_ERRORS_<file>.xlsx` is written back into that office's Nextcloud folder.
- Staging then stops doing ad-hoc cleanup like `LOWER()` and `K IS NOT NULL`. That normalisation moves into the contract (e.g. `normalize: lower`).

**C. Later, only where it's really needed:** for divisions that edit records continuously and not in monthly batches, use **NocoDB or Baserow** (self-hosted, spreadsheet-like grid on top of Postgres, typed columns, dropdowns, per-user permissions). Do this per division, not as a big-bang migration.

## 2. Replace Airbyte with a lightweight Python loader

Airbyte is oversized for this workload. Its fixed cost is a Kubernetes control plane (Temporal, server, workers, Keycloak, its own Postgres, several GB idle) plus a JVM destination pod per sync, and `source-file` loads each file into pandas. It's all there to move a few MB of Excel per hour.

**Recommendation:** turn `split_excel.py` into an `ingest` service that **loads straight into Postgres** and drops the split → re-upload → Airbyte round-trip. It already downloads and parses every workbook (`split_workbook()`, `process_source()`), and it already has retries, the `job_control` server, `/status`, and Telegram reporting.

Design:
- Per source file: download → **sha256; skip if unchanged since the last load**. This alone stops the Append growth.
- Validate against the contract (§1B). Then, in **one transaction per office**, `COPY` the rows into `raw_<dataset>_<kantor>` with a `_load_id` (monotonic, the same role as `_airbyte_generation_id`), `_loaded_at`, `_source_file` and `_source_hash`. Keeping it all-or-nothing per office matches the current split_excel rule ("if any sheet fails, skip the office").
- Keep the column names `_airbyte_generation_id`/`_airbyte_extracted_at`, or add a one-line dbt macro alias. Then the staging "latest pull" filter, `hist_pulls` (`dbt/macros/history_helpers.sql`) and `report_summary.py` keep working unchanged, and the snapshot and archive logic in ADR 0004 is preserved.
- Memory: openpyxl `read_only=True` streaming plus `COPY` stays well under ~200 MB. Give the container a `mem_limit` in compose.
- After a successful load, trigger `dbt run` over gisnet (`DBT_CONTROL_URL`, the same path the bot already uses). This gives a single chain: file changed → load → dbt → notify. The relay's `/sync` and the Airbyte webhook path become obsolete (keep them until the cutover is done).
- Option if you'd rather not maintain loader code: **dlt (dlthub)**. It's a pip library, runs in the same container, and has schema contracts, append/merge, Postgres, and a small footprint. Both options remove Kubernetes.

**Short-term mitigation while Airbyte is still in use:** in `values.yaml`, set job container memory limits and lower concurrent sync workers. Stagger the 14 × 3 connection schedules, or merge them into fewer connections. Run the connections only after split-excel reports a change, not on a fixed schedule.

Migration: run the new loader into a parallel schema (`raw_v2`), point one dbt target at it, and diff `mart_*` and one month's `/laporan` output against the Airbyte path. Then switch office by office and shut Airbyte down.

## 3. Multi-division readiness: config-driven datasets

Right now a new office means editing `sources.yml`, a new `stg_*.sql`, and the `UNION ALL` in the mart (CLAUDE.md "Adding a New Branch Office"). A new *division* would multiply that work. Make datasets declarative:

- **One registry** (`datasets.yml`): dataset name, owning division, Nextcloud folder pattern, sheet → contract mapping, target schema. The loader, the template generator and the dbt sources all read from it.
- **One raw table per dataset, not per office:** `raw.capil` with a `kantor_id` column, instead of `raw_a1…raw_c6`. The loader stamps `kantor_id` from the folder. Adding an office then needs **no code change** (config only), the 14 `stg_*_capil.sql` files + the union collapse into a single model, and the `source_relation_exists` guards mostly go away.
- **Schema per division** (`raw_<division>`, `analytics_<division>`) with a Postgres role per division, and Metabase collections/permissions to match. One stack, isolated data.
- Contracts are versioned in git. A template change = a contract change = reviewed like code.
- Keep the conventions already working: control-server jobs over gisnet, Telegram as the notification bus, `hist_*` snapshots for monthly reports.

## Suggested order

1. Data contract for capil + finance, and validation-only mode in `split_excel.py` (report rejects to Telegram, change nothing else). Quick win, measures the real error rate.
2. Generate the smart Excel template from the contract; roll it out to the offices.
3. Build the direct-to-Postgres loader (hash skip, `_load_id`, per-office transaction); run it in parallel with Airbyte and diff the outputs.
4. Cut over; consolidate to one raw table per dataset; retire Airbyte.
5. Onboard the first new division through the registry only.

## Critical files (when implementing)
- `scripts/split_excel.py` → becomes the loader (reuse `list_xlsx`, `download`, `_request_with_retry`, `split_workbook` parsing)
- `scripts/job_control.py`, `scripts/dbt_control.py` → reuse for triggering / chaining
- `scripts/notif_relay.py` → reject reports; `/sync` retired after cutover
- `dbt/models/staging/sources.yml`, `dbt/macros/history_helpers.sql`, `dbt/macros/finance_helpers.sql` → keep generation-id semantics
- `docker-compose.yml` → `mem_limit`, new service
- new: `contracts/*.yml`, `datasets.yml`, ADR 0005 (replace Airbyte), ADR 0006 (data contracts)

## Verification
- Phase 1: run validation against the current Nextcloud files; compare the reject counts with known data problems.
- Phase 3: load into `raw_v2`; `dbt run --target v2`; row counts and `EXCEPT` diffs per mart must be empty; `/laporan` for the last month must match byte-for-byte on values; watch container memory in Grafana/cAdvisor (already provisioned).
- Unchanged file → the second run must skip it (no new `_load_id`).
