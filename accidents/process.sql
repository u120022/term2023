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
        10000
);

-- extract tile coordinates
--   # zoom lv.16
DROP TABLE IF EXISTS tile_z16;
    CREATE TABLE IF NOT EXISTS tile_z16 AS (
    SELECT
        ((x + 180) / 360 * pow(2, 16))::integer AS xtile,
        ((1 - asinh(tan(radians(y))) / pi()) / 2 * pow(2, 16))::integer AS ytile
    FROM
        accident_cross
    GROUP BY
        xtile, ytile
);

--   # zoom lv.18
DROP TABLE IF EXISTS tile_z18;
    CREATE TABLE IF NOT EXISTS tile_z18 AS (
    SELECT
        ((x + 180) / 360 * pow(2, 18))::integer AS xtile,
        ((1 - asinh(tan(radians(y))) / pi()) / 2 * pow(2, 18))::integer AS ytile
    FROM
        accident_cross
    GROUP BY
        xtile, ytile
);
