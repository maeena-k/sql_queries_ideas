-- Set index number for each row
WITH temp1 AS (
    SELECT
        lat_n,
        row_number() over (
            ORDER BY
                lat_n ASC
        ) AS index_num
    FROM
        station
),

-- Count max row index number
temp2 AS (
    SELECT
        lat_n,
        index_num,
        max(index_num) over () AS index_num_max
    FROM
        temp1
),

-- Find median number from index
-- Set a flag based on whether the max index number is even or odd 
temp3 AS (
    SELECT
        lat_n,
        index_num,
        index_num_max / 2 AS half_percentile,
        CASE
            WHEN index_num_max % 2 = 0 THEN 'even'
            ELSE 'odd'
        END AS row_count_category
    FROM
        temp2
),

-- Calculate the target lat n based on the flag
temp4 AS (
    SELECT
        CASE
            WHEN row_count_category = 'even' THEN avg(lat_n) over ()
            WHEN row_count_category = 'odd' THEN max(lat_n) over ()
        END AS target_lat_n
    FROM
        temp3
    WHERE
        index_num IN (half_percentile, half_percentile + 1)
)

-- Format the number
SELECT
    DISTINCT(cast(round(target_lat_n, 4) AS decimal(10, 4))) AS output_decimal
FROM
    temp4;
