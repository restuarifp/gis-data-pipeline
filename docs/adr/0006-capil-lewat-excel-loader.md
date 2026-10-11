# 0006 — Capil dimuat lewat excel-loader; Airbyte pensiun

Status: diterima (2026-10-11). Melanjutkan ADR 0005; menggantikan koneksi Airbyte
capil, webhook Airbyte → Telegram, dan `/sync` versi Airbyte Public API.

## Konteks

Setelah ADR 0005, Airbyte hanya tersisa untuk `<Kantor>/data.xlsx` (capil) →
`raw_<kantor>`. Seluruh biaya Kubernetes-nya (OOM, lihat plan 0001 §2) ditanggung
untuk satu file per kantor, dan mode Full refresh | Append menyalin seluruh isi
file tiap sync meski tidak ada yang berubah.

## Keputusan

- **Image yang sama, service kedua.** `capil-loader` menjalankan
  `scripts/excel_loader.py` dengan `LOADER_DATASET=capil`. Server kontrol, lock
  single-flight, `/status` dan `/logs`-nya terpisah dari `excel-loader`, sehingga
  run finance yang panjang tidak membuat `/sync` ditolak 409.
- **Hanya `CAPIL_FILE` (default `data.xlsx`) yang dibaca** dari folder kantor
  (`CAPIL_SOURCE_PATHS`, kosong = induk tiap folder Finance). Folder itu berisi
  file lain; file yang hilang dilaporkan dengan daftar file lain sebagai petunjuk
  salah nama. Sheet: `CAPIL_SHEET`, kosong = sheet pertama.
- **Kontrak kolom dibaca dari database, bukan ditulis di kode.** Tabel raw capil
  punya ±50 kolom bernama buatan Airbyte (huruf besar-kecil campur, `No_` dari
  `No.`). Kolom tabel kantor itu — nama dan urutannya — adalah kontraknya; judul
  di file dicocokkan tanpa peduli huruf besar dan tanda baca. Kantor baru dibuat
  `LIKE` tabel capil lain (`CAPIL_TABEL_ACUAN` atau yang pertama ditemukan),
  karena `stg_*_capil` memakai `dbt_utils.star()` dan `mart_capil` adalah
  `UNION ALL` berdasarkan posisi kolom. Kolom tambahan di file dicatat, tidak
  pernah ditambahkan ke tabel, dengan alasan yang sama.
- Selebihnya sama dengan finance (ADR 0005): bentuk tabel `_airbyte_*`,
  `generation_id = MAX + 1`, satu transaksi per kantor, lewati bila isi sama
  dengan tarikan bulan berjalan, semua masalah dikumpulkan, rekap berbahasa
  sehari-hari (kini menyebut "data capil" atau "data keuangan" menurut
  `dataset` di hasil run).
- **`/sync` tetap namanya, artinya berubah**: `/sync [A1 B2 …]` memicu
  capil-loader. Mini App tab *sync* kini memilih kantor, bukan koneksi Airbyte.
- **Semua kode Airbyte di relay dihapus**: Public API (`/sync` lama,
  `/api/connections`, `/api/sync`), dan webhook → Telegram. POST di luar `/api/*`
  dibalas 404 supaya notifikasi Airbyte yang masih menyala tampak gagal di UI-nya,
  bukan tertelan. `AIRBYTE_*` di `.env` diabaikan dengan peringatan di log.

## Konsekuensi

- **Cutover: koneksi Airbyte capil di-*disable*, jangan *reset/clear*.** Reset
  mengosongkan `raw_<kantor>` beserta seluruh riwayat yang dibaca `hist_capil`
  dan Rekap Bulanan. Loader melanjutkan generation id dari tarikan Airbyte
  terakhir; Airbyte yang masih menulis ditandai ⚠️ di rekap.
- **Paritas nilai belum terbukti** sebelum dibandingkan di produksi: Airbyte
  (pandas) dan openpyxl bisa menulis angka/tanggal sebagai teks yang berbeda
  (`1` vs `1.0`, `1990-05-01 00:00:00` vs format lain). Laporan membandingkan
  `"K" = '1'` dan `Bln_Integrasi::numeric`, jadi jalankan sekali ke schema
  bayangan (`LOAD_DB_SCHEMA`) dan bandingkan dengan tarikan Airbyte terakhir
  sebelum cutover.
- Kantor capil baru: tambahkan foldernya ke `CAPIL_SOURCE_PATHS`; tabel dibuat
  pada muatan pertama. Model dbt tetap ditambahkan seperti biasa.
- Airbyte (deployment Helm di luar compose) tidak lagi dipakai pipeline ini dan
  boleh dimatikan setelah cutover.
