# Notifikasi Telegram bersifat best-effort

Relay notifikasi selalu membalas `200` ke Airbyte seketika lalu mengirim ke
Telegram di background dengan retry 3× backoff. Kegagalan final hanya ditulis ke
log, pesannya hilang. Alternatifnya — mengirim sinkron atau mengantrikan ke
storage durabel — ditolak karena notifikasi ini bersifat operasional, bukan data:
membuat Airbyte menganggap job bermasalah (atau mengulang kirim sehingga pesan
dobel) gara-gara hiccup di `api.telegram.org` lebih mahal daripada kehilangan
satu pesan.

Konsekuensi: **tidak adanya notifikasi bukan bukti bahwa sync tidak berjalan.**
Airbyte UI tetap satu-satunya sumber kebenaran untuk status Job.
