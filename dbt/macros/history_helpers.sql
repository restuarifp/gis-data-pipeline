{% macro hist_pulls(pola, kolom, filter=none) %}
{#
    Gabungan SEMUA tarikan Airbyte dari setiap tabel raw yang namanya cocok
    dengan `pola` (regex; grup pertama = kantor_id), untuk Laporan Rekap
    Bulanan yang harus bisa memotret bulan mana pun.

    Beda dengan staging: staging hanya menyimpan tarikan terakhir
    (MAX(_airbyte_generation_id)), sedangkan di sini setiap baris membawa
      tarikan_id   = _airbyte_generation_id
      ditarik_pada = waktu tarikan itu (MIN _airbyte_extracted_at se-generation)
    supaya pemakainya bisa memilih "tarikan terakhir sebelum akhir bulan X".
    Ini hanya bermakna karena koneksi Airbyte-nya memakai mode Append; di mode
    Overwrite raw hanya punya satu tarikan dan hasilnya sama dengan staging.

    ditarik_pada dihitung per generation, bukan per baris: satu batch yang sama
    bisa menghasilkan _airbyte_extracted_at berbeda antar baris.

    Baris ber-_airbyte_extracted_at epoch (1970-01-01) dibuang — Airbyte
    meninggalkan satu baris seperti itu di generation 0 beberapa tabel, dan
    tanggal itu akan membuatnya lolos sebagai "tarikan" untuk bulan mana pun.

    Kantor diambil dari sources.yml, jadi kantor baru ikut otomatis begitu
    tabel raw-nya dideklarasikan di sana. Tabel yang belum ada fisiknya
    dilewati (source_relation_exists); kalau tidak ada satu pun, hasilnya
    kosong dengan kolom & tipe yang sama.

    kolom: daftar [ekspresi atas alias r, alias, tipe]. Tipe hanya dipakai
    untuk cabang kosong, dan harus sama dengan tipe kolom raw-nya.
#}
    {# graph.sources baru terisi saat execute; saat parse cukup cabang kosong. #}
    {% set cocok = [] %}
    {% set semua = graph.sources.values() if execute else [] %}
    {% for node in semua | sort(attribute='name') %}
        {% set m = modules.re.match(pola, node.name) %}
        {% if node.source_name == 'raw' and m %}
            {% set rel = source('raw', node.name) %}
            {% if source_relation_exists(rel) %}
                {% do cocok.append((m.group(1), rel)) %}
            {% endif %}
        {% endif %}
    {% endfor %}

    {% if cocok %}
        {% for kantor_id, rel in cocok %}
SELECT
    '{{ kantor_id | upper }}'::varchar AS kantor_id,
    r._airbyte_generation_id AS tarikan_id,
    r.ditarik_pada,
    {%- for ekspresi, alias, tipe in kolom %}
    {{ ekspresi }} AS {{ alias }}{{ "," if not loop.last }}
    {%- endfor %}
FROM (
    SELECT
        t.*,
        MIN(t._airbyte_extracted_at) OVER (PARTITION BY t._airbyte_generation_id)
            AS ditarik_pada
    FROM {{ rel }} t
    WHERE t._airbyte_extracted_at > TIMESTAMPTZ '1970-01-02 00:00:00+00'
) r
{%- if filter %}
WHERE {{ filter }}
{%- endif %}
            {% if not loop.last %}
UNION ALL
            {% endif %}
        {% endfor %}
    {% else %}
SELECT
    NULL::varchar AS kantor_id,
    NULL::bigint AS tarikan_id,
    NULL::timestamptz AS ditarik_pada,
    {%- for ekspresi, alias, tipe in kolom %}
    NULL::{{ tipe }} AS {{ alias }}{{ "," if not loop.last }}
    {%- endfor %}
WHERE FALSE
    {% endif %}
{% endmacro %}
