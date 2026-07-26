SELECT * FROM {{ ref('stg_a1_finance_rincian') }}
UNION ALL
SELECT * FROM {{ ref('stg_a2_finance_rincian') }}
UNION ALL
SELECT * FROM {{ ref('stg_a3_finance_rincian') }}
UNION ALL
SELECT * FROM {{ ref('stg_b1_finance_rincian') }}
UNION ALL
SELECT * FROM {{ ref('stg_b2_finance_rincian') }}
UNION ALL
SELECT * FROM {{ ref('stg_b3_finance_rincian') }}
UNION ALL
SELECT * FROM {{ ref('stg_b4_finance_rincian') }}
UNION ALL
SELECT * FROM {{ ref('stg_b5_finance_rincian') }}
UNION ALL
SELECT * FROM {{ ref('stg_c1_finance_rincian') }}
UNION ALL
SELECT * FROM {{ ref('stg_c2_finance_rincian') }}
UNION ALL
SELECT * FROM {{ ref('stg_c3_finance_rincian') }}
UNION ALL
SELECT * FROM {{ ref('stg_c4_finance_rincian') }}
UNION ALL
SELECT * FROM {{ ref('stg_c5_finance_rincian') }}
UNION ALL
SELECT * FROM {{ ref('stg_c6_finance_rincian') }}
UNION ALL
SELECT * FROM {{ ref('stg_tester_finance_rincian') }}
