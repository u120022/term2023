DROP TABLE IF EXISTS rdcl_tmp;
CREATE TEMPORARY TABLE IF NOT EXISTS rdcl_tmp AS (
    SELECT
        rid,
        ST_Centroid(geom) AS geom,
        ST_Azimuth(ST_StartPoint(geom), ST_EndPoint(geom)) AS rad
    FROM (
        SELECT
            "rID" AS rid,
            (ST_DumpSegments(ST_Segmentize("geometry", 10))).geom AS geom
        FROM
            rdcl
    )
);

DROP TABLE IF EXISTS rdcl_normal;
CREATE TEMPORARY TABLE IF NOT EXISTS rdcl_normal AS (
    SELECT
        rid,
        geom,
        ST_MakeLine(geom, ST_Translate(geom, 13*cos(pi()-rad), 13*sin(pi()-rad))) AS normal,
        TRUE AS face
    FROM
        rdcl_tmp
);

INSERT INTO
    rdcl_normal
    (rid, geom, normal, face)
SELECT
    rid,
    geom,
    ST_MakeLine(geom, ST_Translate(geom, 13*cos(-rad), 13*sin(-rad))) AS normal,
    FALSE AS face
FROM 
    rdcl_tmp;

DROP INDEX IF EXISTS fgd_idx;
DROP INDEX IF EXISTS rdcl_normal_idx_0;
DROP INDEX IF EXISTS rdcl_normal_idx_1;
CREATE INDEX IF NOT EXISTS fgd_idx ON fgd USING GIST(geometry);
CREATE INDEX IF NOT EXISTS rdcl_normal_idx_0 ON rdcl_normal USING GIST(geom);
CREATE INDEX IF NOT EXISTS rdcl_normal_idx_1 ON rdcl_normal USING GIST(normal);

DROP TABLE IF EXISTS rdcl_width;
CREATE TABLE IF NOT EXISTS rdcl_width AS (
    SELECT
        rid,
        geom,
        sum(width) AS width
    FROM (
        SELECT
            rid,
            geom,
            min(width) AS width
        FROM (
            SELECT
                t1.rid,
                t1.geom,
                ST_Distance(t1.geom, ST_Intersection(t1.normal, t2.geom)) AS width,
                t1.face
            FROM
                rdcl_normal AS t1
            JOIN (
                SELECT
                    geometry AS geom
                FROM
                    fgd
                WHERE
                    type = '真幅道路' OR type = '庭園路等' OR type = '徒歩道'
            ) AS t2 ON
                ST_Intersects(t1.normal, t2.geom)
        ) GROUP BY
            rid, geom, face
    ) GROUP BY
        rid, geom
    HAVING
        count(*) = 2 AND sum(width) < 13.0
);
