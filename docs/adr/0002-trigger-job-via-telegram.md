# Trigger job lewat Telegram: HTTP internal, bukan Docker socket

Operator memicu `split-excel` (dan `dbt run`) dari grup Telegram yang sudah dipakai
notifikasi pipeline. Perintahnya diterima `notif-relay`, yang lalu memanggil server
kontrol HTTP kecil (`scripts/job_control.py`) milik masing-masing service di jaringan
`gisnet`. Port kontrol tidak dipublish ke host.

**Kenapa bukan Docker socket.** Cara terpendek adalah memberi relay akses
`/var/run/docker.sock` lalu menjalankan `docker compose run`. Ditolak: relay adalah
proses yang memakan input dari luar, dan akses ke Docker socket setara root di host.
Satu bug parsing di jalur perintah jadi kompromi host penuh. Dengan server kontrol,
yang bisa dipicu hanyalah fungsi yang memang milik service itu — tidak ada shell,
tidak ada nama container yang bisa dirakit dari input.

**Kenapa long-polling, bukan webhook Telegram.** Webhook butuh URL publik ber-HTTPS;
host ini tidak punya inbound dan port-nya sudah padat. `getUpdates` menarik dari sisi
kita. Konsekuensinya: token tidak boleh punya webhook terpasang, dan hanya boleh ada
**satu** proses yang polling per token — dua instance membuat Telegram membalas 409.

**Otorisasi.** Bot Telegram bisa di-DM siapa saja yang tahu username-nya, jadi
perintah dari chat selain `TELEGRAM_CHAT_ID` diabaikan diam-diam (hanya di-log).

**Validasi path hidup di satu tempat.** Argumen `/split A1/Finance` diteruskan apa
adanya oleh relay; yang memeriksanya hanya `resolve_source()` di `split_excel.py`,
yang menolak `..` dan apa pun di luar `NEXTCLOUD_SOURCE_HOME`. Kalau aturannya
ditulis juga di sisi bot, cepat atau lambat keduanya berbeda dan yang longgar jadi
lubang. **`NEXTCLOUD_SOURCE_HOME` yang kosong berarti tidak ada batas folder induk**
(selain `..`) — set sesempit mungkin.

**Single-flight, bukan antrian.** Dua run split-excel yang tumpang tindih menulis
file yang sama di folder tujuan Nextcloud, jadi permintaan kedua dibalas `409` dan
dibuang. Mengantrikan run akan menyembunyikan fakta bahwa run sebelumnya masih jalan.

**Laporan hasil dikirim oleh pemantau, bukan oleh pemicu.** Relay memantau
`/status` semua job dan mengirim satu pesan tiap `last_finished` berubah. Dengan
begitu run terjadwal `--watch` juga dilaporkan, bukan hanya yang dipicu dari
Telegram — dan karena hanya ada satu tempat yang melapor, run manual tidak dapat
pesan dobel. Alternatifnya, split-excel mengirim sendiri ke Telegram saat selesai,
ditolak: itu berarti token bot harus ikut ditaruh di container yang mengunduh dan
memproses file dari luar.

Sifat best-effort dari [ADR 0001](0001-notifikasi-telegram-best-effort.md) tetap
berlaku untuk balasan perintah: laporan hasil job dikirim sekali dengan retry, dan
kalau gagal hanya di-log. **Tidak adanya balasan bukan bukti job tidak jalan** —
`/status` dan log container tetap sumber kebenarannya.
