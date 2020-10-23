-- Calculate a maximum score for each challenge per hacker
WITH temp1 AS (
    SELECT
        s.hacker_id,
        h.name,
        s.score,
        row_number() over (
            PARTITION by
                s.hacker_id,
                s.challenge_id
            ORDER BY
                s.score DESC
        ) AS score_index
    FROM
        submissions s
        INNER JOIN hackers h ON h.hacker_id = s.hacker_id
),

-- Exclude 0 score or non maximum score
temp2 AS (
    SELECT
        hacker_id,
        name,
        sum(score) AS sum_score
    FROM
        temp1
    WHERE
        score > 0
        AND score_index = 1
    GROUP BY
        hacker_id,
        name
)

-- Final Output
SELECT
    *
FROM
    temp2
ORDER BY
    sum_score DESC,
    hacker_id ASC;
