# GIS Data Pipeline

Gudang data geospasial untuk data catatan sipil (capil) dan keuangan dari sejumlah
kantor perwakilan. Data mengalir dari Nextcloud → Loader Excel (`capil-loader` untuk capil, `excel-loader` untuk finance) →
PostgreSQL/PostGIS → dbt → Metabase.

## Language

### Ingestion & operasional

**Job**:
Satu kali eksekusi sebuah layanan yang punya server kontrol (`load`, `sync`, `dbt`).
Ini adalah unit yang dinotifikasi — satu Job menghasilkan satu pesan, apa pun jumlah
kantor atau tabel di dalamnya.
_Avoid_: stream, pipeline run

**Muatan** (load):
Satu kali Loader Excel menulis data (capil atau finance) satu kantor ke Postgres. Setiap muatan
menjadi satu *tarikan* baru (`_airbyte_generation_id` berikutnya), sama seperti satu
sync Airbyte mode Append dulu. Satu run loader = satu notifikasi, berisi satu baris
per kantor.
_Avoid_: split

**Rekap Pengecekan**:
Satu pesan Telegram per run Loader Excel yang merangkum semua kantor: data masuk,
tidak berubah, atau ditolak — beserta sel yang salah dan cara memperbaikinya, dalam
bahasa sehari-hari. Pengganti notifikasi gagal per kantor.
_Avoid_: notifikasi error, alert

**Loader Excel** (`excel-loader`, `capil-loader`):
Satu script, dua layanan. `excel-loader` membaca `finance.xlsx` tiap kantor dan
menulis sheet REKAP/RINCIAN ke tabel raw finance (ADR 0005, dipicu `/load`).
`capil-loader` membaca `data.xlsx` tiap kantor ke `raw_<kantor>` (ADR 0006, dipicu
`/sync` — namanya tetap, isinya bukan lagi Airbyte).
_Avoid_: split-excel, Airbyte

**Relay Notifikasi**:
Layanan kecil di mesin production yang menjadi bot Telegram pipeline: menerima
perintah, melayani Mini App, dan mengumumkan hasil setiap Job. Dulu juga menerima
webhook Airbyte; sejak ADR 0006 tidak lagi. Bersifat *best-effort*: boleh menjatuhkan
pesan (lihat ADR 0001).
_Avoid_: webhook handler, notifier, bridge

**Kantor Perwakilan**:
Satu kantor cabang yang menyetorkan data capil dan keuangan. Diacu lewat
**Kantor ID** — slug pendek seperti `a1`, `b3`, `c6` — yang muncul sebagai sufiks
tabel mentah (`raw_b3`) dan kolom `kantor_id` di model dbt.
_Avoid_: cabang, branch, office, unit
