-- Set index_number for name by each occupation
WITH temp1 AS (
    SELECT
        *,
        row_number() over (
            PARTITION BY 
                occupation
            ORDER BY
                name ASC
        ) AS index_num
    FROM
        occupations
),

-- Calculate Max index_num
temp2 AS (
    SELECT
        *,
        max(index_num) over () AS max_index_num
    FROM
        temp1
),

-- Extract an occupation that has the max index_num
-- Create a table of index_num_list corresponding to the occupation
temp3 AS (
    SELECT
        index_num
    FROM
        temp1 t1
    WHERE
        EXISTS(
            SELECT
                *
            FROM
                temp2 t2
            WHERE
                t2.index_num = t2.max_index_num
                AND t1.occupation = t2.occupation
        )
),

-- Create Doctor table
temp4 AS (
    SELECT
        t1.name AS name_doctor,
        t3.index_num
    FROM
        temp3 t3
        LEFT JOIN (
            SELECT
                *
            FROM
                temp1
            WHERE
                occupation = 'Doctor'
        ) t1 ON t1.index_num = t3.index_num
),

--Create Professor table
temp5 AS (
    SELECT
        t1.name AS name_professor,
        t3.index_num
    FROM
        temp3 t3
        LEFT JOIN (
            SELECT
                *
            FROM
                temp1
            WHERE
                occupation = 'Professor'
        ) t1 ON t1.index_num = t3.index_num
),

-- Create Singer table
temp6 AS (
    SELECT
        t1.name AS name_singer,
        t3.index_num
    FROM
        temp3 t3
        LEFT JOIN (
            SELECT
                *
            FROM
                temp1
            WHERE
                occupation = 'Singer'
        ) t1 ON t1.index_num = t3.index_num
),

-- Create Actor table
temp7 AS (
    SELECT
        t1.name AS name_Actor,
        t3.index_num
    FROM
        temp3 t3
        LEFT JOIN (
            SELECT
                *
            FROM
                temp1
            WHERE
                occupation = 'Actor'
        ) t1 ON t1.index_num = t3.index_num
)

-- Final Output
SELECT
    name_doctor,
    name_professor,
    name_singer,
    name_Actor
FROM
    temp4 t4
    INNER JOIN temp5 t5 ON t5.index_num = t4.index_num
    INNER JOIN temp6 t6 ON t6.index_num = t4.index_num
    INNER JOIN temp7 t7 ON t7.index_num = t4.index_num
ORDER BY
    t4.index_num ASC;
