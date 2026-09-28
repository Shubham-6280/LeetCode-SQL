WITH RECURSIVE chars AS (
    SELECT
        content_id,
        content_text,
        1 AS pos,
        SUBSTRING(content_text, 1, 1) AS ch,
        1 AS word_no
    FROM user_content

    UNION ALL

    SELECT
        content_id,
        content_text,
        pos + 1,
        SUBSTRING(content_text, pos + 1, 1),
        CASE
            WHEN SUBSTRING(content_text, pos + 1, 1) = ' '
                THEN word_no + 1
            ELSE word_no
        END
    FROM chars
    WHERE pos < LENGTH(content_text)
),

words AS (
    SELECT
        content_id,
        word_no,
        GROUP_CONCAT(ch ORDER BY pos SEPARATOR '') AS word,
        MIN(pos) AS start_pos
    FROM chars
    WHERE ch <> ' '
    GROUP BY content_id, word_no
),

processed AS (
    SELECT
        c.content_id,
        c.pos,
        c.ch,

        CASE

            /* Spaces stay unchanged */
            WHEN c.ch = ' ' THEN ' '

            /* Word starts with non-letter:
               leave complete word unchanged */
            WHEN LEFT(w.word, 1) NOT REGEXP '[A-Za-z]'
                THEN c.ch

            /* Proper hyphenated word:
               capitalize first letter and letter after each hyphen */
            WHEN w.word REGEXP '^[A-Za-z]+(-[A-Za-z]+)+$'
                THEN
                    CASE
                        WHEN c.pos = w.start_pos
                            THEN UPPER(c.ch)

                        WHEN LAG(c.ch) OVER (
                            PARTITION BY c.content_id
                            ORDER BY c.pos
                        ) = '-'
                            THEN UPPER(c.ch)

                        WHEN c.ch REGEXP '[A-Za-z]'
                            THEN LOWER(c.ch)

                        ELSE c.ch
                    END

            /* Normal word */
            ELSE
                CASE
                    WHEN c.pos = w.start_pos
                        THEN UPPER(c.ch)

                    WHEN c.ch REGEXP '[A-Za-z]'
                        THEN LOWER(c.ch)

                    ELSE c.ch
                END
        END AS new_ch

    FROM chars c
    JOIN words w
        ON c.content_id = w.content_id
        AND c.word_no = w.word_no
)

SELECT
    u.content_id,
    u.content_text AS original_text,
    GROUP_CONCAT(
        p.new_ch
        ORDER BY p.pos
        SEPARATOR ''
    ) AS converted_text
FROM user_content u
JOIN processed p
    ON u.content_id = p.content_id
GROUP BY
    u.content_id,
    u.content_text
ORDER BY
    u.content_id;