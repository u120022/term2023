DROP TABLE IF EXISTS entire_crosspoint;
CREATE TEMPORARY TABLE IF NOT EXISTS entire_crosspoint AS (
    SELECT
        geom
    FROM (
        SELECT
            (ST_DumpPoints(geom)).geom
        FROM (
            SELECT
                (ST_DumpSegments(geom)).geom
            FROM
                rdcl
        )
    ) GROUP BY
        geom
    HAVING 
        count(*) = 3 OR count(*) = 4
);

DROP TABLE IF EXISTS crosspoint;
CREATE TABLE IF NOT EXISTS crosspoint (
    geom Geometry(Point, 6668),
    tag Text
);

-- true accident
INSERT INTO
    crosspoint
    (geom, tag)
SELECT 
    ST_ClosestPoint(ST_Collect(t1.geom), t2.geom),
    'true accident'
FROM
    entire_crosspoint AS t1
JOIN
    accident_target AS t2
ON
    ST_DWithin(t1.geom::geography, t2.geom::geography, 30.0)
GROUP BY
    t2.geom;

-- false accident
INSERT INTO
    crosspoint
    (geom, tag)
SELECT
    t2.geom,
    'false accident'
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
    30.0 <= ST_Distance(t1.accident_geom::geography, t2.geom::geography);

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
        ) AS geom,
        tag
    FROM (
        SELECT
            t1.geom AS geom,
            ST_LongestLine(t1.geom, t2.geom) AS line_geom,
            t1.tag AS tag
        FROM 
            crosspoint
        AS t1 JOIN (
            SELECT 
                (ST_DumpSegments(geom)).geom
            FROM
                rdcl
        ) AS t2 ON
            ST_Intersects(t1.geom, t2.geom)
    )
);
