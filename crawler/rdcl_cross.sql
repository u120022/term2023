DROP TABLE IF EXISTS rdcl_crosspoint;
CREATE TABLE rdcl_crosspoint AS (
    SELECT
        geom
    FROM (
        SELECT
            (ST_DumpPoints(geom)).geom
        FROM (
            SELECT
                (ST_DumpSegments(geometry)).geom
            FROM
                rdcl
        )
    ) GROUP BY
        geom
    HAVING 
        count(*) = 3 OR count(*) = 4
);

-- create index for spacial joining #1
DROP INDEX IF EXISTS rdcl_crosspoint_idx;
CREATE INDEX IF NOT EXISTS rdcl_crosspoint_idx ON rdcl_crosspoint USING GIST(geom);

DROP TABLE IF EXISTS rdcl_crossline;
CREATE TABLE rdcl_crossline AS (
    SELECT
        ST_LongestLine(t2.geom, t1.geom) AS geom
    FROM (
        SELECT 
            (ST_DumpSegments(geometry)).geom
        FROM
            rdcl
    ) AS t1 JOIN
        rdcl_crosspoint
    AS t2 ON
        ST_Intersects(t1.geom, t2.geom)
);

-- create index for spacial joining #2
DROP INDEX IF EXISTS rdcl_crossline_idx;
CREATE INDEX IF NOT EXISTS rdcl_crossline_idx ON rdcl_crossline USING GIST(geom);

-- create index for spacial joining #3
DROP INDEX IF EXISTS fgd_idx;
CREATE INDEX IF NOT EXISTS fgd_idx ON fgd USING GIST(geometry);
