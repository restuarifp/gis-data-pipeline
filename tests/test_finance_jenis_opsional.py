"""
Kolom JENIS di sheet REKAP finance bersifat opsional.

Jalankan (dari root repo, di image excel-loader supaya dependensinya sama):

    docker run --rm -v "$PWD":/repo -w /repo gis-data-pipeline-excel-loader \
        python -m unittest discover -s tests -v

Uji ujung-ke-ujung ke Postgres (process_source sampai INSERT) hanya jalan kalau
TEST_DB_HOST di-set; ia memakai schema sementara dan menghapusnya lagi.
"""

import io
import logging
import os
import sys
import unittest
import uuid
from pathlib import Path

# excel_loader membaca config saat di-import.
os.environ.setdefault("NEXTCLOUD_URL", "https://nextcloud.invalid")
os.environ.setdefault("NEXTCLOUD_USER", "tes")
os.environ.setdefault("NEXTCLOUD_PASSWORD", "tes")
os.environ.setdefault("NEXTCLOUD_SOURCE_PATHS", "A1/Finance")
os.environ["LOADER_DATASET"] = "finance"
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))

from openpyxl import Workbook  # noqa: E402

import excel_loader as el  # noqa: E402
import rekap_masalah as rm  # noqa: E402

JUDUL_ANGKA = ["TOTAL 100 PERSEN", "DIKELOLA KANWIL", "DISETOR", "PEMBULATAN SETOR"]
BARIS_REKAP = [("NOMINAL IFQ", 1000, 200, 800, 800), ("CAD", 50, None, 50, 50)]


def _xlsx(judul_rekap, baris_rekap) -> bytes:
    wb = Workbook()
    rincian = wb.active
    rincian.title = "RINCIAN"
    rincian.append(["INSTANSI"] + [f"{p} {j}" for p in ("TUNAI", "NOMINAL") for j in el.JENIS_FINANCE])
    rincian.append(["DINAS A"] + [1] * 20)
    rekap = wb.create_sheet("REKAP")
    rekap.append(judul_rekap)
    for b in baris_rekap:
        rekap.append(list(b))
    buf = io.BytesIO()
    wb.save(buf)
    return buf.getvalue()


def _file_lengkap() -> bytes:
    return _xlsx(["JENIS"] + JUDUL_ANGKA, BARIS_REKAP)


def _file_tanpa_kolom_jenis() -> bytes:
    # Kolom JENIS dihapus seluruhnya: kolom angka bergeser mulai dari A.
    return _xlsx(JUDUL_ANGKA, [b[1:] for b in BARIS_REKAP])


def _file_judul_jenis_kosong() -> bytes:
    # Label di kolom A tetap ada, hanya sel judul A1 yang kosong.
    return _xlsx([None] + JUDUL_ANGKA, BARIS_REKAP)


def _baca(isi):
    return el.baca_workbook(isi, el.KONTRAK_FINANCE)


class JenisOpsional(unittest.TestCase):
    def test_dengan_jenis_tidak_berubah(self):
        sheets, masalah = _baca(_file_lengkap())
        self.assertEqual(masalah, [])
        self.assertEqual([r["JENIS"] for r in sheets["REKAP"]], ["NOMINAL IFQ", "CAD"])
        self.assertEqual(str(sheets["REKAP"][0]["TOTAL_100_PERSEN"]), "1000")
        self.assertIsNone(sheets["REKAP"][1]["DIKELOLA_KANWIL"])

    def test_tanpa_kolom_jenis_dimuat_null_dengan_catatan(self):
        sheets, masalah = _baca(_file_tanpa_kolom_jenis())
        self.assertFalse([m for m in masalah if m["galat"]], masalah)
        self.assertEqual([(m["jenis"], m["kolom"], m["sheet"]) for m in masalah],
                         [("kolom_opsional_hilang", "JENIS", "REKAP")])
        self.assertEqual([r["JENIS"] for r in sheets["REKAP"]], [None, None])
        self.assertEqual([str(r["DISETOR"]) for r in sheets["REKAP"]], ["800", "50"])
        # Kolom lain tetap terbaca dari posisinya yang bergeser.
        self.assertEqual(str(sheets["REKAP"][0]["TOTAL_100_PERSEN"]), "1000")

    def test_judul_jenis_kosong_dibaca_dari_kolom_a(self):
        sheets, masalah = _baca(_file_judul_jenis_kosong())
        self.assertFalse([m for m in masalah if m["galat"]], masalah)
        self.assertEqual([(m["jenis"], m["kolom"], m["sel"]) for m in masalah],
                         [("kolom_tanpa_judul", "JENIS", "A1")])
        lengkap, _ = _baca(_file_lengkap())
        self.assertEqual(sheets["REKAP"], lengkap["REKAP"])  # isi persis sama

    def test_a1_dipakai_judul_lain_tidak_ditebak(self):
        # A1 berisi judul kontrak lain -> JENIS tidak ditebak dari posisi.
        isi = _xlsx(["DISETOR", None, "TOTAL 100 PERSEN", "DIKELOLA KANWIL", "PEMBULATAN SETOR"],
                    [(800, "NOMINAL IFQ", 1000, 200, 800)])
        sheets, masalah = _baca(isi)
        self.assertEqual([m["jenis"] for m in masalah], ["kolom_opsional_hilang"])
        self.assertIsNone(sheets["REKAP"][0]["JENIS"])

    def test_kolom_wajib_lain_tetap_wajib(self):
        isi = _xlsx(["JENIS", "TOTAL 100 PERSEN", "DIKELOLA KANWIL", "PEMBULATAN SETOR"],
                    [("CAD", 1, 2, 3)])
        _, masalah = _baca(isi)
        self.assertEqual([(m["jenis"], m["kolom"], m["galat"]) for m in masalah],
                         [("kolom_hilang", "DISETOR", True)])

    def test_jenis_hilang_dicatat_sebagai_warning(self):
        _, masalah = _baca(_file_tanpa_kolom_jenis())
        with self.assertLogs(el.log, level="WARNING") as cm:
            for m in masalah:
                el._log_masalah(m)
        self.assertEqual([r.levelno for r in cm.records], [logging.WARNING])
        self.assertIn("kolom_opsional_hilang", cm.output[0])

    def test_rekap_telegram_menulis_catatan(self):
        for isi, kata in ((_file_tanpa_kolom_jenis(), "tidak ada, dimuat kosong"),
                          (_file_judul_jenis_kosong(), "isinya tetap dibaca")):
            _, masalah = _baca(isi)
            hasil = {"ok": True, "dataset": "finance", "kantor": [{
                "kantor": "A1", "ok": True, "masalah": [{**m, "file": "finance.xlsx"} for m in masalah],
                "tabel": [{"tabel": "raw_finance_rekap_a1", "status": "dimuat", "baris": 2, "tarikan": 1}],
            }]}
            teks = rm.susun(hasil)
            self.assertIn(kata, teks)
            self.assertNotIn("Ditolak", teks)


@unittest.skipUnless(os.getenv("TEST_DB_HOST"), "TEST_DB_HOST tidak di-set")
class UjungKeUjung(unittest.TestCase):
    """process_source -> INSERT ke Postgres, dengan WebDAV diganti file lokal."""

    def setUp(self):
        import psycopg2
        self.conn = psycopg2.connect(host=os.environ["TEST_DB_HOST"],
                                     port=int(os.getenv("TEST_DB_PORT", "5432")),
                                     dbname=os.getenv("TEST_DB_NAME", "postgres"),
                                     user=os.getenv("TEST_DB_USER", "postgres"),
                                     password=os.getenv("TEST_DB_PASSWORD", "postgres"))
        self.schema = f"tes_{uuid.uuid4().hex[:8]}"
        with self.conn, self.conn.cursor() as cur:
            cur.execute(f"CREATE SCHEMA {self.schema}")
        self._asli = (el.DB_SCHEMA, el.list_xlsx, el.download)
        el.DB_SCHEMA = self.schema

    def tearDown(self):
        el.DB_SCHEMA, el.list_xlsx, el.download = self._asli
        with self.conn, self.conn.cursor() as cur:
            cur.execute(f"DROP SCHEMA {self.schema} CASCADE")
        self.conn.close()

    def _muat(self, isi, kantor="A1"):
        el.list_xlsx = lambda folder: ["finance.xlsx"]
        el.download = lambda folder, nama: isi
        return el.process_source(self.conn, f"/Geo/{kantor}/Finance")

    def _jenis(self, kantor):
        with self.conn, self.conn.cursor() as cur:
            cur.execute(f'SELECT "JENIS", "DISETOR" FROM {self.schema}.raw_finance_rekap_{kantor} '
                        f'ORDER BY "DISETOR" DESC')
            return [(j, int(d)) for j, d in cur.fetchall()]

    def test_tiga_kasus(self):
        for kantor, isi, harap in (
            ("a1", _file_lengkap(), [("NOMINAL IFQ", 800), ("CAD", 50)]),
            ("a2", _file_tanpa_kolom_jenis(), [(None, 800), (None, 50)]),
            ("a3", _file_judul_jenis_kosong(), [("NOMINAL IFQ", 800), ("CAD", 50)]),
        ):
            hasil = self._muat(isi, kantor.upper())
            self.assertTrue(hasil["ok"], hasil)
            self.assertEqual({t["status"] for t in hasil["tabel"]}, {"dimuat"})
            self.assertEqual(self._jenis(kantor), harap)


if __name__ == "__main__":
    unittest.main()
