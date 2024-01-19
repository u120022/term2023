DROP TABLE IF EXISTS tangent_tmp;
CREATE TEMPORARY TABLE IF NOT EXISTS tangent_tmp AS (
    SELECT
        geom AS center,
        i,
        ST_Translate(geom, i*cos(pi()/2-azimuths[1]), i*sin(pi()/2-azimuths[1])) AS geom1,
        ST_Translate(geom, i*cos(pi()/2-azimuths[2]), i*sin(pi()/2-azimuths[2])) AS geom2,
        ST_Translate(geom, i*cos(pi()/2-azimuths[3]), i*sin(pi()/2-azimuths[3])) AS geom3,
        ST_Translate(geom, i*cos(pi()/2-azimuths[4]), i*sin(pi()/2-azimuths[4])) AS geom4,
        count
    FROM (
        SELECT
            geom,
            array_agg(azimuth) AS azimuths,
            count(*)
        FROM (
            SELECT
                ST_StartPoint(geom) AS geom,
                ST_Azimuth(ST_StartPoint(geom), ST_EndPoint(geom)) AS azimuth
            FROM
                rdcl_crossline
            ORDER BY azimuth
        ) GROUP BY
            geom
    ), (SELECT GENERATE_SERIES(1, 20) AS i)
);

-- for 3 branch cross
--   #1
DROP TABLE IF EXISTS tangent;
CREATE TEMPORARY TABLE tangent AS (
    SELECT
        center,
        i,
        1 AS dir,
        ST_MakeLine(geom1, geom2) AS geom,
        3 AS count
    FROM
        tangent_tmp
    WHERE
        count = 3
);

--   #2
INSERT INTO
    tangent (center, i, dir, geom, count)
SELECT
    center,
    i,
    2 AS dir,
    ST_MakeLine(geom2, geom3) AS geom,
    3 AS count
FROM
    tangent_tmp
WHERE
    count = 3;

--   #3
INSERT INTO
    tangent (center, i, dir, geom, count)
SELECT
    center,
    i,
    3 AS dir,
    ST_MakeLine(geom3, geom1) AS geom,
    3 AS count
FROM
    tangent_tmp
WHERE
    count = 3;

-- for 4 branch cross
--   #1
INSERT INTO
    tangent (center, i, dir, geom, count)
SELECT
    center,
    i,
    1 AS dir,
    ST_MakeLine(geom1, geom2) AS geom,
    4 AS count
FROM
    tangent_tmp
WHERE
    count = 4;

--   #2
INSERT INTO
    tangent (center, i, dir, geom, count)
SELECT
    center,
    i,
    2 AS dir,
    ST_MakeLine(geom2, geom3) AS geom,
    4 AS count
FROM
    tangent_tmp
WHERE
    count = 4;

--   #3
INSERT INTO
    tangent (center, i, dir, geom, count)
SELECT
    center,
    i,
    3 AS dir,
    ST_MakeLine(geom3, geom4) AS geom,
    4 AS count
FROM
    tangent_tmp
WHERE
    count = 4;

--   #4
INSERT INTO
    tangent (center, i, dir, geom, count)
SELECT
    center,
    i,
    4 AS dir,
    ST_MakeLine(geom4, geom1) AS geom,
    4 AS count
FROM
    tangent_tmp
WHERE
    count = 4;

-- create index for spacial joining
DROP INDEX IF EXISTS tangent_idx;
CREATE INDEX IF NOT EXISTS tangent_idx ON tangent USING GIST(geom);

-- extract clearance #1
DROP TABLE IF EXISTS rdcl_clearance_1;
CREATE TABLE IF NOT EXISTS rdcl_clearance_1 AS (
    SELECT
        center,
        dir,
        min(i) AS dist
    FROM 
        tangent
    AS t1 JOIN (
        SELECT
            geometry AS geom
        FROM
            fgd
        WHERE
            type = '真幅道路' OR type = '庭園路等' OR type = '徒歩道'
    ) AS t2 ON 
        ST_Intersects(t1.geom, t2.geom)
    GROUP BY
        center,
        dir
);

-- extract clearance #2
DROP TABLE IF EXISTS rdcl_clearance_2;
CREATE TABLE IF NOT EXISTS rdcl_clearance_2 AS (
    SELECT
        center,
        dir,
        min(i) AS dist
    FROM 
        tangent
    AS t1 JOIN (
        SELECT
            geometry AS geom
        FROM
            fgd
        WHERE
            type = '堅ろう建物' OR type = '普通建物' OR type = '普通無壁舎'
    ) AS t2 ON 
        ST_Intersects(t1.geom, t2.geom)
    GROUP BY
        center,
        dir
);
