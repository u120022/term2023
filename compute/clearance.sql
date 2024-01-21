DROP TABLE IF EXISTS cp_area_corner;
CREATE TEMPORARY TABLE IF NOT EXISTS cp_area_corner AS (
    SELECT
        geom,
        array_agg(end_geom) AS end_geoms,
        count(*)
    FROM (
        SELECT
            ST_StartPoint(geom) AS geom,
            ST_EndPoint(geom) AS end_geom
        FROM
            crossline
        ORDER BY
            ST_Azimuth(ST_StartPoint(geom), ST_EndPoint(geom))
    ) GROUP BY
        geom
);

DROP TABLE IF EXISTS cp_area;
CREATE TABLE IF NOT EXISTS cp_area (
    geom Geometry(Point, 6668),
    area_geom Geometry(Polygon, 6668),
    dir_seq Integer
);

-- cp_area #1
INSERT INTO
    cp_area
    (geom, area_geom, dir_seq)
SELECT
    geom,
    ST_MakePolygon(ST_MakeLine(array[geom, end_geoms[1], end_geoms[2], geom])),
    1
FROM
    cp_area_corner;

-- cp_area #2
INSERT INTO
    cp_area
    (geom, area_geom, dir_seq)
SELECT
    geom,
    ST_MakePolygon(ST_MakeLine(array[geom, end_geoms[2], end_geoms[3], geom])),
    2
FROM
    cp_area_corner;

-- cp_area #3
INSERT INTO
    cp_area
    (geom, area_geom, dir_seq)
SELECT
    geom,
    CASE 
        WHEN count = 3 THEN ST_MakePolygon(ST_MakeLine(array[geom, end_geoms[3], end_geoms[1], geom]))
        WHEN count = 4 THEN ST_MakePolygon(ST_MakeLine(array[geom, end_geoms[3], end_geoms[4], geom]))
        ELSE NULL
    END,
    3
FROM
    cp_area_corner;

-- cp_area #4
INSERT INTO
    cp_area
    (geom, area_geom, dir_seq)
SELECT
    geom,
    CASE 
        WHEN count = 3 THEN NULL
        WHEN count = 4 THEN ST_MakePolygon(ST_MakeLine(array[geom, end_geoms[4], end_geoms[1], geom]))
        ELSE NULL
    END,
    4
FROM
    cp_area_corner;

-- extract clearance #1
DROP TABLE IF EXISTS cp_clearance_ob;
CREATE TABLE IF NOT EXISTS cp_clearance_ob AS (
    SELECT
        t1.geom,
        t1.dir_seq,
        ST_Distance(t1.geom::geography, ST_Collect(t2.geom)::geography) AS dist
    FROM 
        cp_area
    AS t1 JOIN (
        SELECT
            geom
        FROM
            fgd
        WHERE
            type = '堅ろう建物' OR type = '普通建物' OR type = '普通無壁舎'
    ) AS t2 ON 
        ST_Intersects(t1.area_geom, t2.geom)
    GROUP BY
        t1.geom,
        t1.dir_seq
);

-- extract clearance #2
DROP TABLE IF EXISTS cp_clearance_noob;
CREATE TABLE IF NOT EXISTS cp_clearance_noob AS (
    SELECT
        t1.geom,
        t1.dir_seq,
        ST_Distance(t1.geom::geography, ST_Collect(t2.geom)::geography) AS dist
    FROM 
        cp_area
    AS t1 JOIN (
        SELECT
            geom
        FROM
            fgd
        WHERE
            type = '真幅道路' OR type = '庭園路等' OR type = '徒歩道'
    ) AS t2 ON 
        ST_Intersects(t1.area_geom, t2.geom)
    GROUP BY
        t1.geom,
        t1.dir_seq
);
