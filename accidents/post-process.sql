-- extract cross only
DROP TABLE IF EXISTS accident_hit;
CREATE TABLE IF NOT EXISTS accident_hit AS (
    SELECT
        *
    FROM
        accident
    WHERE
        "車道幅員" = 11
        OR "車道幅員" = 12
        OR "車道幅員" = 14
        OR "車道幅員" = 15
    ORDER BY
        random()
    LIMIT
        10
);

\COPY (SELECT xtile_z16, ytile_z16 FROM accident_hit) TO 'tile_z16.csv' DELIMITER ',' CSV;

\COPY (SELECT xtile_z18, ytile_z18 FROM accident_hit) TO 'tile_z18.csv' DELIMITER ',' CSV;

