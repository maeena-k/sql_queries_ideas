-- Join two tables and count challenges for each hacker
WITH temp1 AS (
    SELECT
        c.hacker_id,
        h.name,
        count(c.challenge_id) AS challenge_count
    FROM
        challenges AS c
        INNER JOIN hackers AS h ON h.hacker_id = c.hacker_id
    GROUP BY
        c.hacker_id,
        h.name
),

-- Calculate the max value of challenge count
-- Find the numbers of challenge count that have more than two hackers
temp2 AS (
    SELECT
        challenge_count,
        max(challenge_count) over () AS challenge_count_max,
        count(challenge_count) AS challenge_count_duplicate
    FROM
        temp1
    GROUP BY
        challenge_count
),

-- Extract the numbers of challenge count that have no duplication
-- Or the number is the max value
temp3 AS (
    SELECT
        challenge_count
    FROM
        temp2
    WHERE
        challenge_count_duplicate = 1
        OR challenge_count = challenge_count_max
)

-- Final Output
SELECT
    *
FROM
    temp1 AS t1
WHERE
    EXISTS(
        SELECT
            *
        FROM
            temp3 AS t3
        WHERE
            t1.challenge_count = t3.challenge_count
    )
ORDER BY
    challenge_count DESC,
    hacker_id ASC
