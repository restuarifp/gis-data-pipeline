WITH latest_gen AS (
    SELECT MAX(_airbyte_generation_id) AS last_gen
    FROM {{ source('raw', 'raw_b2') }}
)
SELECT
    r.*,
    'B2' AS kantor_id
FROM {{ source('raw', 'raw_b2') }} r
INNER JOIN latest_gen lg 
    ON r._airbyte_generation_id = lg.last_gen
