-- angle per lines
DROP TABLE IF EXISTS rdcl_rad;
CREATE TABLE IF NOT EXISTS rdcl_rad AS (
    SELECT
        geom,
        ST_StartPoint(geom) AS center,
        ST_Azimuth(ST_StartPoint(geom), ST_EndPoint(geom)) AS rad
    FROM
        rdcl_itl
);
