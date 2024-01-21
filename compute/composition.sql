DROP TABLE IF EXISTS cl_angle;
CREATE TEMPORARY TABLE IF NOT EXISTS cl_angle AS (
    SELECT
        geom,
        array_agg(azimuth) AS azimuths,
        count(*)
    FROM (
        SELECT
            ST_StartPoint(geom) AS geom,
            ST_Azimuth(ST_StartPoint(geom), ST_EndPoint(geom)) AS azimuth
        FROM
            crossline
        ORDER BY
            azimuth
    ) GROUP BY
        geom
);

-- create base for data frame
DROP TABLE IF EXISTS scaffold;
CREATE TEMPORARY TABLE IF NOT EXISTS scaffold (
    geom Geometry(Point, 6668),
    angle Real,
    dir_seq Integer,
    count Integer
);

-- scaffold #1
INSERT INTO
    scaffold
    (geom, angle, dir_seq, count)
SELECT
    geom,
    azimuths[2] - azimuths[1],
    1,
    count
FROM
    cl_angle;

-- scaffold #2
INSERT INTO
    scaffold
    (geom, angle, dir_seq, count)
SELECT
    geom,
    azimuths[3] - azimuths[2],
    2,
    count
FROM
    cl_angle;

-- scaffold #3
INSERT INTO
    scaffold
    (geom, angle, dir_seq, count)
SELECT
    geom,
    CASE
        WHEN count = 3 THEN azimuths[1] - azimuths[3] + 2.0 * pi()
        WHEN count = 4 THEN azimuths[4] - azimuths[3]
        ELSE NULL
    END,
    3,
    count
FROM
    cl_angle;

-- scaffold #4
INSERT INTO
    scaffold
    (geom, angle, dir_seq, count)
SELECT
    geom,
    CASE
        WHEN count = 3 THEN 9999.0
        WHEN count = 4 THEN azimuths[1] - azimuths[4] + 2.0 * pi()
        ELSE NULL
    END,
    4,
    count
FROM
    cl_angle;

-- merge `clearance` and `width`
DROP TABLE IF EXISTS flatten_frame;
CREATE TEMPORARY TABLE IF NOT EXISTS flatten_frame AS (
    SELECT
        t1.*,
        t2.dist AS dist_ob,
        t3.dist AS dist_noob,
        COALESCE(t4.widths_sw[t1.dir_seq], 9999.0) AS width_sw,
        COALESCE(t4.widths_nosw[t1.dir_seq], 9999.0) AS width_nosw,
        t5.category
    FROM
        scaffold AS t1
    LEFT JOIN
        cp_clearance_ob AS t2
    ON 
        t1.geom = t2.geom AND t1.dir_seq = t2.dir_seq
    LEFT JOIN
        cp_clearance_noob AS t3
    ON
        t1.geom = t3.geom AND t1.dir_seq = t3.dir_seq
    LEFT JOIN (
        SELECT
            geom,
            array_agg(width_sw) AS widths_sw,
            array_agg(width_nosw) AS widths_nosw
        FROM (
            SELECT
                ST_StartPoint(t1.geom) AS geom,
                ST_Azimuth(ST_StartPoint(t1.geom), ST_EndPoint(t1.geom)) AS azimuth,
                t1.width AS width_sw,
                t2.width AS width_nosw
            FROM
                cl_width_sw AS t1
            LEFT JOIN
                cl_width_nosw AS t2
            ON
                t1.geom = t2.geom
            ORDER BY
                azimuth
        ) GROUP BY
            geom
    ) AS t4 ON
        t1.geom = t4.geom
    JOIN
        crosspoint AS t5
    ON
        t1.geom = t5.geom
);

-- dense data frame
DROP TABLE IF EXISTS frame;
CREATE TABLE IF NOT EXISTS frame AS (
    SELECT
        t1.geom AS geom,
        t1.count AS count,

        t2."CITY_CODE" AS city_code,
        t2."POP2020" AS pop,
        t2."POP2020A" AS pop_1,
        t2."POP2020B" AS pop_2,
        t2."POP2020C" AS pop_3,

        t1.angles[1] AS angle_1,
        t1.angles[2] AS angle_2,
        t1.angles[3] AS angle_3,
        t1.angles[4] AS angle_4,

        t1.dists_ob[1] AS dist_ob_1,
        t1.dists_ob[2] AS dist_ob_2,
        t1.dists_ob[3] AS dist_ob_3,
        t1.dists_ob[4] AS dist_ob_4,

        t1.dists_noob[1] AS dist_noob_1,
        t1.dists_noob[2] AS dist_noob_2,
        t1.dists_noob[3] AS dist_noob_3,
        t1.dists_noob[4] AS dist_noob_4,

        t1.widths_sw[1] AS width_sw_1,
        t1.widths_sw[2] AS width_sw_2,
        t1.widths_sw[3] AS width_sw_3,
        t1.widths_sw[4] AS width_sw_4,

        t1.widths_nosw[1] AS width_nosw_1,
        t1.widths_nosw[2] AS width_nosw_2,
        t1.widths_nosw[3] AS width_nosw_3,
        t1.widths_nosw[4] AS width_nosw_4,

        t1.category
    FROM (
        SELECT
            geom,
            count,
            array_agg(angle) AS angles,
            array_agg(dist_ob) AS dists_ob,
            array_agg(dist_noob) AS dists_noob,
            array_agg(width_sw) AS widths_sw,
            array_agg(width_nosw) AS widths_nosw,
            category
        FROM (
            SELECT
                *
            FROM
                flatten_frame
            ORDER BY
                geom,
                dir_seq
        ) GROUP BY
            geom,
            count,
            category
    ) AS t1 JOIN
        population
    AS t2 ON
        ST_Intersects(t1.geom, t2.geom)
);

\COPY (SELECT * FROM frame) TO 'frame.csv' HEADER DELIMITER ',' CSV;
