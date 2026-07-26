{% macro source_relation_exists(relation) %}
{#
    Cek apakah tabel raw sudah benar-benar ada di Postgres.
    Sumber dengan kantor yang belum disinkronkan oleh Airbyte belum punya
    tabel fisiknya sama sekali (bukan cuma tabel kosong), jadi mereferensikan
    source() secara langsung akan gagal dengan "relation does not exist".

    adapter.get_relation() mengembalikan None saat execute==False (dbt parse/ls)
    maupun saat tabel tidak ada, sehingga tidak perlu guard execute manual.
#}
    {% set existing = adapter.get_relation(
        database=relation.database,
        schema=relation.schema,
        identifier=relation.identifier
    ) %}
    {{ return(existing is not none) }}
{% endmacro %}


{% macro stg_finance_rekap(kantor_id) %}
{#
    Staging untuk raw_<kantor_id>_finance_rekap.

    Kolom mengikuti file finance apa adanya: JENIS, DISETOR, DIKELOLA_KANWIL,
    PEMBULATAN_SETOR, TOTAL_100_PERSEN.

    Hanya penarikan data terakhir yang ditampilkan (MAX(_airbyte_extracted_at)).

    Jika tabel raw kantor tersebut belum ada, kembalikan result set kosong
    dengan kolom & tipe yang sama persis, supaya UNION ALL di mart tidak pernah patah.
#}
    {% set src = source('raw', 'raw_finance_rekap_' ~ kantor_id) %}
    {% if source_relation_exists(src) %}
WITH latest_pull AS (
    SELECT MAX(_airbyte_extracted_at) AS last_extracted_at
    FROM {{ src }}
)
SELECT
    '{{ kantor_id | upper }}' AS kantor_id,
    r."JENIS" AS jenis,
    r."DISETOR" AS disetor,
    r."DIKELOLA_KANWIL" AS dikelola_kanwil,
    r."PEMBULATAN_SETOR" AS pembulatan_setor,
    r."TOTAL_100_PERSEN" AS total_100_persen
FROM {{ src }} r
INNER JOIN latest_pull lp
    ON r._airbyte_extracted_at = lp.last_extracted_at
    {% else %}
SELECT
    '{{ kantor_id | upper }}'::varchar AS kantor_id,
    NULL::varchar AS jenis,
    NULL::numeric AS disetor,
    NULL::numeric AS dikelola_kanwil,
    NULL::numeric AS pembulatan_setor,
    NULL::numeric AS total_100_persen
WHERE FALSE
    {% endif %}
{% endmacro %}


{% macro stg_finance_rincian(kantor_id) %}
{#
    Staging untuk raw_<kantor_id>_finance_rincian.

    Kolom mengikuti file finance apa adanya: INSTANSI + TUNAI_* + NOMINAL_*
    (10 jenis: FI, ZF, AQQ, FDY, IFQ, LQT, SDQ, SNK, TDY, ZKT), KECUALI
    WAJIB_IFQ yang tidak ada di file finance melainkan diturunkan dari data
    capil (raw_<kantor_id>): jumlah warga per instansi (LMG) dengan
    Status_Tabungan = 'Paham'.

    Hanya penarikan data terakhir yang ditampilkan: baris difilter ke
    MAX(_airbyte_extracted_at). Jadi jika dalam sebulan ada beberapa kali
    penarikan (sync), hanya batch paling akhir yang muncul — memakai
    _airbyte_extracted_at, bukan _airbyte_generation_id, karena beberapa sync
    bisa berbagi generation yang sama saat mode-nya append.

    Jika tabel raw kantor tersebut belum ada, kembalikan result set kosong
    dengan kolom & tipe yang sama persis, supaya UNION ALL di mart tidak pernah patah.
#}
    {% set src = source('raw', 'raw_finance_rincian_' ~ kantor_id) %}
    {% set capil = source('raw', 'raw_' ~ kantor_id) %}
    {% if source_relation_exists(src) %}
    {% set capil_exists = source_relation_exists(capil) %}
WITH latest_pull AS (
    SELECT MAX(_airbyte_extracted_at) AS last_extracted_at
    FROM {{ src }}
)
{%- if capil_exists %},
wajib_ifq_calc AS (
    SELECT
        c."LMG" AS instansi,
        COUNT(*) AS wajib_ifq
    FROM {{ capil }} c
    INNER JOIN (
        SELECT MAX(_airbyte_extracted_at) AS last_extracted_at FROM {{ capil }}
    ) cg ON c._airbyte_extracted_at = cg.last_extracted_at
    WHERE c."Status_Tabungan" = 'Paham'
    GROUP BY c."LMG"
)
{%- endif %}
SELECT
    '{{ kantor_id | upper }}' AS kantor_id,
    r."INSTANSI" AS instansi,

    {% if capil_exists %}COALESCE(w.wajib_ifq, 0)::numeric{% else %}NULL::numeric{% endif %} AS wajib_ifq,

    r."TUNAI_FI" AS tunai_fi,
    r."TUNAI_ZF" AS tunai_zf,
    r."TUNAI_AQQ" AS tunai_aqq,
    r."TUNAI_FDY" AS tunai_fdy,
    r."TUNAI_IFQ" AS tunai_ifq,
    r."TUNAI_LQT" AS tunai_lqt,
    r."TUNAI_SDQ" AS tunai_sdq,
    r."TUNAI_SNK" AS tunai_snk,
    r."TUNAI_TDY" AS tunai_tdy,
    r."TUNAI_ZKT" AS tunai_zkt,

    r."NOMINAL_FI" AS nominal_fi,
    r."NOMINAL_ZF" AS nominal_zf,
    r."NOMINAL_AQQ" AS nominal_aqq,
    r."NOMINAL_FDY" AS nominal_fdy,
    r."NOMINAL_IFQ" AS nominal_ifq,
    r."NOMINAL_LQT" AS nominal_lqt,
    r."NOMINAL_SDQ" AS nominal_sdq,
    r."NOMINAL_SNK" AS nominal_snk,
    r."NOMINAL_TDY" AS nominal_tdy,
    r."NOMINAL_ZKT" AS nominal_zkt
FROM {{ src }} r
INNER JOIN latest_pull lp
    ON r._airbyte_extracted_at = lp.last_extracted_at
{%- if capil_exists %}
LEFT JOIN wajib_ifq_calc w
    ON w.instansi = r."INSTANSI"
{%- endif %}
    {% else %}
SELECT
    '{{ kantor_id | upper }}'::varchar AS kantor_id,
    NULL::varchar AS instansi,

    NULL::numeric AS wajib_ifq,

    NULL::numeric AS tunai_fi,
    NULL::numeric AS tunai_zf,
    NULL::numeric AS tunai_aqq,
    NULL::numeric AS tunai_fdy,
    NULL::numeric AS tunai_ifq,
    NULL::numeric AS tunai_lqt,
    NULL::numeric AS tunai_sdq,
    NULL::numeric AS tunai_snk,
    NULL::numeric AS tunai_tdy,
    NULL::numeric AS tunai_zkt,

    NULL::numeric AS nominal_fi,
    NULL::numeric AS nominal_zf,
    NULL::numeric AS nominal_aqq,
    NULL::numeric AS nominal_fdy,
    NULL::numeric AS nominal_ifq,
    NULL::numeric AS nominal_lqt,
    NULL::numeric AS nominal_sdq,
    NULL::numeric AS nominal_snk,
    NULL::numeric AS nominal_tdy,
    NULL::numeric AS nominal_zkt
WHERE FALSE
    {% endif %}
{% endmacro %}
