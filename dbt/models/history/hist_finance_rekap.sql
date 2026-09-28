{#
    Semua tarikan finance rekap, semua kantor — kolomnya sama dengan
    stg_finance_rekap (macros/finance_helpers.sql).
#}
{{ hist_pulls(
    '^raw_finance_rekap_([a-z][0-9]+)$',
    [
        ['r."JENIS"',            'jenis',            'varchar'],
        ['r."DISETOR"',          'disetor',          'numeric'],
        ['r."DIKELOLA_KANWIL"',  'dikelola_kanwil',  'numeric'],
        ['r."PEMBULATAN_SETOR"', 'pembulatan_setor', 'numeric'],
        ['r."TOTAL_100_PERSEN"', 'total_100_persen', 'numeric'],
    ],
) }}
