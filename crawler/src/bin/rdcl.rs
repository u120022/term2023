use futures::StreamExt;
use std::str::FromStr;

#[tokio::main]
async fn main() {
    let mut tiles: Vec<(i64, i64)> = vec![];

    let file = std::fs::File::open("../accident/tile_z16.csv").expect("not fount tile.csv file");

    let mut rdr = csv::ReaderBuilder::new()
        .has_headers(false)
        .from_reader(file);

    for record in rdr.deserialize().flatten() {
        tiles.push(record);
    }

    let mut dilate_tiles = vec![];
    for (xtile, ytile) in tiles {
        for x in -1..=1 {
            for y in -1..=1 {
                dilate_tiles.push((xtile + x, ytile + y))
            }
        }
    }

    dilate_tiles.sort();
    dilate_tiles.dedup();

    let pool = sqlx::postgres::PgPoolOptions::new()
        .connect("postgres://postgres:0@localhost/postgres")
        .await
        .expect("failed to connect postgresql");

    sqlx::query("DROP TABLE IF EXISTS rdcl")
        .execute(&pool)
        .await
        .expect("failed to drop table");

    sqlx::query(
        "CREATE TABLE IF NOT EXISTS rdcl (id Serial PRIMARY KEY, geom Geometry(LineString, 6668))",
    )
    .execute(&pool)
    .await
    .expect("faile to create table");

    let client = reqwest::Client::new();
    let n_progress = std::sync::Arc::new(std::sync::atomic::AtomicUsize::new(0));
    let n_total = dilate_tiles.len();

    futures::stream::iter(dilate_tiles)
        .map(|(xtile, ytile)| {
            let pool = pool.clone();

            let client = client.clone();
            let n_progress = n_progress.clone();

            let url = format!(
                "https://cyberjapandata.gsi.go.jp/xyz/experimental_rdcl/16/{}/{}.geojson",
                xtile, ytile
            );

            async move {
                let response = match client.get(url).send().await {
                    Ok(inner) => inner,
                    Err(err) => {
                        println!("invalid response: {}", err);
                        return;
                    }
                };

                if response.status() != reqwest::StatusCode::OK {
                    println!("invalid status: {}", response.status());
                    return;
                }

                let text = match response.text().await {
                    Ok(inner) => inner,
                    Err(err) => {
                        println!("invalid content: {}", err);
                        return;
                    }
                };

                let geojson = match geojson::GeoJson::from_str(&text) {
                    Ok(inner) => inner,
                    Err(err) => {
                        println!("invalid format: {}", err);
                        return;
                    }
                };

                let feats = match geojson::FeatureCollection::try_from(geojson) {
                    Ok(inner) => inner,
                    Err(err) => {
                        println!("invalid format: {}", err);
                        return;
                    }
                };

                for feat in feats {
                    let geojson::Feature { geometry, .. } = feat;

                    let geometry = match geometry {
                        Some(inner) => inner,
                        None => {
                            println!("no geometry");
                            continue;
                        }
                    };

                    if geometry.value.type_name() != "LineString" {
                        println!("no LineString geometry");
                        continue;
                    }

                    let status = sqlx::query(
                        "INSERT INTO rdcl (geom) VALUES (ST_SetSRID(ST_GeomFromGeoJSON($1), 6668))",
                    )
                    .bind(geometry.to_string())
                    .execute(&pool)
                    .await;

                    if let Err(err) = status {
                        println!("{}", err);
                    }
                }

                let n_progress = n_progress.fetch_add(1, std::sync::atomic::Ordering::AcqRel);
                println!("PROGRESS: {}/{}", n_progress, n_total);
            }
        })
        .buffer_unordered(512)
        .collect::<Vec<_>>()
        .await;
}
