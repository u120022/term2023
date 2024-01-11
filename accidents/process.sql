-- extract cross only
DROP TABLE IF EXISTS accident_cross;
CREATE TABLE IF NOT EXISTS accident_cross AS (
    SELECT
        *
    FROM
        accident
    WHERE
        11 <= "車道幅員" AND "車道幅員" <= 15
    ORDER BY
        random()
    LIMIT
        1000
);

-- extract tile coordinates
--   # zoom lv.16
DROP TABLE IF EXISTS tile_z16;
    CREATE TABLE IF NOT EXISTS tile_z16 AS (
    SELECT
        xtile_z16 AS xtile,
        ytile_z16 AS ytile
    FROM
        accident_cross
    GROUP BY
        xtile_z16,
        ytile_z16
);

--   # zoom lv.18
DROP TABLE IF EXISTS tile_z18;
    CREATE TABLE IF NOT EXISTS tile_z18 AS (
    SELECT
        xtile_z18 AS xtile,
        ytile_z18 AS ytile
    FROM
        accident_cross
    GROUP BY
        xtile_z18,
        ytile_z18
);
