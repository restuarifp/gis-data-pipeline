WITH latest_gen AS (
    SELECT MAX(_airbyte_generation_id) AS last_gen
    FROM {{ source('raw', 'raw_c4') }}
)
SELECT
    r.*,
    'C4' AS kantor_id
FROM {{ source('raw', 'raw_c4') }} r
INNER JOIN latest_gen lg 
    ON r._airbyte_generation_id = lg.last_gen
