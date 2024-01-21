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
CREATE TABLE IF NOT EXISTS crosspoint AS (
    SELECT 
        ST_ClosestPoint(ST_Collect(t1.geom), t2.geom) AS geom
    FROM
        entire_crosspoint AS t1
    JOIN
        accident_target AS t2
    ON
        ST_DWithin(t1.geom::geography, t2.geom::geography, 30.0)
    GROUP BY
        t2.geom
);

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
