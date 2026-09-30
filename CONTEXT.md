# GIS Data Pipeline

Gudang data geospasial untuk data catatan sipil (capil) dan keuangan dari sejumlah
kantor perwakilan. Data mengalir dari Nextcloud → Airbyte (capil) / Loader Excel (finance) →
PostgreSQL/PostGIS → dbt → Metabase.

## Language

### Ingestion & operasional

**Job**:
Satu kali eksekusi sinkronisasi Airbyte untuk satu koneksi. Ini adalah unit yang
dinotifikasi — satu Job menghasilkan satu notifikasi, apa pun jumlah tabel di dalamnya.
_Avoid_: stream, pipeline run, sync run

**Muatan** (load):
Satu kali Loader Excel menulis data finance satu kantor ke Postgres. Setiap muatan
menjadi satu *tarikan* baru (`_airbyte_generation_id` berikutnya), sama seperti satu
sync Airbyte mode Append dulu. Satu run loader = satu notifikasi, berisi satu baris
per kantor.
_Avoid_: split, sync (untuk finance)

**Rekap Pengecekan**:
Satu pesan Telegram per run Loader Excel yang merangkum semua kantor: data masuk,
tidak berubah, atau ditolak — beserta sel yang salah dan cara memperbaikinya, dalam
bahasa sehari-hari. Pengganti notifikasi gagal per kantor.
_Avoid_: notifikasi error, alert

**Loader Excel** (`excel-loader`):
Layanan yang membaca `finance.xlsx` tiap kantor dari Nextcloud dan menulis sheet
REKAP/RINCIAN langsung ke tabel raw finance. Menggantikan split-excel + koneksi
Airbyte finance (ADR 0005).
_Avoid_: split-excel

**Stream**:
Satu tabel/sheet di dalam sebuah Job. Sebuah Job umumnya berisi banyak Stream.
Bukan unit notifikasi: Airbyte tidak mengirim event per-Stream, dan satu pesan per
Stream akan membanjiri grup Telegram.
_Avoid_: tabel, sheet, entity

**Relay Notifikasi**:
Layanan kecil di mesin production yang menerima webhook Airbyte dan menerjemahkannya
menjadi pesan Telegram. Ada karena payload Airbyte dan Telegram Bot API berbeda bentuk —
Airbyte tidak bisa memanggil Telegram secara langsung. Bersifat *best-effort*: selalu
membalas `200` seketika dan boleh menjatuhkan pesan (lihat ADR 0001).
_Avoid_: webhook handler, notifier, bridge

**Kantor Perwakilan**:
Satu kantor cabang yang menyetorkan data capil dan keuangan. Diacu lewat
**Kantor ID** — slug pendek seperti `a1`, `b3`, `c6` — yang muncul sebagai sufiks
tabel mentah (`raw_b3`) dan kolom `kantor_id` di model dbt.
_Avoid_: cabang, branch, office, unit
