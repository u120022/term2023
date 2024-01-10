-- dir order
DROP TABLE IF EXISTS tmp;
CREATE TEMPORARY TABLE IF NOT EXISTS tmp AS (
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
        ORDER BY
            azimuth
    ) GROUP BY
        geom
);

-- for 3 branch cross
--   #1
DROP TABLE IF EXISTS scafold;
CREATE TEMPORARY TABLE IF NOT EXISTS scafold AS (
    SELECT
        geom,
        1 AS dir,
        azimuths[2] - azimuths[1] AS angle,
        count
    FROM
        tmp
    WHERE
        count = 3
);

--   #2
INSERT INTO
    scafold
    (geom, dir, angle, count)
SELECT
    geom,
    2 AS dir,
    azimuths[3] - azimuths[2] AS angle,
    count
FROM
    tmp
WHERE
    count = 3;

--   #3
INSERT INTO
    scafold
    (geom, dir, angle, count)
SELECT
    geom,
    3 AS dir,
    2*pi() + azimuths[1] - azimuths[3] AS angle,
    count
FROM
    tmp
WHERE
    count = 3;

-- for 4 branch cross
--   #1
INSERT INTO
    scafold
    (geom, dir, angle, count)
SELECT
    geom,
    1 AS dir,
    azimuths[2] - azimuths[1] AS angle,
    count
FROM
    tmp
WHERE
    count = 4;

--   #2
INSERT INTO
    scafold
    (geom, dir, angle, count)
SELECT
    geom,
    2 AS dir,
    azimuths[3] - azimuths[2] AS angle,
    count
FROM
    tmp
WHERE
    count = 4;

--   #3
INSERT INTO
    scafold
    (geom, dir, angle, count)
SELECT
    geom,
    3 AS dir,
    azimuths[4] - azimuths[3] AS angle,
    count
FROM
    tmp
WHERE
    count = 4;

--   #4
INSERT INTO
    scafold
    (geom, dir, angle, count)
SELECT
    geom,
    4 AS dir,
    2*pi() + azimuths[1] - azimuths[4] AS angle,
    count
FROM
    tmp
WHERE
    count = 4;

-- merge `clearance` and `width`
DROP TABLE IF EXISTS flatten_frame;
CREATE TEMPORARY TABLE IF NOT EXISTS flatten_frame AS (
    SELECT
        t1.*,
        t2.dist AS dist_1,
        t3.dist AS dist_2,
        t4.widths_1[t1.dir] AS width_1,
        t4.widths_2[t1.dir] AS width_2
    FROM
        scafold AS t1
    LEFT JOIN
        rdcl_clearance_1 AS t2
    ON 
        t1.geom = t2.center AND t1.dir = t2.dir
    LEFT JOIN
        rdcl_clearance_2 AS t3
    ON
        t1.geom = t3.center AND t1.dir = t3.dir
    LEFT JOIN (
        SELECT
            center,
            array_agg(width_1) AS widths_1,
            array_agg(width_2) AS widths_2
        FROM (
            SELECT
                ST_StartPoint(t1.geom) AS center,
                ST_Azimuth(ST_StartPoint(t1.geom), ST_EndPoint(t1.geom)) AS azimuth,
                t1.width AS width_1,
                t2.width AS width_2
            FROM
                rdcl_width_sw AS t1
            LEFT JOIN
                rdcl_width_nosw AS t2
            ON
                t1.geom = t2.geom
            ORDER BY
                azimuth
        ) GROUP BY
            center
    ) AS t4 ON
        t1.geom = t4.center
);

-- compress
DROP TABLE IF EXISTS frame;
CREATE TABLE IF NOT EXISTS frame AS (
    SELECT
        geom,
        a[1] AS a1,
        a[2] AS a2,
        a[3] AS a3,
        a[4] AS a4,

        da[1] AS da1,
        da[2] AS da2,
        da[3] AS da3,
        da[4] AS da4,

        db[1] AS db1,
        db[2] AS db2,
        db[3] AS db3,
        db[4] AS db4,

        wa[1] AS wa1,
        wa[2] AS wa2,
        wa[3] AS wa3,
        wa[4] AS wa4,

        wb[1] AS wb1,
        wb[2] AS wb2,
        wb[3] AS wb3,
        wb[4] AS wb4
    FROM (
        SELECT
            geom,
            array_agg(angle) AS a,
            array_agg(dist_1) AS da,
            array_agg(dist_2) AS db,
            array_agg(width_1) AS wa,
            array_agg(width_2) AS wb
        FROM
            flatten_frame
        GROUP BY
            geom
    )
);
