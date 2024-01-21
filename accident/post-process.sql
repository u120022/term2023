-- extract cross only
DROP TABLE IF EXISTS accident_target;
CREATE TABLE IF NOT EXISTS accident_target AS (
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
        100000
);

\COPY (SELECT xtile_z16, ytile_z16 FROM accident_target) TO 'tile_z16.csv' DELIMITER ',' CSV;

\COPY (SELECT xtile_z18, ytile_z18 FROM accident_target) TO 'tile_z18.csv' DELIMITER ',' CSV;
