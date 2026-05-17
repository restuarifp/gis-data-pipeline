WITH latest_gen AS (
    SELECT MAX(_airbyte_generation_id) AS last_gen
    FROM {{ source('raw', 'raw_c2') }}
)
SELECT
    {{ dbt_utils.star(
        source('raw', 'raw_c2'),
        except=[
            'No_',
            '_airbyte_raw_id',
            '_airbyte_extracted_at',
            '_airbyte_meta',
            '_airbyte_generation_id',
            'Alamat_Negara',
            'Alamat_Kabupaten',
            'Alamat_Kecamatan',
        ]
    ) }},
    LOWER(r."Alamat_Negara") AS "Alamat_Negara",
    LOWER(r."Alamat_Kabupaten") AS "Alamat_Kabupaten",
    LOWER(r."Alamat_Kecamatan") AS "Alamat_Kecamatan",
    'C2' AS kantor_id
FROM {{ source('raw', 'raw_c2') }} r
INNER JOIN latest_gen lg 
    ON r._airbyte_generation_id = lg.last_gen
WHERE r."K" IS NOT NULL