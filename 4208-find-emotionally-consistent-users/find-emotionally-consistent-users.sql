# Write your MySQL query statement below

WITH t AS (
    SELECT
        user_id,
        reaction,
        COUNT(*) AS cnt
    FROM reactions
    GROUP BY user_id, reaction
),
s AS (
    SELECT
        user_id,
        MAX(cnt) AS mx_cnt,
        SUM(cnt) AS total_cnt,
        ROUND(MAX(cnt) / SUM(cnt), 2) AS reaction_ratio
    FROM t
    GROUP BY user_id
    HAVING SUM(cnt) >= 5
       AND MAX(cnt) / SUM(cnt) >= 0.60
)
SELECT
    s.user_id,
    t.reaction AS dominant_reaction,
    s.reaction_ratio
FROM s
JOIN t
    ON s.user_id = t.user_id
   AND s.mx_cnt = t.cnt
ORDER BY
    s.reaction_ratio DESC,
    s.user_id ASC;
