-- Calculate task duration by days
-- Fetch end_date from the previous row
WITH temp1 AS (
    SELECT
        start_date,
        end_date,
        datediff(day, start_date, end_date) AS count_task_days,
        LAG(end_date) OVER (ORDER BY start_date) AS previous_end_date
    FROM
        projects
),

-- Add same project flag column 
temp2 AS (
    SELECT
        start_date,
        end_date,
        count_task_days,
        previous_end_date,
        CASE
            WHEN previous_end_date = start_date THEN 0
            ELSE 1
        END AS same_project_flag
    FROM
        temp1
),

-- Set project id column
temp3 AS (
    SELECT
        start_date,
        end_date,
        count_task_days,
        SUM(same_project_flag) OVER (ORDER BY start_date) AS project_id
    FROM
        temp2
),

-- Aggregate by project it
-- Calculate min & max date for each project
temp4 AS (
    SELECT
        project_id,
        MIN(start_date) AS start_date_min,
        MAX(end_date) AS end_date_max,
        SUM(count_task_days) AS count_project_days
    FROM
        temp3
    GROUP BY
        project_id
)

-- Final Output
SELECT  
    start_date_min,
    end_date_max
FROM
    temp4
ORDER BY
    count_project_days ASC, start_date_min ASC
;
