SELECT * FROM {{ ref('stg_a1_capil') }}
UNION ALL
SELECT * FROM {{ ref('stg_a2_capil') }}
UNION ALL
SELECT * FROM {{ ref('stg_a3_capil') }}
UNION ALL
SELECT * FROM {{ ref('stg_b1_capil') }}
UNION ALL
SELECT * FROM {{ ref('stg_b2_capil') }}
UNION ALL
SELECT * FROM {{ ref('stg_b3_capil') }}
UNION ALL
SELECT * FROM {{ ref('stg_b4_capil') }}
UNION ALL
SELECT * FROM {{ ref('stg_b5_capil') }}
UNION ALL
SELECT * FROM {{ ref('stg_c1_capil') }}
UNION ALL
SELECT * FROM {{ ref('stg_c2_capil') }}
UNION ALL
SELECT * FROM {{ ref('stg_c3_capil') }}
UNION ALL
SELECT * FROM {{ ref('stg_c4_capil') }}
UNION ALL
SELECT * FROM {{ ref('stg_c5_capil') }}
UNION ALL
SELECT * FROM {{ ref('stg_c6_capil') }}
