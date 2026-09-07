# 0004 — Laporan Rekap Bulanan dikirim sebagai dokumen Telegram

Status: diterima

## Konteks

Rekap bulanan per kantor sudah ada sebagai satu pertanyaan SQL di Metabase, dan
bentuk cetaknya sudah ada sebagai file Excel yang diisi manual tiap bulan
(`docs/template/summary.xlsx`). Yang belum ada adalah jembatan di antara
keduanya: seseorang harus membuka Metabase, ekspor CSV, lalu menyalin angkanya
kolom demi kolom ke template.

Operator sudah terbiasa memakai Mini App untuk memicu job, jadi tombol "buat
laporan" paling wajar diletakkan di sana.

## Keputusan

Relay yang menyusun laporannya (`scripts/report_summary.py`), dan hasilnya
dikirim ke Telegram lewat `sendDocument` — bukan diunduh dari halaman Mini App.

**Kenapa bukan diunduh langsung dari Mini App.** Mini App berjalan di dalam
webview Telegram, yang memblokir unduhan yang dimulai halaman. Sebuah tombol
yang memanggil `/api/report` lalu menyimpan blob-nya akan terlihat berhasil dan
tidak menghasilkan file apa pun. `sendDocument` juga memberi keuntungan lain:
file-nya masuk ke riwayat grup, jadi rekap bulan lalu bisa dicari kembali tanpa
membuat ulang.

**Kenapa query-nya di relay, bukan model dbt baru.** Bentuknya laporan cetak
(satu baris per kantor, kolom mengikuti tata letak template), bukan tabel yang
akan di-query orang lain. Menjadikannya model dbt berarti menambah satu view
yang satu-satunya pemakainya adalah pembuat file ini. Konsekuensinya relay kini
punya kredensial Postgres dan dua dependensi baru (`psycopg2-binary`,
`openpyxl`); keduanya dibuat opsional saat impor supaya image lama tetap hidup
dengan fitur laporan mati, bukan crash.

**Template diisi, bukan digambar ulang.** `openpyxl` membuka
`docs/template/summary.xlsx` lalu menulis nilai ke sel yang sudah ada, sehingga
merge, border, dan format angkanya ikut apa adanya. Menggambar ulang tabel
berarti menyalin desain yang sudah benar ke dalam kode, lalu harus mengubahnya
di dua tempat setiap kali bentuk laporannya berubah.

## Konsekuensi

**Bulan yang dipilih hanya menyaring DAKWAH HASIL.** Model staging cuma
menyimpan tarikan terakhir (`_airbyte_generation_id = MAX`), jadi warehouse
tidak punya riwayat bulanan. Semua kolom selain DAKWAH HASIL adalah potret data
terkini; bulan yang dipilih menyaring `Bln_Integrasi`/`Th_Integrasi` dan menjadi
judul laporan.

Caption filenya sengaja satu kalimat — hanya menyebut siapa yang meminta.
Peringatan (kantor tanpa baris di template, arsip gagal ditulis) tidak lagi ikut
ke Telegram dan hanya ditulis ke log notif-relay: operator memintanya begitu,
dan konsekuensinya angka yang hilang tidak lagi terlihat dari Telegram saja.

**Baris JUMLAH BULAN LALU diisi dari arsip, bukan dari warehouse.** Karena
warehouse tidak punya riwayat, tiap laporan yang selesai dibangun menyimpan
potretnya sendiri ke `REPORT_HISTORY_DIR` sebagai `<tahun>-<bulan>.json`, dan
laporan bulan berikutnya membacanya. Artinya pembanding baru ada setelah bulan
itu pernah dilaporkan sekali — bulan pertama berisi nol, dengan catatan yang
mengatakannya. Folder arsip itu satu-satunya salinan riwayat yang dimiliki
sistem ini; kalau hilang, semua pembanding bulan lalu ikut hilang.

Kuncinya nama semantik (`NAMA_KOLOM`), bukan huruf kolom: menyisipkan satu
kolom di template akan menggeser huruf-hurufnya, dan arsip lama akan terbaca ke
kolom yang salah tanpa satu pun error.

**Kantor baru butuh baris baru di template, tapi tidak butuh perubahan kode.**
Baris ringkasan dicari lewat labelnya di kolom A (`JUMLAH BULAN INI`, dst.), dan
baris data adalah semua yang ada di antara baris 5 dan label itu. Menambah
kantor dari kode ditolak: sel-selnya ter-merge dan bordernya digambar tangan,
jadi menyisipkan baris dari `openpyxl` justru merusak bentuk yang mau
dipertahankan. Kantor yang ada di warehouse tapi tidak ada barisnya dilaporkan
sebagai peringatan di caption, jadi angkanya tidak hilang diam-diam.

**Kolom BARIS dan NT tidak diisi** — keduanya tidak ada di query rekap.

## Alternatif yang ditolak

*Ekspor bawaan Metabase.* Memberi CSV mentah, bukan template terisi; masalah
penyalinan manualnya tetap ada.

*Job terjadwal yang mengirim laporan tiap awal bulan.* Bisa ditambahkan nanti di
atas fungsi yang sama, tapi tanpa riwayat bulanan di warehouse laporan otomatis
akan diam-diam salah kalau sync bulan itu terlambat. Pemicu manual membuat
operator memilih kapan datanya dianggap lengkap.
