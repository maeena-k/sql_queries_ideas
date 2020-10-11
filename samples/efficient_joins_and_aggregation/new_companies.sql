-- Delete duplicate rows in company table
WITH company_summary AS (
    SELECT
        company_code,
        founder
    FROM
        company
    GROUP BY
        company_code,
        founder
),

-- Delete duplicate rows in lead_manager_table
-- Count the number of lead managers for each company
lead_manager_summary AS (
    SELECT
        t.company_code,
        count(*) AS lead_manager_count
    FROM
        (
            SELECT
                company_code,
                lead_manager_code
            FROM
                lead_manager
            GROUP BY
                company_code,
                lead_manager_code
        ) t
    GROUP BY
        t.company_code
),

-- Delete duplicate rows in senior_manager_table
-- Count the number of senior managers for each company
senior_manager_summary AS (
    SELECT
        t.company_code,
        count(*) AS senior_manager_count
    FROM
        (
            SELECT
                company_code,
                senior_manager_code
            FROM
                senior_manager
            GROUP BY
                company_code,
                senior_manager_code
        ) t
    GROUP BY
        t.company_code
),

-- Delete duplicate rows in manager_table
-- Count the number of managers for each company
manager_summary AS (
    SELECT
        t.company_code,
        count(*) AS manager_count
    FROM
        (
            SELECT
                company_code,
                manager_code
            FROM
                manager
            GROUP BY
                company_code,
                manager_code
        ) t
    GROUP BY
        t.company_code
),

-- Delete duplicate rows in employee_table
-- Count the number of employees for each company
employee_summary AS (
    SELECT
        t.company_code,
        count(*) AS employee_count
    FROM
        (
            SELECT
                company_code,
                employee_code
            FROM
                employee
            GROUP BY
                company_code,
                employee_code
        ) t
    GROUP BY
        t.company_code
)

-- Final output
SELECT
    c.company_code,
    c.founder,
    isnull(lm.lead_manager_count, 0),
    isnull(sm.senior_manager_count, 0),
    isnull(m.manager_count, 0),
    isnull(e.employee_count, 0)
FROM
    company_summary AS c
    LEFT JOIN lead_manager_summary AS lm ON lm.company_code = c.company_code
    LEFT JOIN senior_manager_summary AS sm ON sm.company_code = c.company_code
    LEFT JOIN manager_summary AS m ON m.company_code = c.company_code
    LEFT JOIN employee_summary AS e ON e.company_code = c.company_code
ORDER BY
    c.company_code ASC
;
