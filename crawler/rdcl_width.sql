-- subdivide into line segments and compute radian
DROP TABLE IF EXISTS rdcl_tmp;
CREATE TEMPORARY TABLE IF NOT EXISTS rdcl_tmp AS (
    SELECT
        segment,
        ST_Centroid(geom) AS geom,
        rad
    FROM (
        SELECT
            geom AS segment,
            (ST_DumpSegments(ST_Segmentize(geom, 4.0))).geom,
            ST_Azimuth(ST_StartPoint(geom), ST_EndPoint(geom)) AS rad
        FROM
            rdcl_crossline
    )
);

-- line normal (front face)
DROP TABLE IF EXISTS rdcl_normal;
CREATE TEMPORARY TABLE IF NOT EXISTS rdcl_normal AS (
    SELECT
        segment,
        geom,
        ST_MakeLine(geom, ST_Translate(geom, 20.0*cos(pi()-rad), 20.0*sin(pi()-rad))) AS normal,
        TRUE AS face
    FROM
        rdcl_tmp
);

-- line normal (back face)
INSERT INTO
    rdcl_normal
    (segment, geom, normal, face)
SELECT
    segment,
    geom,
    ST_MakeLine(geom, ST_Translate(geom, 20.0*cos(-rad), 20.0*sin(-rad))) AS normal,
    FALSE AS face
FROM 
    rdcl_tmp;

-- index for spacial joinning
DROP INDEX IF EXISTS rdcl_normal_idx;
CREATE INDEX IF NOT EXISTS rdcl_normal_idx ON rdcl_normal USING GIST(normal);

-- width with side walk
DROP TABLE IF EXISTS rdcl_width_sw;
CREATE TABLE IF NOT EXISTS rdcl_width_sw AS (
    SELECT
        segment AS geom,
        percentile_cont(0.5) WITHIN GROUP (ORDER BY width) AS width
    FROM (
        SELECT
            segment,
            geom,
            sum(width) AS width
        FROM (
            SELECT
                segment,
                geom,
                face,
                min(width) AS width
            FROM (
                SELECT
                    t1.segment,
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
                segment,
                geom,
                face
        ) GROUP BY
            segment,
            geom
        HAVING
            count(*) = 2 AND sum(width) < 20.0
    ) GROUP BY
        segment
);

-- width without side walk
DROP TABLE IF EXISTS rdcl_width_nosw;
CREATE TABLE IF NOT EXISTS rdcl_width_nosw AS (
    SELECT
        segment AS geom,
        percentile_cont(0.5) WITHIN GROUP (ORDER BY width) AS width
    FROM (
        SELECT
            segment,
            geom,
            sum(width) AS width
        FROM (
            SELECT
                segment,
                geom,
                face,
                min(width) AS width
            FROM (
                SELECT
                    t1.segment,
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
                        type = '真幅道路' OR type = '庭園路等' OR type = '徒歩道' OR type = '歩道'
                ) AS t2 ON
                    ST_Intersects(t1.normal, t2.geom)
            ) GROUP BY
                segment,
                geom,
                face
        ) GROUP BY
            segment,
            geom
        HAVING
            count(*) = 2 AND sum(width) < 20.0
    ) GROUP BY
        segment
);
