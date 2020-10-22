-- Join tables to merge necessary columns into one table
WITH temp1 AS (
    SELECT
        s.challenge_id,
        s.hacker_id,
        h.name,
        c.difficulty_level,
        s.score
    FROM
        submissions s
        INNER JOIN hackers h ON h.hacker_id = s.hacker_id
        INNER JOIN challenges c ON c.challenge_id = s.challenge_id
),

-- Pick up hackers who earned a full score for each challenge
-- Count the number of challenges with full score
temp2 AS(
    SELECT
        hacker_id,
        name,
        count(*) AS submissions_count
    FROM
        temp1 t1
    WHERE
        EXISTS(
            SELECT
                *
            FROM
                difficulty d
            WHERE
                d.difficulty_level = t1.difficulty_level
                AND d.score = t1.score
        )
    GROUP BY
        hacker_id,
        name
)

-- Final Output
SELECT
    hacker_id,
    name
FROM
    temp2
WHERE
    submissions_count >= 2
ORDER BY
    submissions_count DESC,
    hacker_id ASC;