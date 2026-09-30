#!/usr/bin/env python3
"""
rekap_masalah.py — rekap hasil pengecekan file Excel keuangan, dalam bahasa sehari-hari

Mengubah last_result excel-loader (lihat excel_loader.process_source) menjadi
SATU pesan Telegram untuk semua kantor: siapa yang datanya masuk, siapa yang
ditolak, dan untuk yang ditolak — sel mana yang salah dan cara membetulkannya.

Pembacanya petugas kantor yang mengisi file, bukan admin. Karena itu:
  * istilah teknis (tabel, generation id, exception) tidak muncul, kecuali di
    bagian "Masalah sistem" yang memang untuk admin;
  * nama kolom ditulis seperti judulnya di file ("NOMINAL IFQ", bukan NOMINAL_IFQ);
  * setiap masalah membawa saran perbaikan yang konkret;
  * masalah sejenis di satu sheet diringkas, supaya 40 sel salah tidak jadi 40 baris.

Hanya stdlib — dipakai notif_relay.py, tidak butuh akses ke Nextcloud/database.
"""

import hashlib
import html
import json
import os
import re
from datetime import datetime
from zoneinfo import ZoneInfo

# Jam di judul rekap: zona yang sama dengan Rekap Bulanan, bukan jam container (UTC).
ZONA = ZoneInfo(os.getenv("LOAD_TIMEZONE") or os.getenv("REPORT_TIMEZONE") or "Asia/Jakarta")

BATAS_PESAN = 3900          # batas Telegram 4096, sisakan ruang untuk tag HTML
CONTOH_SEL_PER_JENIS = 5    # sel "bukan angka" yang ditulis satu per satu per sheet

# Jenis masalah yang bukan kesalahan pengisi file.
JENIS_SISTEM = {"folder_gagal", "unduh_gagal", "gagal_simpan",
                "nama_kantor_tidak_valid", "kantor_di_luar_pola"}


def _e(v) -> str:
    return html.escape(str(v))


def _c(v) -> str:
    """
    Teks yang mungkin disalin pembaca (alamat sel, angka pengganti, nama sheet/
    kolom yang benar). <code> di Telegram = sekali ketuk langsung tersalin.
    """
    return f"<code>{_e(v)}</code>"


def _kutip(teks) -> str:
    """
    Pesan error teknis (untuk admin) sebagai kutipan yang bisa dibuka-tutup.
    Dijadikan satu baris supaya pemotongan pesan per baris tidak membelah tagnya.
    """
    satu_baris = " ".join(str(teks).split())[:300]
    return f"<blockquote expandable>{_e(satu_baris)}</blockquote>"


def _kolom(nama: str) -> str:
    """NOMINAL_IFQ -> NOMINAL IFQ, seperti judul kolom yang dilihat di file."""
    return str(nama).replace("_", " ")


def _saran_angka(nilai: str) -> str:
    """Saran perbaikan untuk sel angka yang berisi teks, ditebak dari isinya."""
    teks = str(nilai).strip()
    polos = re.sub(r"[\s.]", "", teks)
    if re.match(r"(?i)^rp", teks):
        angka = re.sub(r"(?i)^rp\.?\s*", "", teks).replace(".", "").replace(" ", "")
        return f"hapus \"Rp\" dan titik, tulis {_c(angka)}" if angka.isdigit() else "hapus \"Rp\", isi angka saja"
    if re.fullmatch(r"\d{1,3}(\.\d{3})+", teks):
        return f"tulis tanpa titik: {_c(teks.replace('.', ''))}"
    if re.fullmatch(r"\d+,\d+", teks):
        return f"pakai titik untuk desimal: {_c(teks.replace(',', '.'))}"
    if re.fullmatch(r"\d{1,3}(,\d{3})+", teks):
        return f"tulis tanpa koma: {_c(teks.replace(',', ''))}"
    if polos.isdigit():
        return f"hapus spasi, tulis {_c(polos)}"
    if teks in ("-", "–", "—"):
        return f"kosongkan sel atau isi {_c(0)}"
    return "isi dengan angka saja (tanpa huruf, titik ribuan, atau \"Rp\")"


def _daftar_sel(sel: list, maks: int = 6) -> str:
    """Daftar alamat sel sebagai satu blok salin, mis. `D11, D12, D13`, ditambah '…'."""
    return _c(", ".join(sel[:maks])) + (", …" if len(sel) > maks else "")


def _kalimat_galat(kelompok: dict, sheet_lain: list) -> list:
    """
    Kalimat untuk semua masalah pengisi di satu (file, sheet), dikelompokkan
    per jenis. `kelompok` = {jenis: [masalah, ...]}; boleh berisi kolom_tambahan
    (catatan) yang dipakai sebagai petunjuk judul kolom yang salah ketik.
    `sheet_lain` = sheet tak dikenal di kantor ini, petunjuk sheet yang diganti nama.
    """
    out = []
    for m in kelompok.get("file_rusak", []):
        out.append(f"File {_c(m.get('file'))} tidak bisa dibuka — mungkin rusak atau "
                   f"bukan file Excel (.xlsx) asli. Buka lalu simpan ulang sebagai .xlsx.")
    for m in kelompok.get("sheet_hilang", []):
        kalimat = f"Sheet {_c(m.get('sheet'))} tidak ada. Nama sheet harus persis {_c(m.get('sheet'))}."
        if sheet_lain:
            kalimat += (f" Ada sheet lain bernama {', '.join(_c(x) for x in sheet_lain)} "
                        f"— kalau itu yang dimaksud, ganti namanya jadi {_c(m.get('sheet'))}.")
        out.append(kalimat)
    for m in kelompok.get("sheet_ganda", []):
        out.append(f"Ada dua sheet bernama {_c(m.get('sheet'))} di file yang sama. Hapus salah satu.")
    for m in kelompok.get("sheet_ganda_antar_file", []):
        out.append(f"Sheet {_c(m.get('sheet'))} ada di dua file "
                   f"({_c(m.get('detail'))} dan {_c(m.get('file'))}). "
                   f"Simpan hanya satu file keuangan di folder ini.")
    for m in kelompok.get("sheet_kosong", []):
        out.append("Sheet ini kosong — baris judul kolom (baris 1) tidak ada.")
    hilang = [_kolom(m["kolom"]) for m in kelompok.get("kolom_hilang", [])]
    if hilang:
        kalimat = (f"Judul kolom tidak ditemukan di baris 1: {', '.join(_c(k) for k in hilang)}. "
                   f"Judul kolom jangan diubah, dihapus, atau dipindah ke baris lain.")
        asing = [_kolom(k) for m in kelompok.get("kolom_tambahan", [])
                 for k in str(m.get("kolom", "")).split(", ") if k]
        if asing:
            kalimat += (f" Ada judul yang tidak dikenal: {', '.join(_c(k) for k in asing)} — "
                        f"mungkin salah ketik atau diganti namanya?")
        out.append(kalimat)
    for m in kelompok.get("kolom_ganda", []):
        out.append(f"Judul kolom {_c(_kolom(m['kolom']))} muncul dua kali "
                   f"(sel {_c(m.get('sel'))}). Hapus salah satunya.")

    # Sel dengan isi yang sama (mis. "-" di 100 sel) = satu kebiasaan pengisi,
    # jadi satu baris saja; isi yang berbeda-beda ditulis per sel.
    per_isi: dict = {}
    for m in kelompok.get("bukan_angka", []):
        per_isi.setdefault(str(m.get("nilai", "")), []).append(m)
    baris_angka, sisa = 0, []
    for isi, daftar in per_isi.items():
        if baris_angka >= CONTOH_SEL_PER_JENIS:
            sisa += [m["sel"] for m in daftar]
            continue
        baris_angka += 1
        if len(daftar) == 1:
            m = daftar[0]
            out.append(f"Sel {_c(m['sel'])} (kolom {_e(_kolom(m['kolom']))}) berisi "
                       f"\"{_e(isi)}\" → {_saran_angka(isi)}.")
        else:
            out.append(f"{len(daftar)} sel berisi \"{_e(isi)}\" → {_saran_angka(isi)}. "
                       f"Selnya: {_daftar_sel([m['sel'] for m in daftar])}")
    if sisa:
        out.append(f"…dan {len(sisa)} sel lain yang juga harus berisi angka: {_daftar_sel(sisa)}")

    rumus = [m["sel"] for m in kelompok.get("formula_tanpa_hasil", [])]
    if rumus:
        out.append(f"{len(rumus)} sel berisi rumus tapi hasil hitungnya belum tersimpan "
                   f"({_daftar_sel(rumus)}). Buka file di OnlyOffice/Excel, tunggu "
                   f"angkanya muncul, lalu simpan ulang.")
    for m in kelompok.get("folder_kosong", []):
        out.append("Tidak ada file Excel (.xlsx) di folder Finance kantor ini.")
    for m in kelompok.get("terpotong", []):
        out.append(f"…dan {m.get('jumlah')} masalah lain tidak ditampilkan.")
    return out


def _kalimat_sistem(m: dict) -> str:
    """Kalimat sederhana; pesan error teknisnya (bila ada) menyusul sebagai kutipan."""
    teks = {
        "folder_gagal": "folder di Nextcloud tidak bisa dibaca",
        "unduh_gagal": f"file {_c(m.get('file', ''))} gagal diunduh dari Nextcloud",
        "gagal_simpan": "data sudah benar tapi gagal disimpan ke database",
        "nama_kantor_tidak_valid": "nama folder kantor tidak bisa dipakai",
        "kantor_di_luar_pola": "kode kantor di luar pola A1/B2/…, tidak ikut model riwayat dbt",
    }.get(m["jenis"], _e(m["jenis"]))
    return teks + (_kutip(m["detail"]) if m.get("detail") else "")


def _kalimat_catatan(m: dict) -> str:
    if m["jenis"] == "sheet_tak_dikenal":
        return f"sheet {_c(m.get('sheet'))} tidak dibaca (yang dibaca hanya REKAP dan RINCIAN)"
    if m["jenis"] == "kolom_tambahan":
        return (f"sheet {_c(m.get('sheet'))}: kolom tambahan tidak dibaca "
                f"({', '.join(_c(_kolom(k)) for k in str(m.get('kolom', '')).split(', '))})")
    return _e(m["jenis"])


def dimuat(hasil: dict) -> bool:
    """Ada kantor yang datanya benar-benar masuk pada run ini?"""
    return any(t.get("status") == "dimuat"
               for k in hasil.get("kantor") or [] for t in k.get("tabel") or [])


def sidik(hasil: dict) -> str:
    """
    Sidik semua masalah + peringatan Airbyte pada run ini. Dipakai relay untuk
    tidak mengulang rekap yang sama persis setiap run terjadwal. String kosong =
    tidak ada masalah apa pun.
    """
    butir = []
    if hasil.get("error"):
        butir.append(["run", hasil["error"]])
    for k in hasil.get("kantor") or []:
        for m in k.get("masalah") or []:
            butir.append([k.get("kantor"), m.get("jenis"), m.get("file"), m.get("sheet"),
                          m.get("sel"), m.get("kolom"), m.get("nilai")])
        for t in k.get("tabel") or []:
            if t.get("airbyte_aktif"):
                butir.append([k.get("kantor"), "airbyte_aktif", t.get("tabel")])
    if not butir:
        return ""
    return hashlib.sha256(json.dumps(sorted(butir, key=str), ensure_ascii=False)
                          .encode("utf-8")).hexdigest()


def susun(hasil: dict, durasi: str = "", diulang: bool = False) -> str:
    """Susun satu pesan rekap (parse_mode HTML) dari last_result excel-loader."""
    kantor = hasil.get("kantor") or []
    diperbarui, tetap, ditolak = [], [], []
    for k in kantor:
        if not k.get("ok"):
            ditolak.append(k)
        elif any(t.get("status") == "dimuat" for t in k.get("tabel") or []):
            diperbarui.append(k)
        else:
            tetap.append(k)

    judul = "⚠️" if (ditolak or hasil.get("error")) else "✅"
    kepala = [f"{judul} <b>Rekap pengecekan data keuangan</b>"]
    info = [datetime.now(ZONA).strftime("%d/%m %H:%M")]
    if kantor:
        info.append(f"{len(kantor)} kantor diperiksa")
    if durasi:
        info.append(durasi)
    kepala.append(" · ".join(info))
    if diulang:
        kepala.append("<i>Pengingat: masalah di bawah ini belum diperbaiki sejak rekap sebelumnya.</i>")

    ringkas = []
    if diperbarui:
        ringkas.append(f"✅ Data masuk ({len(diperbarui)}): "
                       + ", ".join(_e(k["kantor"]) for k in diperbarui))
    if tetap:
        ringkas.append(f"➖ Tidak ada perubahan ({len(tetap)}): "
                       + ", ".join(_e(k["kantor"]) for k in tetap))
    if ditolak:
        ringkas.append(f"❌ Ditolak ({len(ditolak)}): "
                       + ", ".join(_e(k["kantor"]) for k in ditolak))
        ringkas.append("<i>Data kantor yang ditolak tidak dimasukkan; laporan tetap memakai "
                       "data terakhir yang benar. Setelah file diperbaiki di Nextcloud, "
                       "pengecekan berikutnya otomatis memasukkannya.</i>")

    rincian, sistem, catatan, airbyte = [], [], [], []
    if hasil.get("error"):
        sistem.append("loader tidak bisa bekerja, tidak ada kantor yang diproses"
                      + _kutip(hasil["error"]))
    for k in kantor:
        nama = k.get("kantor", "?")
        per_tempat: dict = {}
        masalah = k.get("masalah") or []
        galat_di = {(m.get("file"), m.get("sheet")) for m in masalah if m.get("galat")}
        ada_sheet_hilang = any(m["jenis"] == "sheet_hilang" for m in masalah)
        sheet_lain = [m.get("sheet") for m in masalah if m["jenis"] == "sheet_tak_dikenal"]
        for m in masalah:
            tempat = (m.get("file"), m.get("sheet"))
            if m.get("sistem") or m["jenis"] in JENIS_SISTEM:
                (sistem if m.get("galat") else catatan).append(
                    f"<b>{_e(nama)}</b>: {_kalimat_sistem(m)}")
            elif m["jenis"] == "kolom_tambahan" and tempat in galat_di:
                # Jadi petunjuk di kalimat "judul kolom tidak ditemukan".
                per_tempat.setdefault(tempat, {}).setdefault(m["jenis"], []).append(m)
            elif m["jenis"] == "sheet_tak_dikenal" and ada_sheet_hilang:
                continue  # sudah disebut di kalimat "sheet tidak ada"
            elif not m.get("galat"):
                catatan.append(f"<b>{_e(nama)}</b>: {_kalimat_catatan(m)}")
            else:
                if m["jenis"] == "sheet_hilang":
                    tempat = (None, None)  # hilang dari semua file, bukan dari satu tempat
                per_tempat.setdefault(tempat, {}).setdefault(m["jenis"], []).append(m)
        if per_tempat:
            rincian.append(f"\n<b>{_e(nama)}</b>")
            # Masalah tingkat kantor (tanpa file/sheet) ditulis paling atas, tanpa judul.
            for (file, sheet), kelompok in sorted(per_tempat.items(),
                                                  key=lambda x: x[0] != (None, None)):
                lokasi = " · ".join(_e(x) for x in (file, f"sheet {sheet}" if sheet else None) if x)
                kalimat = _kalimat_galat(kelompok, sheet_lain)
                if lokasi and kalimat:
                    rincian.append(f"<i>{lokasi}</i>")
                rincian += [f"• {x}" for x in kalimat]
        for t in k.get("tabel") or []:
            if t.get("airbyte_aktif") and nama not in airbyte:
                airbyte.append(nama)

    badan = kepala + ([""] + ringkas if ringkas else []) + rincian
    if sistem:
        badan += ["", "⚙️ <b>Masalah sistem</b> (untuk admin)"] + [f"• {x}" for x in sistem]
    if airbyte:
        badan += ["", "⚠️ <b>Airbyte masih mengisi data keuangan</b> "
                  f"{_e(', '.join(airbyte))} — matikan (disable, jangan reset) koneksi Airbyte "
                  "finance kantor tersebut."]
    if catatan:
        badan += ["", "ℹ️ <b>Catatan</b> (data tetap dimasukkan)"] + [f"• {x}" for x in catatan]

    # Potong per baris supaya tag HTML tidak terbelah.
    hasil_teks, panjang = [], 0
    for i, baris in enumerate(badan):
        if panjang + len(baris) + 1 > BATAS_PESAN:
            hasil_teks.append(f"\n<i>…rekap dipotong ({len(badan) - i} baris lagi) — "
                              f"perbaiki yang tertera dulu, sisanya muncul di rekap berikutnya.</i>")
            break
        hasil_teks.append(baris)
        panjang += len(baris) + 1
    return "\n".join(hasil_teks)
