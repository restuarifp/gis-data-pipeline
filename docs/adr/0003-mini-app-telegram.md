# Mini App Telegram: panel web dilayani relay, otorisasi lewat initData

Perintah teks (`/split`, `/dbt`, `/sync`, `/status`, `/logs`) tetap ada, tapi
operator harus hafal namanya dan mengetik path folder dengan benar dari ponsel.
Mini App menambahkan panel klik-klik dengan **kemampuan yang sama persis**:
status semua job, tombol jalankan (pilih folder / perintah dbt / koneksi Airbyte),
dan ekor log yang menyegar sendiri.

**Halaman dilayani oleh notif-relay sendiri** (`GET /app`, file
`scripts/miniapp.html`), bukan service atau image web baru. Panelnya hanya
memanggil hal yang sudah dilakukan bot teks; menaruhnya di proses lain berarti
menyalin token bot dan URL control server ke tempat kedua.

**Otorisasi: verifikasi `initData`, lalu keanggotaan grup.** Padanan aturan
"hanya chat `TELEGRAM_CHAT_ID` yang dilayani" untuk sebuah halaman web adalah
"hanya anggota grup itu". Setiap permintaan `/api/*` memverifikasi ulang HMAC
`initData` dengan token bot (tanpa itu, siapa pun yang tahu URL-nya bisa memicu
job), lalu memastikan `user.id` anggota `TELEGRAM_CHAT_ID` lewat `getChatMember`
— jawabannya di-cache 5 menit supaya polling status tidak jadi banjir panggilan.
Tidak ada cookie dan tidak ada sesi: `initData` adalah satu-satunya kredensial,
dan umurnya dibatasi `MINI_APP_AUTH_MAX_AGE` (default 24 jam) supaya yang bocor
tidak berlaku selamanya. Keanggotaan yang tidak bisa dipastikan = ditolak.

**Validasi parameter tetap tinggal di control server.** Panel mengirim
`sources`/`select` apa adanya ke `POST /run`; yang memeriksa tetap
`resolve_source()` dan `validate_params()` milik service masing-masing — alasan
yang sama dengan ADR 0002: dua salinan aturan pasti berbeda suatu saat, dan yang
longgar jadi lubang. Daftar folder yang tampil sebagai chip diambil dari blok
`info` pada `/status`, jadi panel tidak pernah menebak isi konfigurasi.

**Butuh URL HTTPS publik.** Telegram menolak membuka `http://`, sementara relay
mendengarkan HTTP di dalam `gisnet` — jadi `MINI_APP_URL` harus menunjuk ke
reverse proxy atau tunnel yang meneruskan ke `/app`. Kosong = fitur mati: tanpa
URL, tombolnya tidak akan pernah bisa dibuka, jadi tidak ada gunanya dipasang.
Ini juga konsekuensi yang tidak dimiliki bot teks (ADR 0002 memilih long-polling
justru untuk menghindari inbound) — perlu diputuskan sadar, bukan kebetulan.

**Tombol `web_app` hanya sah di chat privat.** Di grup, Telegram menolaknya, jadi
`/app` di grup memakai *direct link* `t.me/<bot>/<shortname>` (dibuat dengan
BotFather `/newapp`, isi `MINI_APP_DIRECT_LINK`) sebagai tombol URL biasa. Karena
itu pula perintah `/start`, `/app`, dan `/help` dilayani di japri — tapi hanya
untuk anggota grup, dan hanya untuk membuka panel. Perintah pemicu job lewat teks
tetap eksklusif milik grup.

**Setiap aksi dari panel diumumkan ke grup.** Klik di panel tidak meninggalkan
pesan seperti perintah teks, jadi relay mengirim satu baris "dimulai oleh
@siapa lewat Mini App". Tanpa itu, operator lain melihat job berjalan entah dari
mana. Laporan *selesai* tetap satu-satunya milik `watch_jobs()` — panel tidak
ikut melapor, supaya tidak ada pesan dobel.
