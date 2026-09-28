# Write your MySQL query statement below
WITH RankedScores AS (
    SELECT
        student_id,
        subject,
        score,
        exam_date,
        ROW_NUMBER() OVER (
            PARTITION BY student_id, subject
            ORDER BY exam_date ASC
        ) AS first_rank,
        ROW_NUMBER() OVER (
            PARTITION BY student_id, subject
            ORDER BY exam_date DESC
        ) AS latest_rank
    FROM Scores
)

SELECT
    f.student_id,
    f.subject,
    f.score AS first_score,
    l.score AS latest_score
FROM RankedScores f
JOIN RankedScores l
    ON f.student_id = l.student_id
    AND f.subject = l.subject
WHERE f.first_rank = 1
  AND l.latest_rank = 1
  AND l.score > f.score
ORDER BY f.student_id, f.subject;