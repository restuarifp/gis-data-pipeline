{% macro source_relation_exists(relation) %}
{#
    Cek apakah tabel raw sudah benar-benar ada di Postgres.
    Sumber dengan kantor yang belum disinkronkan oleh Airbyte belum punya
    tabel fisiknya sama sekali (bukan cuma tabel kosong), jadi mereferensikan
    source() secara langsung akan gagal dengan "relation does not exist".

    execute == False saat `dbt parse` / `dbt ls` (tidak ada koneksi DB) -> selalu
    anggap tidak ada, supaya validasi offline tetap jalan tanpa DB.
#}
    {% if execute %}
        {% set query %}
            select 1
            from information_schema.tables
            where table_schema = '{{ relation.schema }}'
              and table_name = '{{ relation.identifier }}'
            limit 1
        {% endset %}
        {% set results = run_query(query) %}
        {{ return(results.rows | length > 0) }}
    {% else %}
        {{ return(false) }}
    {% endif %}
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
SELECT
    '{{ kantor_id | upper }}' AS kantor_id,
    r."TUNAI" AS tunai,
    r."WAJIB" AS wajib,
    r."NOMINAL" AS nominal,
    r."INSTANSI" AS instansi,
    r."TUNAI_FI" AS tunai_fi,
    r."TUNAI_AQQ" AS tunai_aqq,
    r."TUNAI_FDY" AS tunai_fdy,
    r."TUNAI_IFQ" AS tunai_ifq,
    r."TUNAI_LQT" AS tunai_lqt,
    r."TUNAI_SDQ" AS tunai_sdq,
    r."TUNAI_SNK" AS tunai_snk,
    r."TUNAI_ZKT" AS tunai_zkt,
    r."NOMINAL_FI" AS nominal_fi,
    r."NOMINAL_AQQ" AS nominal_aqq,
    r."NOMINAL_FDY" AS nominal_fdy,
    r."NOMINAL_IFQ" AS nominal_ifq,
    r."NOMINAL_LQT" AS nominal_lqt,
    r."NOMINAL_SDQ" AS nominal_sdq,
    r."NOMINAL_ZKT" AS nominal_zkt,
    r."JUMLAH_WAJIB" AS jumlah_wajib,
    r."JUMLAH_WARGA" AS jumlah_warga
FROM {{ src }} r
    {% else %}
SELECT
    '{{ kantor_id | upper }}'::varchar AS kantor_id,
    NULL::varchar AS tunai,
    NULL::varchar AS wajib,
    NULL::varchar AS nominal,
    NULL::varchar AS instansi,
    NULL::numeric AS tunai_fi,
    NULL::numeric AS tunai_aqq,
    NULL::numeric AS tunai_fdy,
    NULL::numeric AS tunai_ifq,
    NULL::numeric AS tunai_lqt,
    NULL::numeric AS tunai_sdq,
    NULL::numeric AS tunai_snk,
    NULL::numeric AS tunai_zkt,
    NULL::numeric AS nominal_fi,
    NULL::numeric AS nominal_aqq,
    NULL::numeric AS nominal_fdy,
    NULL::numeric AS nominal_ifq,
    NULL::numeric AS nominal_lqt,
    NULL::numeric AS nominal_sdq,
    NULL::numeric AS nominal_zkt,
    NULL::numeric AS jumlah_wajib,
    NULL::numeric AS jumlah_warga
WHERE FALSE
    {% endif %}
{% endmacro %}
