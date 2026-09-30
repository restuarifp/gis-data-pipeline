# 0005 — Finance dimuat langsung dari Excel ke Postgres (excel-loader)

Status: diterima (2026-09-30). Menggantikan `split-excel` + koneksi Airbyte finance.
Capil tetap lewat Airbyte.

## Konteks

Jalur finance sebelumnya: `split_excel.py` mengunduh `finance.xlsx` tiap kantor,
memecah per sheet, **mengunggah ulang** file per-sheet ke Nextcloud, lalu Airbyte
(koneksi per kantor, jadwal cron, mode Full refresh | Append) mengunduhnya lagi
dan menulis ke `raw_finance_rekap_<kantor>` / `raw_finance_rincian_<kantor>`.
Script itu sudah membaca workbook-nya; Airbyte hanya memindahkan data yang sudah
ada di memori, dengan biaya Kubernetes yang sering OOM (lihat
`docs/plans/0001-ingest-and-input-quality.md` §2).

## Keputusan

`scripts/excel_loader.py` (service `excel-loader`) membaca sheet `REKAP` dan
`RINCIAN` lalu menulisnya langsung ke tabel raw yang sama.

- **Bentuk tabel tidak berubah.** Kolom `_airbyte_raw_id`, `_airbyte_extracted_at`,
  `_airbyte_meta`, `_airbyte_generation_id` tetap ditulis. Filter "tarikan
  terakhir" di staging, macro `hist_pulls`, dan `report_summary.py` bergantung
  pada kolom itu, jadi dbt dan Rekap Bulanan tidak perlu diubah. Setiap muatan =
  satu tarikan baru dengan `generation_id = MAX + 1` (tetap mode Append, riwayat
  bulanan tetap ada). Baris loader dikenali dari `_airbyte_meta->>'loader'`.
- **Satu transaksi per kantor.** Satu sheet gagal = tidak ada tabel kantor itu
  yang berubah; tarikan sebelumnya tetap berlaku.
- **Kontrak kolom di kode** (`DATASETS`): header baris 1, dinormalisasi seperti
  Airbyte (`TUNAI IFQ` → `TUNAI_IFQ`). Kolom wajib hilang, sel angka berisi teks,
  atau formula tanpa hasil tersimpan → kantor ditolak dengan alamat selnya.
  Airbyte dulu memuat kasus terakhir itu sebagai kosong tanpa suara.
- **Lewati bila tidak berubah — di bulan yang sama.** Sidik SHA-256 atas isi data
  (bukan byte file) disimpan di `_airbyte_meta`. Kalau sama dengan tarikan
  terakhir *dan* tarikan itu sudah terjadi bulan ini (`LOAD_TIMEZONE`), tidak ada
  baris baru. Run per jam tidak lagi menggandakan data, tapi setiap bulan tetap
  punya tarikan sendiri untuk potret Rekap Bulanan.
- **Jadwal pindah ke loader** (`SCHEDULE_INTERVAL_MINUTES`). Run terjadwal kini
  lewat `JobRunner.run_now()` sehingga tunduk pada lock single-flight yang sama
  dengan `/load` dan tercatat di `/status`. Sebelumnya loop `--watch` memanggil
  `run_once()` langsung: run terjadwal tidak terlihat oleh `watch_jobs()` dan bisa
  tumpang tindih dengan run manual.
- **Notifikasi Telegram menggantikan webhook Airbyte finance.** `job_control`
  menyimpan hasil runner (`last_result`); relay menyusun satu pesan per run dengan
  satu baris per kantor (tabel, jumlah baris, nomor tarikan, atau error). Run
  terjadwal yang sukses tanpa perubahan tidak diumumkan; run manual selalu dijawab.
- **UX bot:** `/split` → `/load` (alias `/split` masih diterima dengan catatan),
  tab Mini App `split` → `load`, `SPLIT_CONTROL_URL` → `LOAD_CONTROL_URL`
  (nilai lama sengaja diabaikan karena menunjuk ke host yang sudah tidak ada).

**Rekap pengecekan (tambahan 2026-09-30).** Loader memeriksa semua file dan
sheet sampai habis dan mengumpulkan setiap temuan sebagai data terstruktur
(`masalah`), bukan berhenti di kesalahan pertama. Relay menyusun satu rekap
berbahasa sehari-hari untuk semua kantor (`scripts/rekap_masalah.py`) — dibaca
petugas pengisi file, jadi setiap temuan menyebut sel, isinya, dan cara
memperbaikinya. Rekap yang sama persis tidak dikirim ulang oleh run terjadwal;
diingatkan lagi setelah `REKAP_ULANG_JAM`. Kalimatnya sengaja hidup di relay,
bukan loader: loader tetap bisa dipakai tanpa Telegram, dan bahasa rekap bisa
diubah tanpa menyentuh jalur tulis database.

## Konsekuensi

- **Koneksi Airbyte finance harus dimatikan saat cutover** — *disable*, jangan
  *reset/clear data* (reset mengosongkan tabel raw beserta seluruh riwayatnya).
  Kalau Airbyte tetap menulis, generation id-nya bisa lebih kecil dari milik
  loader sehingga tarikannya tak terlihat. Loader mendeteksi baris non-loader
  yang lebih baru dari muatannya dan menandainya ⚠️ di pesan Telegram.
- `/sync` dan webhook Airbyte tetap ada, sekarang hanya untuk capil.
- Kantor finance baru tidak butuh koneksi Airbyte: tambahkan folder ke
  `NEXTCLOUD_SOURCE_PATHS`; tabelnya dibuat loader pada muatan pertama. Model dbt
  (`sources.yml`, `stg_*`, mart) tetap perlu ditambahkan seperti biasa.
- Folder `NEXTCLOUD_DEST_PATH` (file hasil split) tidak lagi diperbarui; boleh
  dihapus setelah koneksi Airbyte finance mati.
- Tidak perlu memicu `dbt run` setelah muatan: model finance berupa view.
- Kontrak ada di Python, belum di `contracts/*.yml` (plan 0001 §1). Memindahkannya
  nanti tidak mengubah bentuk tabel.
