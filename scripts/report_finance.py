#!/usr/bin/env python3
"""
report_finance.py — Laporan Keuangan Bulanan (Rekapitulasi Simpanan Bulanan)

Mengisi template `docs/template/monthly-finance-report.xlsx`: tabel atas berisi
satu baris per kantor untuk bulan laporan, tabel bawah berisi total semua kantor
per bulan (Januari s.d. bulan laporan, tahun yang sama).

Dipakai oleh notif_relay.py: perintah /keuangan dan tombol "Laporan keuangan"
di Mini App memanggil bangun_laporan(), lalu hasilnya dikirim ke Telegram
sebagai dokumen — sama seperti Rekap Bulanan (report_summary.py), dan dengan
cakupan data yang sama: potret akhir bulan dari view `hist_*`, bukan staging.

Isi kolom (per kantor, per bulan):
  B-D  NASABAH TUNAI 1/2/3  SUM(rincian TUNAI_IFQ), dibagi per K lewat
                            instansi = LMG di capil (K terbanyak di LMG itu)
  E-G  NASABAH AKTIF 1/2/3  jumlah baris capil dengan K = 1/2/3
  H    TOTAL ANGGOTA        E + F + G
  I    SIMPANAN WAJIB       rekap NOMINAL IFQ · TOTAL 100%
  J    SIMPANAN POKOK       rekap NOMINAL ZKT · TOTAL 100%
  K    SIMPANAN SUKARELA    rekap NOMINAL SDQ · TOTAL 100%
  L    TOTAL KONTRIBUSI     I + J + K
  M    TOTAL SETOR          SUM(rekap DISETOR) semua baris kecuali TOTAL
  N    CAD BULAN INI        rekap CAD · DISETOR
  O    AKUMULASI CAD        jumlah CAD semua bulan s.d. bulan laporan, hanya
                            bulan yang punya tarikan finance sendiri
  P    JUMLAH PETUGAS       capil dengan LMG bukan PRA / PJ% / KPJ% (= pengurus)

AKUMULASI CAD dihitung ulang dari warehouse setiap kali, mulai dari bulan
tarikan finance pertama. Jadi ia hanya selengkap riwayat tarikan finance
(Append) — kalau tabel raw finance pernah di-reset, bulan-bulan sebelumnya
hilang dari akumulasi.

Konfigurasi: sama dengan report_summary.py (REPORT_DB_*, REPORT_SCHEMA,
REPORT_VIEW_HIST_*, REPORT_TIMEZONE, REPORT_XLSX_PASSWORD), ditambah
  REPORT_FINANCE_TEMPLATE  (default docs/template/monthly-finance-report.xlsx)
"""

import io
import logging
import os
from datetime import date
from pathlib import Path

import report_summary as rs
from report_summary import ReportError

log = logging.getLogger("notif_relay.report_finance")

TEMPLATE = Path(os.getenv(
    "REPORT_FINANCE_TEMPLATE",
    Path(__file__).resolve().parent.parent / "docs" / "template" / "monthly-finance-report.xlsx",
))

NAMA_BULAN = ["", "JANUARI", "FEBRUARI", "MARET", "APRIL", "MEI", "JUNI", "JULI",
              "AGUSTUS", "SEPTEMBER", "OKTOBER", "NOVEMBER", "DESEMBER"]


def _pilih(tarikan: str) -> str:
    """
    Untuk tiap bulan di `bulan` dan tiap kantor: tarikan terakhir (`tarikan`
    berisi kantor_id, tarikan_id, ditarik_pada) sebelum awal bulan berikutnya,
    jam lokal — aturan potret yang sama dengan report_summary._potret().
    """
    return f"""
    SELECT b.awal_bulan, x.kantor_id, MAX(x.tarikan_id) AS tarikan_id
    FROM bulan b
    JOIN {tarikan} x
      ON x.ditarik_pada < ((b.awal_bulan + INTERVAL '1 month')::timestamp
                           AT TIME ZONE %(zona)s)
    GROUP BY b.awal_bulan, x.kantor_id"""


# Satu baris per (bulan, kantor). Agregat dihitung sekali per tarikan, baru
# dipilih per bulan — view hist_* tidak dipindai ulang untuk tiap bulan.
SQL = f"""
WITH
  capil_tarikan AS (
    SELECT kantor_id, tarikan_id, MIN(ditarik_pada) AS ditarik_pada,
      COUNT(*) FILTER (WHERE trim("K") = '1') AS aktif_1,
      COUNT(*) FILTER (WHERE trim("K") = '2') AS aktif_2,
      COUNT(*) FILTER (WHERE trim("K") = '3') AS aktif_3,
      COUNT(*) FILTER (WHERE "LMG" NOT LIKE 'PRA' AND "LMG" NOT LIKE 'PJ%%'
                         AND "LMG" NOT LIKE 'KPJ%%') AS petugas
    FROM {rs._q(rs.VIEW_CAPIL)}
    GROUP BY kantor_id, tarikan_id
  ),
  -- LMG → K per tarikan capil. Satu LMG idealnya satu K; kalau campur, K yang
  -- anggotanya terbanyak dipakai dan LMG-nya disebut di catatan.
  lmg_k_semua AS (
    SELECT kantor_id, tarikan_id, upper(trim("LMG")) AS lmg, trim("K") AS k,
           COUNT(*) AS n
    FROM {rs._q(rs.VIEW_CAPIL)}
    WHERE trim("K") IN ('1', '2', '3')
    GROUP BY 1, 2, 3, 4
  ),
  lmg_k AS (
    SELECT DISTINCT ON (kantor_id, tarikan_id, lmg) kantor_id, tarikan_id, lmg, k
    FROM lmg_k_semua
    ORDER BY kantor_id, tarikan_id, lmg, n DESC, k
  ),
  lmg_campur AS (
    SELECT kantor_id, tarikan_id, string_agg(lmg, ', ' ORDER BY lmg) AS lmg_campur
    FROM (SELECT kantor_id, tarikan_id, lmg FROM lmg_k_semua
          GROUP BY 1, 2, 3 HAVING COUNT(*) > 1) c
    GROUP BY 1, 2
  ),
  rekap_tarikan AS (
    SELECT kantor_id, tarikan_id, MIN(ditarik_pada) AS ditarik_pada,
      SUM(total_100_persen) FILTER (WHERE j = 'NOMINAL IFQ') AS wajib,
      SUM(total_100_persen) FILTER (WHERE j = 'NOMINAL ZKT') AS pokok,
      SUM(total_100_persen) FILTER (WHERE j = 'NOMINAL SDQ') AS sukarela,
      SUM(disetor)          FILTER (WHERE j <> 'TOTAL')      AS setor,
      SUM(disetor)          FILTER (WHERE j = 'CAD')         AS cad
    FROM (SELECT *, upper(trim(jenis)) AS j FROM {rs._q(rs.VIEW_REKAP)}) r
    GROUP BY kantor_id, tarikan_id
  ),
  rincian_tarikan AS (
    SELECT kantor_id, tarikan_id, MIN(ditarik_pada) AS ditarik_pada
    FROM {rs._q(rs.VIEW_RINCIAN)}
    GROUP BY kantor_id, tarikan_id
  ),
  bulan AS (
    SELECT generate_series(
      LEAST(%(awal)s::timestamp,
            (SELECT date_trunc('month', MIN(ditarik_pada) AT TIME ZONE %(zona)s)
             FROM rekap_tarikan)),
      %(akhir)s::timestamp, INTERVAL '1 month')::date AS awal_bulan
  ),
  p_capil   AS ({_pilih("capil_tarikan")}
  ),
  p_rekap   AS ({_pilih("rekap_tarikan")}
  ),
  p_rincian AS ({_pilih("rincian_tarikan")}
  ),
  -- TUNAI_IFQ per instansi pada tarikan rincian terpilih, diberi K dari
  -- tarikan capil terpilih bulan yang sama.
  tunai AS (
    SELECT pr.awal_bulan, pr.kantor_id,
      SUM(h.tunai_ifq) FILTER (WHERE m.k = '1') AS tunai_1,
      SUM(h.tunai_ifq) FILTER (WHERE m.k = '2') AS tunai_2,
      SUM(h.tunai_ifq) FILTER (WHERE m.k = '3') AS tunai_3,
      SUM(h.tunai_ifq) FILTER (WHERE m.k IS NULL) AS tunai_tanpa_k,
      string_agg(DISTINCT h.instansi, ', ')
        FILTER (WHERE m.k IS NULL AND COALESCE(h.tunai_ifq, 0) <> 0) AS instansi_tanpa_k
    FROM p_rincian pr
    JOIN {rs._q(rs.VIEW_RINCIAN)} h
      ON h.kantor_id = pr.kantor_id AND h.tarikan_id = pr.tarikan_id
    LEFT JOIN p_capil pc
      ON pc.awal_bulan = pr.awal_bulan AND pc.kantor_id = pr.kantor_id
    LEFT JOIN lmg_k m
      ON m.kantor_id = pc.kantor_id AND m.tarikan_id = pc.tarikan_id
     AND m.lmg = upper(trim(h.instansi))
    GROUP BY pr.awal_bulan, pr.kantor_id
  ),
  kunci AS (
    SELECT awal_bulan, kantor_id FROM p_capil
    UNION SELECT awal_bulan, kantor_id FROM p_rekap
    UNION SELECT awal_bulan, kantor_id FROM p_rincian
  )
SELECT
  k.awal_bulan, k.kantor_id,
  t.tunai_1, t.tunai_2, t.tunai_3, t.tunai_tanpa_k, t.instansi_tanpa_k,
  c.aktif_1, c.aktif_2, c.aktif_3, c.petugas, lc.lmg_campur,
  r.wajib, r.pokok, r.sukarela, r.setor, r.cad,
  c.ditarik_pada  AT TIME ZONE %(zona)s AS ditarik_capil,
  r.ditarik_pada  AT TIME ZONE %(zona)s AS ditarik_finance
FROM kunci k
  LEFT JOIN p_capil pc       ON pc.awal_bulan = k.awal_bulan AND pc.kantor_id = k.kantor_id
  LEFT JOIN capil_tarikan c  ON c.kantor_id = pc.kantor_id AND c.tarikan_id = pc.tarikan_id
  LEFT JOIN lmg_campur lc    ON lc.kantor_id = pc.kantor_id AND lc.tarikan_id = pc.tarikan_id
  LEFT JOIN p_rekap pk       ON pk.awal_bulan = k.awal_bulan AND pk.kantor_id = k.kantor_id
  LEFT JOIN rekap_tarikan r  ON r.kantor_id = pk.kantor_id AND r.tarikan_id = pk.tarikan_id
  LEFT JOIN tunai t          ON t.awal_bulan = k.awal_bulan AND t.kantor_id = k.kantor_id
ORDER BY k.awal_bulan, k.kantor_id
"""

# Kolom template → nama nilai. Turunan (H, L, O) dihitung di _nilai_baris().
KOLOM = {
    "B": "tunai_1", "C": "tunai_2", "D": "tunai_3",
    "E": "aktif_1", "F": "aktif_2", "G": "aktif_3",
    "H": "total_anggota",
    "I": "wajib", "J": "pokok", "K": "sukarela",
    "L": "kontribusi",
    "M": "setor", "N": "cad", "O": "akumulasi_cad",
    "P": "petugas",
}
UANG = {"wajib", "pokok", "sukarela", "kontribusi", "setor", "cad", "akumulasi_cad"}

KOL_JUDUL_BULAN = "A2"    # baris kedua judul (merge A2:P2), kosong di template
BARIS_PERTAMA   = 6       # baris data pertama; baris 1-5 judul + header dua tingkat
LABEL_TOTAL     = "TOTAL"
LABEL_BULAN     = "BULAN"


def laporan_aktif() -> tuple:
    bisa, alasan = rs.laporan_aktif()
    if not bisa:
        return bisa, alasan
    if not TEMPLATE.is_file():
        return False, f"template tidak ditemukan: {TEMPLATE}"
    return True, ""


def _uang(nilai) -> float:
    # DISETOR membawa noise float dari Excel (51677862.50000001).
    return round(float(nilai or 0), 2)


def ambil_data(bulan: int, tahun: int) -> dict:
    """{(tahun, bulan): {kantor_id: rec}} untuk semua bulan s.d. bulan laporan."""
    try:
        with rs.psycopg2.connect(connect_timeout=10, **rs.DB) as conn, conn.cursor() as cur:
            cur.execute(SQL, {
                "awal": date(tahun, 1, 1).isoformat(),
                "akhir": date(tahun, bulan, 1).isoformat(),
                "zona": rs.ZONA_WAKTU,
            })
            nama_kolom = [d[0] for d in cur.description]
            baris = cur.fetchall()
    except rs.psycopg2.Error as exc:
        raise ReportError(f"query warehouse gagal: {str(exc).strip()[:300]}") from exc

    hasil = {}
    for r in baris:
        rec = dict(zip(nama_kolom, r))
        awal = rec.pop("awal_bulan")
        kantor = str(rec.pop("kantor_id") or "").strip().upper()
        if kantor:
            hasil.setdefault((awal.year, awal.month), {})[kantor] = rec
    return hasil


def _nilai_baris(rec: dict, akumulasi: float) -> dict:
    """Nilai satu baris (kunci = nama di KOLOM), termasuk kolom turunan."""
    n = {k: rs._angka(rec.get(k)) for k in
         ("tunai_1", "tunai_2", "tunai_3", "aktif_1", "aktif_2", "aktif_3", "petugas")}
    for k in ("wajib", "pokok", "sukarela", "setor", "cad"):
        n[k] = _uang(rec.get(k))
    n["total_anggota"] = n["aktif_1"] + n["aktif_2"] + n["aktif_3"]
    n["kontribusi"] = round(n["wajib"] + n["pokok"] + n["sukarela"], 2)
    n["akumulasi_cad"] = round(akumulasi, 2)
    return n


def _cari_baris(ws, label: str, mulai: int) -> int:
    for baris in range(mulai, ws.max_row + 1):
        if str(ws[f"A{baris}"].value or "").strip().upper() == label:
            return baris
    raise ReportError(f"template tidak punya baris berlabel {label!r} di kolom A "
                      f"— periksa {TEMPLATE}")


def _tulis_total(ws, baris: int, nilai: dict) -> None:
    # Ditulis sebagai angka, menggantikan =SUM(...) template: pratinjau file
    # Telegram tidak menghitung ulang formula.
    for kol, nama in KOLOM.items():
        v = nilai.get(nama, 0)
        ws[f"{kol}{baris}"] = round(v, 2) if nama in UANG else v


def bangun_laporan(bulan: int, tahun: int) -> tuple:
    """Kembalikan (isi_xlsx_bytes, nama_file, catatan) — kontrak report_summary."""
    bisa, alasan = laporan_aktif()
    if not bisa:
        raise ReportError(alasan)
    bulan, tahun = int(bulan), int(tahun)
    if not 1 <= bulan <= 12:
        raise ReportError(f"bulan harus 1-12, bukan {bulan}")

    data = ambil_data(bulan, tahun)

    wb = rs.load_workbook(TEMPLATE)
    ws = wb.active
    ws.title = f"{bulan}_{tahun % 100:02d}"
    ws[KOL_JUDUL_BULAN] = f"BULAN: {NAMA_BULAN[bulan]} {tahun}"

    baris_total = _cari_baris(ws, LABEL_TOTAL, BARIS_PERTAMA)
    kantor_template = {}
    for baris in range(BARIS_PERTAMA, baris_total):
        kode = str(ws[f"A{baris}"].value or "").strip().upper()
        if kode:
            kantor_template[kode] = baris

    # Semua bulan berurutan: akumulasi CAD per kantor berjalan dari bulan
    # tarikan pertama, menyeberang tahun bila perlu.
    akumulasi = {k: 0.0 for k in kantor_template}
    per_bulan = {}      # bulan di tahun laporan → {kantor: nilai_baris}
    for (t, b) in sorted(data):
        isi = {}
        for kantor in kantor_template:
            rec = data[(t, b)].get(kantor)
            if rec is None:
                continue
            # Hanya tarikan finance dari bulan itu sendiri yang menambah
            # akumulasi. Kantor tanpa tarikan baru memakai potret bulan lalu
            # (seperti kolom lain), tapi CAD-nya bukan uang baru — kalau
            # ditambahkan lagi, akumulasinya terhitung dua kali.
            waktu = rec.get("ditarik_finance")
            if waktu is not None and (waktu.year, waktu.month) == (t, b):
                akumulasi[kantor] += _uang(rec.get("cad"))
            isi[kantor] = _nilai_baris(rec, akumulasi[kantor])
        if t == tahun:
            per_bulan[b] = isi

    # Tabel atas: bulan laporan per kantor.
    ini = per_bulan.get(bulan, {})
    total = {nama: 0 for nama in KOLOM.values()}
    for kantor, baris in kantor_template.items():
        nilai = ini.get(kantor)
        if nilai is None:
            continue    # kantor tanpa data: barisnya dibiarkan kosong
        for kol, nama in KOLOM.items():
            ws[f"{kol}{baris}"] = nilai[nama]
            total[nama] += nilai[nama]
    _tulis_total(ws, baris_total, total)

    # Tabel bawah: total semua kantor per bulan di tahun laporan.
    baris_judul = _cari_baris(ws, LABEL_BULAN, baris_total + 1)
    baris_total_bawah = _cari_baris(ws, LABEL_TOTAL, baris_judul + 1)
    total_bawah = {nama: 0 for nama in KOLOM.values()}
    for baris in range(baris_judul + 1, baris_total_bawah):
        label = str(ws[f"A{baris}"].value or "").strip().upper()
        if label not in NAMA_BULAN or not per_bulan.get(NAMA_BULAN.index(label)):
            continue    # bulan sesudah bulan laporan / tanpa data: kosong
        sebulan = {nama: sum(v[nama] for v in per_bulan[NAMA_BULAN.index(label)].values())
                   for nama in KOLOM.values()}
        _tulis_total(ws, baris, sebulan)
        for nama, v in sebulan.items():
            total_bawah[nama] += v
    _tulis_total(ws, baris_total_bawah, total_bawah)

    catatan = _catatan(data.get((tahun, bulan), {}), kantor_template, bulan, tahun)

    buf = io.BytesIO()
    wb.save(buf)
    nama_file = f"keuangan-{tahun:04d}-{bulan:02d}.xlsx"
    log.info("Laporan %s dibangun (%d kantor terisi, %d catatan).",
             nama_file, len(ini), len(catatan))
    return rs._kunci_xlsx(buf.getvalue()), nama_file, catatan


def _catatan(data_bulan: dict, kantor_template: dict, bulan: int, tahun: int) -> list:
    """Hal yang perlu diketahui operator; ditulis ke log relay, bukan ke Telegram."""
    catatan = rs._catatan_tarikan(data_bulan, bulan, tahun)
    for kantor, rec in sorted(data_bulan.items()):
        if rec.get("instansi_tanpa_k"):
            catatan.append(
                f"{kantor}: {rs._angka(rec.get('tunai_tanpa_k'))} nasabah tunai tidak "
                f"masuk kolom 1/2/3 — instansi tanpa LMG di capil: {rec['instansi_tanpa_k']}")
        if rec.get("lmg_campur"):
            catatan.append(f"{kantor}: LMG dengan K campuran (dipakai K terbanyak): "
                           f"{rec['lmg_campur']}")
    kosong = sorted(set(kantor_template) - set(data_bulan))
    if kosong:
        catatan.append("Tanpa data di warehouse: " + ", ".join(kosong))
    lebih = sorted(set(data_bulan) - set(kantor_template))
    if lebih:
        catatan.append("Ada di warehouse tapi tidak ada barisnya di template: "
                       + ", ".join(lebih))
    return catatan
