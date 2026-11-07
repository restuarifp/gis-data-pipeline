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
    # AKUMULASI CAD menjumlah PEMBULATAN CAD; di tes ini sama dengan CAD
    # kecuali disebut lain.
    rec = {"cad": cad, "ditarik_finance": ditarik, "pemb_wajib": 0,
           "pemb_pokok": 0, "pemb_cad": cad}
    rec.update(lain)
    return rec


class TestNilaiBaris(unittest.TestCase):
    def test_total_setor_dari_tiga_pembulatan(self):
        # Data prod C1 Oktober 2026.
        n = rf._nilai_baris({"pemb_wajib": 32_000_000, "pemb_pokok": 1_480_000,
                             "pemb_cad": 1_420_000, "cad": 1_391_103}, 0)
        self.assertEqual(n["setor"], 34_900_000)
        self.assertEqual(n["cad"], 1_391_103)

    def test_pembulatan_kosong_jadi_nol(self):
        n = rf._nilai_baris({"pemb_wajib": None, "pemb_pokok": None, "pemb_cad": None}, 0)
        self.assertEqual(n["setor"], 0)

    def test_daftar_jenis_wajib(self):
        self.assertEqual(sorted(rf.JENIS_PEMBULATAN_WAJIB), sorted(
            f"NOMINAL {k}" for k in ("IFQ", "SDQ", "FDY", "AQQ", "FI", "LQT", "SNK", "TDY", "ZF")))
        self.assertNotIn("NOMINAL ZKT", rf.JENIS_PEMBULATAN_WAJIB)
        sql = rf.SQL
        self.assertIn("'NOMINAL ZF'", sql)
        self.assertIn("FILTER (WHERE j = 'NOMINAL ZKT') AS pemb_pokok", sql)
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

    def test_data_prod_c1(self):
        # Prod C1: saldo awal (generation 0) 62.245.000, lalu PEMBULATAN CAD
        # tarikan terakhir tiap bulan. Tarikan 1 Okt (1.405.000) tergantikan
        # tarikan 30 Okt (1.420.000). Angka acuan pengguna: 67.835.000.
        c1 = lambda cad, pemb, w: _rec(cad, w, pemb_cad=pemb)  # noqa: E731
        data = {
            (2026, 8):  {"C1": c1(1_278_396, 1_300_000, datetime(2026, 8, 8, 7, 14))},
            (2026, 9):  {"C1": c1(1_424_756.25, 1_450_000, datetime(2026, 9, 30, 12, 1))},
            (2026, 10): {"C1": c1(1_391_103, 1_420_000, datetime(2026, 10, 30, 20, 32))},
            (2026, 11): {"C1": c1(1_391_103, 1_420_000, datetime(2026, 11, 1, 0, 33))},
        }
        pb = rf.susun_per_bulan(data, ["C1"], 2026, {"C1": 62_245_000})
        self.assertEqual(pb[10]["C1"]["akumulasi_cad"], 66_415_000)
        self.assertEqual(pb[11]["C1"]["akumulasi_cad"], 67_835_000)

    def test_saldo_awal_tanpa_tarikan_bulan_itu(self):
        feb = _rec(300, datetime(2026, 2, 28))
        pb = rf.susun_per_bulan({(2026, 2): {"A1": feb}, (2026, 3): {"A1": feb}},
                                ["A1"], 2026, {"A1": 1000})
        self.assertEqual(pb[2]["A1"]["akumulasi_cad"], 1300)
        self.assertEqual(pb[3]["A1"]["akumulasi_cad"], 1300)

    def test_akumulasi_pakai_pembulatan_bukan_disetor(self):
        pb = rf.susun_per_bulan({(2026, 1): {"A1": _rec(99.5, datetime(2026, 1, 9),
                                                        pemb_cad=100)}}, ["A1"], 2026)
        self.assertEqual(pb[1]["A1"]["akumulasi_cad"], 100)


class TestLaporan(unittest.TestCase):
    """bangun_laporan() ujung ke ujung dengan ambil_data() dipalsukan."""

    def setUp(self):
        self._asli = (rf.ambil_data, rf.laporan_aktif, rf.rs._kunci_xlsx, rf.ambil_saldo_awal)
        rf.laporan_aktif = lambda: (True, "")
        rf.rs._kunci_xlsx = lambda b: b
        rf.ambil_saldo_awal = lambda: {"A1": 5000}
        rf.ambil_data = lambda bulan, tahun: {
            (2026, 1): {"A1": _rec(100, datetime(2026, 1, 31), pemb_wajib=1000,
                                   pemb_pokok=10, pemb_cad=100)},
            (2026, 2): {"A1": _rec(200, datetime(2026, 2, 27), pemb_wajib=2000,
                                   pemb_pokok=20, pemb_cad=200)},
        }

    def tearDown(self):
        rf.ambil_data, rf.laporan_aktif, rf.rs._kunci_xlsx, rf.ambil_saldo_awal = self._asli

    def test_kolom_dan_total(self):
        isi, _, _ = rf.bangun_laporan(2, 2026)
        ws = load_workbook(io.BytesIO(isi)).active
        hdr = rf._cari_baris(ws, rf.LABEL_HEADER, 1)
        kol = rf._peta_kolom(ws, hdr)
        a1 = rf._cari_baris(ws, "A1", hdr + 1)
        self.assertEqual(ws[f"{kol['pemb_wajib']}{a1}"].value, 2000)
        self.assertEqual(ws[f"{kol['pemb_pokok']}{a1}"].value, 20)
        self.assertEqual(ws[f"{kol['pemb_cad']}{a1}"].value, 200)
        self.assertEqual(ws[f"{kol['setor']}{a1}"].value, 2220)
        self.assertEqual(ws[f"{kol['akumulasi_cad']}{a1}"].value, 5300)
        # Tabel bawah: TOTAL akumulasi = saldo bulan terakhir, bukan jumlahnya.
        judul = rf._cari_baris(ws, rf.LABEL_BULAN, a1)
        total = rf._cari_baris(ws, rf.LABEL_TOTAL, judul + 1)
        self.assertEqual(ws[f"{kol['akumulasi_cad']}{total}"].value, 5300)
        self.assertEqual(ws[f"{kol['cad']}{total}"].value, 300)
        self.assertEqual(ws[f"{kol['setor']}{total}"].value, 1110 + 2220)


if __name__ == "__main__":
    unittest.main()
