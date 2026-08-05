WITH latest_pull AS (
    SELECT MAX(_airbyte_generation_id) AS last_generation_id
    FROM {{ source('raw', 'raw_b1') }}
)
SELECT
    {{ dbt_utils.star(
        source('raw', 'raw_b1'),
        except=[
            'No_',
            'null',
            '_airbyte_raw_id',
            '_airbyte_extracted_at',
            '_airbyte_meta',
            '_airbyte_generation_id',
            'Alamat_Negara',
            'Alamat_Kabupaten',
            'Alamat_Kecamatan',
            'Instansi_Pekerjaan',
            'Nama_Lengkap',
        ]
    ) }},
    LOWER(r."Alamat_Negara") AS "Alamat_Negara",
    LOWER(r."Alamat_Kabupaten") AS "Alamat_Kabupaten",
    LOWER(r."Alamat_Kecamatan") AS "Alamat_Kecamatan",
    'B1' AS kantor_id
FROM {{ source('raw', 'raw_b1') }} r
INNER JOIN latest_pull lp
    ON r._airbyte_generation_id = lp.last_generation_id
WHERE r."K" IS NOT NULL