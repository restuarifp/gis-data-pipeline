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
    Jika tabel raw kantor tersebut belum ada, kembalikan result set kosong
    dengan kolom & tipe yang sama persis, supaya UNION ALL di mart tidak pernah patah.
#}
    {% set src = source('raw', 'raw_' ~ kantor_id ~ '_finance_rekap') %}
    {% if source_relation_exists(src) %}
WITH latest_gen AS (
    SELECT MAX(_airbyte_generation_id) AS last_gen
    FROM {{ src }}
)
SELECT
    '{{ kantor_id | upper }}' AS kantor_id,
    r."JENIS" AS jenis,
    r."PERSEN_SETOR" AS persen_setor,
    r."TOTAL_TANPA_PEMBULATAN" AS total_tanpa_pembulatan,
    r."TOTAL_SETOR_DENGAN_PEMBULATAN" AS total_setor_dengan_pembulatan
FROM {{ src }} r
INNER JOIN latest_gen lg
    ON r._airbyte_generation_id = lg.last_gen
    {% else %}
SELECT
    '{{ kantor_id | upper }}'::varchar AS kantor_id,
    NULL::varchar AS jenis,
    NULL::numeric AS persen_setor,
    NULL::numeric AS total_tanpa_pembulatan,
    NULL::numeric AS total_setor_dengan_pembulatan
WHERE FALSE
    {% endif %}
{% endmacro %}


{% macro stg_finance_rincian(kantor_id) %}
{#
    Staging untuk raw_<kantor_id>_finance_rincian.
    Sama seperti stg_finance_rekap: fallback ke result set kosong jika
    tabel raw kantor tersebut belum tersedia.
#}
    {% set src = source('raw', 'raw_' ~ kantor_id ~ '_finance_rincian') %}
    {% if source_relation_exists(src) %}
WITH latest_gen AS (
    SELECT MAX(_airbyte_generation_id) AS last_gen
    FROM {{ src }}
)
SELECT
    '{{ kantor_id | upper }}' AS kantor_id,
    r."INSTANSI" AS instansi,
    r."JUMLAH_WARGA" AS jumlah_warga,

    r."WAJIB_IFQ" AS wajib_ifq,
    r."TUNAI_IFQ" AS tunai_ifq,
    r."NOMINAL_IFQ" AS nominal_ifq,

    r."WAJIB_FI" AS wajib_fi,
    r."TUNAI_FI" AS tunai_fi,
    r."NOMINAL_FI" AS nominal_fi,

    r."WAJIB_AQQ" AS wajib_aqq,
    r."TUNAI_AQQ" AS tunai_aqq,
    r."NOMINAL_AQQ" AS nominal_aqq,

    r."WAJIB_FDY" AS wajib_fdy,
    r."TUNAI_FDY" AS tunai_fdy,
    r."NOMINAL_FDY" AS nominal_fdy,

    r."WAJIB_LQT" AS wajib_lqt,
    r."TUNAI_LQT" AS tunai_lqt,
    r."NOMINAL_LQT" AS nominal_lqt,

    r."WAJIB_SDQ" AS wajib_sdq,
    r."TUNAI_SDQ" AS tunai_sdq,
    r."NOMINAL_SDQ" AS nominal_sdq,

    r."WAJIB_SNK" AS wajib_snk,
    r."TUNAI_SNK" AS tunai_snk,
    r."NOMINAL_SNK" AS nominal_snk,

    r."WAJIB_ZKT" AS wajib_zkt,
    r."TUNAI_ZKT" AS tunai_zkt,
    r."NOMINAL_ZKT" AS nominal_zkt,

    r."WAJIB_ZM" AS wajib_zm,
    r."TUNAI_ZM" AS tunai_zm,
    r."NOMINAL_ZM" AS nominal_zm,

    r."WAJIB_TDY" AS wajib_tdy,
    r."TUNAI_TDY" AS tunai_tdy,
    r."NOMINAL_TDY" AS nominal_tdy
FROM {{ src }} r
INNER JOIN latest_gen lg
    ON r._airbyte_generation_id = lg.last_gen
    {% else %}
SELECT
    '{{ kantor_id | upper }}'::varchar AS kantor_id,
    NULL::varchar AS instansi,
    NULL::numeric AS jumlah_warga,

    NULL::numeric AS wajib_ifq,
    NULL::numeric AS tunai_ifq,
    NULL::numeric AS nominal_ifq,

    NULL::numeric AS wajib_fi,
    NULL::numeric AS tunai_fi,
    NULL::numeric AS nominal_fi,

    NULL::numeric AS wajib_aqq,
    NULL::numeric AS tunai_aqq,
    NULL::numeric AS nominal_aqq,

    NULL::numeric AS wajib_fdy,
    NULL::numeric AS tunai_fdy,
    NULL::numeric AS nominal_fdy,

    NULL::numeric AS wajib_lqt,
    NULL::numeric AS tunai_lqt,
    NULL::numeric AS nominal_lqt,

    NULL::numeric AS wajib_sdq,
    NULL::numeric AS tunai_sdq,
    NULL::numeric AS nominal_sdq,

    NULL::numeric AS wajib_snk,
    NULL::numeric AS tunai_snk,
    NULL::numeric AS nominal_snk,

    NULL::numeric AS wajib_zkt,
    NULL::numeric AS tunai_zkt,
    NULL::numeric AS nominal_zkt,

    NULL::numeric AS wajib_zm,
    NULL::numeric AS tunai_zm,
    NULL::numeric AS nominal_zm,

    NULL::numeric AS wajib_tdy,
    NULL::numeric AS tunai_tdy,
    NULL::numeric AS nominal_tdy
WHERE FALSE
    {% endif %}
{% endmacro %}
