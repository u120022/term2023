-- create target intersection points
DROP TABLE IF EXISTS rdcl_itp;
CREATE TABLE rdcl_itp AS (
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

-- culling by target intersection points
DROP TABLE IF EXISTS rdcl_itl;
CREATE TABLE rdcl_itl AS (
    SELECT
        ST_LongestLine(t2.geom, t1.geom) AS geom
    FROM (
        SELECT 
            (ST_DumpSegments(geometry)).geom
        FROM
            rdcl
    ) AS t1 JOIN
        rdcl_itp
    AS t2 ON
        ST_Intersects(t1.geom, t2.geom)
);

-- create index #1
DROP INDEX IF EXISTS rdcl_itp_idx;
DROP INDEX IF EXISTS rdcl_itl_idx;
CREATE INDEX IF NOT EXISTS rdcl_itp_idx ON rdcl_itp USING GIST(geom);
CREATE INDEX IF NOT EXISTS rdcl_itl_idx ON rdcl_itl USING GIST(geom);

-- create index #2
DROP INDEX IF EXISTS fgd_idx;
CREATE INDEX IF NOT EXISTS fgd_idx ON fgd USING GIST(geometry);
