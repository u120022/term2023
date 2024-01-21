-- subdivide into line segments and compute radian
DROP TABLE IF EXISTS cl_segment;
CREATE TEMPORARY TABLE IF NOT EXISTS cl_segment AS (
    SELECT
        geom,
        ST_Centroid(segment_geom) AS rayorigin_geom,
        azimuth
    FROM (
        SELECT
            geom,
            (ST_DumpSegments(ST_Segmentize(geom::geography, 4.0)::geometry)).geom AS segment_geom,
            ST_Azimuth(ST_StartPoint(geom), ST_EndPoint(geom)) AS azimuth
        FROM
            crossline
    )
);

DROP TABLE IF EXISTS cl_normal;
CREATE TABLE IF NOT EXISTS cl_normal (
    geom Geometry(LineString, 6668),
    rayorigin_geom Geometry(Point, 6668),
    normal_geom Geometry(LineString, 6668),
    face Boolean
);

-- line normal (front face)
INSERT INTO
    cl_normal
    (geom, rayorigin_geom, normal_geom, face)
SELECT
    geom,
    rayorigin_geom,
    ST_MakeLine(
        rayorigin_geom,
        ST_Project(
            rayorigin_geom::geography,
            15.0,
            azimuth + 0.5 * pi()
        )::geometry
    ),
    True
FROM
    cl_segment;

-- line normal (back face)
INSERT INTO
    cl_normal
    (geom, rayorigin_geom, normal_geom, face)
SELECT
    geom,
    rayorigin_geom,
    ST_MakeLine(
        rayorigin_geom,
        ST_Project(
            rayorigin_geom::geography,
            15.0,
            azimuth - 0.5 * pi()
        )::geometry
    ),
    False
FROM 
    cl_segment;

-- width with side walk
DROP TABLE IF EXISTS cl_width_sw;
CREATE TABLE IF NOT EXISTS cl_width_sw AS (
    SELECT
        geom,
        percentile_cont(0.5) WITHIN GROUP (ORDER BY width) AS width
    FROM (
        SELECT
            geom,
            rayorigin_geom,
            sum(width) AS width
        FROM (
            SELECT
                geom,
                rayorigin_geom,
                face,
                min(width) AS width
            FROM (
                SELECT
                    t1.geom,
                    t1.rayorigin_geom,
                    ST_Distance(
                        t1.rayorigin_geom::geography,
                        ST_Intersection(t1.normal_geom, t2.geom)::geography
                    ) AS width,
                    t1.face
                FROM
                    cl_normal AS t1
                JOIN (
                    SELECT
                        geom
                    FROM
                        fgd
                    WHERE
                        type = '真幅道路' OR type = '庭園路等' OR type = '徒歩道'
                ) AS t2 ON
                    ST_Intersects(t1.normal_geom, t2.geom)
            ) GROUP BY
                geom,
                rayorigin_geom,
                face
        ) GROUP BY
            geom,
            rayorigin_geom
        HAVING
            count(*) = 2
    ) GROUP BY
        geom
);

-- width without side walk
DROP TABLE IF EXISTS cl_width_nosw;
CREATE TABLE IF NOT EXISTS cl_width_nosw AS (
    SELECT
        geom,
        percentile_cont(0.5) WITHIN GROUP (ORDER BY width) AS width
    FROM (
        SELECT
            geom,
            rayorigin_geom,
            sum(width) AS width
        FROM (
            SELECT
                geom,
                rayorigin_geom,
                face,
                min(width) AS width
            FROM (
                SELECT
                    t1.geom,
                    t1.rayorigin_geom,
                    ST_Distance(
                        t1.rayorigin_geom,
                        ST_Intersection(t1.normal_geom, t2.geom)
                    ) AS width,
                    t1.face
                FROM
                    cl_normal AS t1
                JOIN (
                    SELECT
                        geom
                    FROM
                        fgd
                    WHERE
                        type = '真幅道路' OR type = '庭園路等' OR type = '徒歩道' OR type = '歩道'
                ) AS t2 ON
                    ST_Intersects(t1.normal_geom, t2.geom)
            ) GROUP BY
                geom,
                rayorigin_geom,
                face
        ) GROUP BY
            geom,
            rayorigin_geom
        HAVING
            count(*) = 2
    ) GROUP BY
        geom
);
