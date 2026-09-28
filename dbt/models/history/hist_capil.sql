{#
    Semua tarikan capil, semua kantor — dipakai Laporan Rekap Bulanan untuk
    memotret bulan tertentu. Kolomnya sama dengan analytics.stg_all_capil;
    filter K IS NOT NULL sama dengan stg_<kantor>_capil.
#}
{{ hist_pulls(
    '^raw_([a-z][0-9]+)$',
    [
        ['r."K"',                '"K"',                'varchar'],
        ['r."JK"',               '"JK"',               'varchar'],
        ['r."LMG"',              '"LMG"',              'varchar'],
        ['r."Th_Integrasi"',     '"Th_Integrasi"',     'varchar'],
        ['r."Bln_Integrasi"',    '"Bln_Integrasi"',    'varchar'],
        ['r."Status_Aktivitas"', '"Status_Aktivitas"', 'varchar'],
        ['r."Status_Tabungan"',  '"Status_Tabungan"',  'varchar'],
    ],
    filter='r."K" IS NOT NULL',
) }}
