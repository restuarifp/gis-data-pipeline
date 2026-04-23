WITH latest_gen AS (
    SELECT MAX(_airbyte_generation_id) AS last_gen
    FROM {{ source('raw', 'raw_a3') }}
)
SELECT
    {{ dbt_utils.star(
        source('raw', 'raw_a3'),
        except=[
            'No_'
        ]
    ) }},
    CAST(r."No_" AS NUMERIC),
    'A3' AS kantor_id
FROM {{ source('raw', 'raw_a3') }} r
INNER JOIN latest_gen lg 
    ON r._airbyte_generation_id = lg.last_gen
