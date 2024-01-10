-- extract cross only
DROP TABLE IF EXISTS accident_cross;
CREATE TABLE IF NOT EXISTS accident_cross AS (
    SELECT
        *
    FROM
        accident
    WHERE
        11 <= "車道幅員" AND "車道幅員" <= 15
);
