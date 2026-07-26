WITH latest_pull AS (
    SELECT MAX(_airbyte_extracted_at) AS last_extracted_at
    FROM {{ source('raw', 'raw_b2') }}
)
SELECT
    {{ dbt_utils.star(
        source('raw', 'raw_b2'),
        except=[
            'No_',
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
    'B2' AS kantor_id
FROM {{ source('raw', 'raw_b2') }} r
INNER JOIN latest_pull lp
    ON r._airbyte_extracted_at = lp.last_extracted_at
WHERE r."K" IS NOT NULL