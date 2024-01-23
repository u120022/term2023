DROP INDEX IF EXISTS idx_accident;
DROP INDEX IF EXISTS idx_accident_target;

CREATE INDEX IF NOT EXISTS idx_accident ON accident USING GIST((geom::geography));
CREATE INDEX IF NOT EXISTS idx_accident_target ON accident_target USING GIST((geom::geography));

DROP TABLE IF EXISTS rdcl_segment;
CREATE TEMPORARY TABLE IF NOT EXISTS rdcl_segment AS (
    SELECT
        (ST_DumpSegments(geom)).geom
    FROM
        rdcl
);

DROP INDEX IF EXISTS idx_rdcl_segment;
CREATE INDEX IF NOT EXISTS idx_rdcl_segment ON rdcl_segment USING GIST(geom);

-- extract entire crosspoint that has 3 or 4 branches
DROP TABLE IF EXISTS entire_crosspoint;
CREATE TEMPORARY TABLE IF NOT EXISTS entire_crosspoint AS (
    SELECT
        geom
    FROM (
        SELECT
            (ST_DumpPoints(geom)).geom
        FROM 
            rdcl_segment
    ) GROUP BY
        geom
    HAVING 
        count(*) = 3 OR count(*) = 4
);

DROP INDEX IF EXISTS idx_entire_crosspoint;
CREATE INDEX IF NOT EXISTS idx_entire_crosspoint ON entire_crosspoint USING GIST((geom::geography));

-- crosspoint in accident
DROP TABLE IF EXISTS crosspoint;
CREATE TABLE IF NOT EXISTS crosspoint (
    geom Geometry(Point, 6668),
    accident boolean,
    accident_count Integer
);

-- true accident
INSERT INTO
    crosspoint
    (geom, accident, accident_count)
SELECT
    geom,
    true,
    count(*)
FROM (
    SELECT 
        ST_ClosestPoint(ST_Collect(t1.geom), t2.geom) AS geom
    FROM
        entire_crosspoint AS t1
    JOIN (
        SELECT geom FROM accident_target
    ) AS t2 ON
        ST_DWithin(t1.geom::geography, t2.geom::geography, 30.0)
    GROUP BY
        t2.geom
) GROUP BY
    geom;

-- false accident
INSERT INTO
    crosspoint
    (geom, accident, accident_count)
SELECT
    geom,
    false,
    count(*)
FROM (
    SELECT
        t2.geom AS geom
    FROM (
        SELECT
            t1.geom AS geom,
            ST_Collect(t2.geom) AS accident_geom
        FROM
            accident_target AS t1
        JOIN
            accident AS t2
        ON
            ST_DWithin(t1.geom::geography, t2.geom::geography, 100.0)
        GROUP BY
            t1.geom
    ) AS t1 JOIN
        entire_crosspoint AS t2
    ON
        ST_DWithin(t1.geom::geography, t2.geom::geography, 100.0)
    WHERE
        30.0 <= ST_Distance(t1.accident_geom::geography, t2.geom::geography)
) GROUP BY
    geom;

DROP INDEX IF EXISTS idx_crosspoint;
CREATE INDEX IF NOT EXISTS idx_crosspoint ON crosspoint USING GIST(geom);

-- crossline on crosspoint
DROP TABLE IF EXISTS crossline;
CREATE TABLE crossline AS (
    SELECT
        ST_MakeLine(
            geom,
            ST_Project(
                geom::geography,
                30.0,
                ST_Azimuth(ST_StartPoint(line_geom), ST_EndPoint(line_geom))
            )::geometry
        ) AS geom
    FROM (
        SELECT
            t1.geom AS geom,
            ST_LongestLine(t1.geom, t2.geom) AS line_geom
        FROM 
            crosspoint AS t1
        JOIN 
            rdcl_segment AS t2
        ON
            ST_Intersects(t1.geom, t2.geom)
    )
);
