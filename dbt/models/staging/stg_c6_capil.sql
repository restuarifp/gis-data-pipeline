WITH latest_gen AS (
    SELECT MAX(_airbyte_generation_id) AS last_gen
    FROM {{ source('raw', 'raw_c6') }}
)
SELECT
    {{ dbt_utils.star(
        source('raw', 'raw_c6'),
        except=[
            'No_',
            '_airbyte_raw_id',
            '_airbyte_extracted_at',
            '_airbyte_meta',
            '_airbyte_generation_id',
        ]
    ) }},
    'C6' AS kantor_id
FROM {{ source('raw', 'raw_c6') }} r
INNER JOIN latest_gen lg 
    ON r._airbyte_generation_id = lg.last_gen
