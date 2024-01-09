-- subdivision line segments
DROP TABLE IF EXISTS rdcl_tmp;
CREATE TEMPORARY TABLE IF NOT EXISTS rdcl_tmp AS (
    SELECT
        ST_Centroid(geom) AS geom,
        ST_Azimuth(ST_StartPoint(geom), ST_EndPoint(geom)) AS rad
    FROM (
        SELECT
            (ST_DumpSegments(ST_Segmentize(geom, 4.0))).geom
        FROM
            rdcl_itl
    )
);

-- line normal front face
DROP TABLE IF EXISTS rdcl_normal;
CREATE TEMPORARY TABLE IF NOT EXISTS rdcl_normal AS (
    SELECT
        geom,
        ST_MakeLine(geom, ST_Translate(geom, 20.0*cos(pi()-rad), 20.0*sin(pi()-rad))) AS normal,
        TRUE AS face
    FROM
        rdcl_tmp
);

-- line normal back face
INSERT INTO
    rdcl_normal
    (geom, normal, face)
SELECT
    geom,
    ST_MakeLine(geom, ST_Translate(geom, 20.0*cos(-rad), 20.0*sin(-rad))) AS normal,
    FALSE AS face
FROM 
    rdcl_tmp;

-- index for spacial joinning
DROP INDEX IF EXISTS rdcl_normal_idx_0;
DROP INDEX IF EXISTS rdcl_normal_idx_1;
CREATE INDEX IF NOT EXISTS rdcl_normal_idx_0 ON rdcl_normal USING GIST(geom);
CREATE INDEX IF NOT EXISTS rdcl_normal_idx_1 ON rdcl_normal USING GIST(normal);

-- with side walk
DROP TABLE IF EXISTS rdcl_width_sw;
CREATE TEMPORARY TABLE IF NOT EXISTS rdcl_width_sw AS (
    SELECT
        geom,
        sum(width) AS width
    FROM (
        SELECT
            geom,
            min(width) AS width
        FROM (
            SELECT
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
            geom, face
    ) GROUP BY
        geom
    HAVING
        count(*) = 2 AND sum(width) < 20.0
);

-- without side walk
DROP TABLE IF EXISTS rdcl_width_nosw;
CREATE TEMPORARY TABLE IF NOT EXISTS rdcl_width_nosw AS (
    SELECT
        geom,
        sum(width) AS width
    FROM (
        SELECT
            geom,
            min(width) AS width
        FROM (
            SELECT
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
            geom, face
    ) GROUP BY
        geom
    HAVING
        count(*) = 2 AND sum(width) < 20.0
);

-- width per lines
DROP TABLE IF EXISTS rdcl_width;
CREATE TABLE IF NOT EXISTS rdcl_width AS (
    SELECT
        t1.geom,
        percentile_cont(0.5) WITHIN GROUP (ORDER BY t2.width) AS width,
        percentile_cont(0.5) WITHIN GROUP (ORDER BY t2.sw_width) AS sw_width
    FROM
        rdcl_itl
    AS t1 JOIN (
        SELECT
            t1.geom,
            t1.width AS width,
            t1.width - t2.width AS sw_width
        FROM
            rdcl_width_sw AS t1
        JOIN
            rdcl_width_nosw AS t2
        ON
            t1.geom = t2.geom
    ) AS t2 ON
        ST_DWithin(t1.geom, t2.geom, 0.1)
    GROUP BY
        t1.geom
);

-- building
-- DROP TABLE IF EXISTS rdcl_width_obs_tmp;
-- CREATE TEMPORARY TABLE IF NOT EXISTS rdcl_width_obs_tmp AS (
--     SELECT
--         geom,
--         face,
--         min(width) AS width
--     FROM (
--         SELECT
--             t1.geom,
--             ST_Distance(t1.geom, ST_Intersection(t1.normal, t2.geom)) AS width,
--             t1.face
--         FROM
--             rdcl_normal AS t1
--         JOIN (
--             SELECT
--                 geometry AS geom
--             FROM
--                 fgd
--             WHERE
--                 type = '普通建物' OR type = '堅ろう建物' OR type = '普通無壁舎'
--         ) AS t2 ON
--             ST_Intersects(t1.normal, t2.geom)
--     ) GROUP BY
--         geom, face
-- );
-- 
-- DROP TABLE IF EXISTS rdcl_width_obs;
-- CREATE TABLE IF NOT EXISTS rdcl_width_obs AS (
--     SELECT
--         t2.geom,
--         t2.face,
--         t1.width
--     FROM
--         rdcl_width_obs_tmp
--     AS t1 JOIN (
--         SELECT
--             t1.geom,
--             ST_StartPoint(t1.geom) AS center,
--             ST_Union(t2.geom) AS measure_geom,
--             face
--         FROM
--             rdcl_itl
--         AS t1 JOIN
--             rdcl_width_obs_tmp
--         AS t2 ON
--             ST_DWithin(t1.geom, t2.geom, 0.1)
--         GROUP BY
--             t1.geom,
--             face
--     ) AS t2 ON
--         t1.geom = ST_ClosestPoint(t2.geom, t2.measure_geom)
-- );
