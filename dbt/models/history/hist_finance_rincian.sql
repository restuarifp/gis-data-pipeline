{#
    Semua tarikan finance rincian, semua kantor — kolomnya sama dengan
    stg_finance_rincian (macros/finance_helpers.sql), KECUALI wajib_ifq: kolom
    itu diturunkan dari capil tarikan terakhir, dan tidak punya padanan yang
    jujur untuk tarikan lama. Sengaja tidak ada daripada ada tapi salah.
#}
{{ hist_pulls(
    '^raw_finance_rincian_([a-z][0-9]+)$',
    [
        ['r."INSTANSI"', 'instansi', 'varchar'],
        ['r."TUNAI_FI"', 'tunai_fi', 'numeric'],
        ['r."TUNAI_ZF"', 'tunai_zf', 'numeric'],
        ['r."TUNAI_AQQ"', 'tunai_aqq', 'numeric'],
        ['r."TUNAI_FDY"', 'tunai_fdy', 'numeric'],
        ['r."TUNAI_IFQ"', 'tunai_ifq', 'numeric'],
        ['r."TUNAI_LQT"', 'tunai_lqt', 'numeric'],
        ['r."TUNAI_SDQ"', 'tunai_sdq', 'numeric'],
        ['r."TUNAI_SNK"', 'tunai_snk', 'numeric'],
        ['r."TUNAI_TDY"', 'tunai_tdy', 'numeric'],
        ['r."TUNAI_ZKT"', 'tunai_zkt', 'numeric'],
        ['r."NOMINAL_FI"', 'nominal_fi', 'numeric'],
        ['r."NOMINAL_ZF"', 'nominal_zf', 'numeric'],
        ['r."NOMINAL_AQQ"', 'nominal_aqq', 'numeric'],
        ['r."NOMINAL_FDY"', 'nominal_fdy', 'numeric'],
        ['r."NOMINAL_IFQ"', 'nominal_ifq', 'numeric'],
        ['r."NOMINAL_LQT"', 'nominal_lqt', 'numeric'],
        ['r."NOMINAL_SDQ"', 'nominal_sdq', 'numeric'],
        ['r."NOMINAL_SNK"', 'nominal_snk', 'numeric'],
        ['r."NOMINAL_TDY"', 'nominal_tdy', 'numeric'],
        ['r."NOMINAL_ZKT"', 'nominal_zkt', 'numeric'],
    ],
) }}
