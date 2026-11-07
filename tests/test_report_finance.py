"""
Laporan keuangan: kolom PEMBULATAN, TOTAL SETOR, dan AKUMULASI CAD.

Jalankan (dari root repo, di image notif-relay supaya dependensinya sama):

    docker run --rm -v "$PWD":/repo -w /repo gis-data-pipeline-notif-relay \
        python -m unittest discover -s tests -v
"""

import io
import sys
import unittest
from datetime import datetime
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))

import report_finance as rf  # noqa: E402
from openpyxl import load_workbook  # noqa: E402


def _rec(cad, ditarik, **lain):
    rec = {"cad": cad, "ditarik_finance": ditarik, "pemb_wajib": 0,
           "pemb_sukarela": 0, "pemb_cad": 0}
    rec.update(lain)
    return rec


class TestNilaiBaris(unittest.TestCase):
    def test_total_setor_dari_tiga_pembulatan(self):
        n = rf._nilai_baris({"pemb_wajib": 57_960_000, "pemb_sukarela": 250_000,
                             "pemb_cad": 2_400_000, "cad": 2_390_886.09}, 0)
        self.assertEqual(n["setor"], 57_960_000 + 250_000 + 2_400_000)
        self.assertEqual(n["cad"], 2_390_886.09)

    def test_pembulatan_kosong_jadi_nol(self):
        n = rf._nilai_baris({"pemb_wajib": None, "pemb_sukarela": None, "pemb_cad": None}, 0)
        self.assertEqual(n["setor"], 0)

    def test_daftar_jenis_wajib(self):
        self.assertEqual(sorted(rf.JENIS_PEMBULATAN_WAJIB), sorted(
            f"NOMINAL {k}" for k in ("IFQ", "SDQ", "FDY", "AQQ", "FI", "LQT", "SNK", "TDY", "ZF")))
        self.assertNotIn("NOMINAL ZKT", rf.JENIS_PEMBULATAN_WAJIB)
        sql = rf.SQL
        self.assertIn("'NOMINAL ZF'", sql)
        self.assertNotIn("AS setor", sql)


class TestAkumulasiCad(unittest.TestCase):
    def test_kumulatif_dari_awal_menyeberang_tahun(self):
        data = {
            (2025, 12): {"A1": _rec(100, datetime(2025, 12, 31, 20))},
            (2026, 1):  {"A1": _rec(200, datetime(2026, 1, 31, 23))},
            (2026, 2):  {"A1": _rec(300, datetime(2026, 2, 28, 22))},
        }
        pb = rf.susun_per_bulan(data, ["A1"], 2026)
        self.assertNotIn(12, pb)                         # tahun lalu tidak ditulis
        self.assertEqual(pb[1]["A1"]["akumulasi_cad"], 300)   # 100 + 200
        self.assertEqual(pb[2]["A1"]["akumulasi_cad"], 600)

    def test_tarikan_lama_tidak_dihitung_dua_kali(self):
        # Maret tanpa tarikan baru: potret Februari dipakai, CAD-nya tidak ditambah.
        feb = _rec(300, datetime(2026, 2, 28, 22))
        data = {(2026, 2): {"A1": feb}, (2026, 3): {"A1": feb},
                (2026, 4): {"A1": _rec(50, datetime(2026, 4, 30, 8))}}
        pb = rf.susun_per_bulan(data, ["A1"], 2026)
        self.assertEqual(pb[3]["A1"]["cad"], 300)
        self.assertEqual(pb[3]["A1"]["akumulasi_cad"], 300)
        self.assertEqual(pb[4]["A1"]["akumulasi_cad"], 350)

    def test_per_kantor_terpisah(self):
        data = {(2026, 1): {"A1": _rec(10, datetime(2026, 1, 5)),
                            "B2": _rec(1, datetime(2026, 1, 6))},
                (2026, 2): {"A1": _rec(20, datetime(2026, 2, 5))}}
        pb = rf.susun_per_bulan(data, ["A1", "B2"], 2026)
        self.assertEqual(pb[2]["A1"]["akumulasi_cad"], 30)
        self.assertNotIn("B2", pb[2])


class TestLaporan(unittest.TestCase):
    """bangun_laporan() ujung ke ujung dengan ambil_data() dipalsukan."""

    def setUp(self):
        self._asli = (rf.ambil_data, rf.laporan_aktif, rf.rs._kunci_xlsx)
        rf.laporan_aktif = lambda: (True, "")
        rf.rs._kunci_xlsx = lambda b: b
        rf.ambil_data = lambda bulan, tahun: {
            (2026, 1): {"A1": _rec(100, datetime(2026, 1, 31), pemb_wajib=1000,
                                   pemb_sukarela=10, pemb_cad=100)},
            (2026, 2): {"A1": _rec(200, datetime(2026, 2, 27), pemb_wajib=2000,
                                   pemb_sukarela=20, pemb_cad=200)},
        }

    def tearDown(self):
        rf.ambil_data, rf.laporan_aktif, rf.rs._kunci_xlsx = self._asli

    def test_kolom_dan_total(self):
        isi, _, _ = rf.bangun_laporan(2, 2026)
        ws = load_workbook(io.BytesIO(isi)).active
        hdr = rf._cari_baris(ws, rf.LABEL_HEADER, 1)
        kol = rf._peta_kolom(ws, hdr)
        a1 = rf._cari_baris(ws, "A1", hdr + 1)
        self.assertEqual(ws[f"{kol['pemb_wajib']}{a1}"].value, 2000)
        self.assertEqual(ws[f"{kol['pemb_sukarela']}{a1}"].value, 20)
        self.assertEqual(ws[f"{kol['pemb_cad']}{a1}"].value, 200)
        self.assertEqual(ws[f"{kol['setor']}{a1}"].value, 2220)
        self.assertEqual(ws[f"{kol['akumulasi_cad']}{a1}"].value, 300)
        # Tabel bawah: TOTAL akumulasi = saldo bulan terakhir, bukan 100 + 300.
        judul = rf._cari_baris(ws, rf.LABEL_BULAN, a1)
        total = rf._cari_baris(ws, rf.LABEL_TOTAL, judul + 1)
        self.assertEqual(ws[f"{kol['akumulasi_cad']}{total}"].value, 300)
        self.assertEqual(ws[f"{kol['cad']}{total}"].value, 300)
        self.assertEqual(ws[f"{kol['setor']}{total}"].value, 1110 + 2220)


if __name__ == "__main__":
    unittest.main()
