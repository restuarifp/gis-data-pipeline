SELECT * FROM {{ ref('stg_a1_capil') }}
UNION ALL
SELECT * FROM {{ ref('stg_a2_capil') }}
