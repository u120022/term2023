use std::str::FromStr;
use futures::StreamExt;

#[tokio::main]
async fn main() {
    println!("start rdcl");
    #[rustfmt::skip]
    let url_gen = |xtile, ytile| format!("https://cyberjapandata.gsi.go.jp/xyz/experimental_rdcl/16/{}/{}.geojson", xtile, ytile);
    execute("../accidents/tile_z16.csv", "rdcl.geojson", url_gen).await;

    println!("start fgd");
    #[rustfmt::skip]
    let url_gen = |xtile, ytile| format!("https://cyberjapandata.gsi.go.jp/xyz/experimental_fgd/18/{}/{}.geojson", xtile, ytile);
    execute("../accidents/tile_z18.csv", "fgd.geojson", url_gen).await;
}

async fn execute<
    P: AsRef<std::path::Path>,
    Q: AsRef<std::path::Path>,
    F: Fn(i64, i64) -> String,
>(
    tile_file: P,
    output_file: Q,
    url_gen: F,
) {
    let mut tiles = vec![];

    let file = std::fs::File::open(tile_file).unwrap();
    let mut reader = csv::Reader::from_reader(file);
    for record in reader.records() {
        if let Ok(record) = record {
            let xtile: i64 = record.get(0).unwrap().parse().unwrap();
            let ytile: i64 = record.get(1).unwrap().parse().unwrap();
            tiles.push((xtile, ytile));
        }
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

    let client = reqwest::Client::new();
    let n_progress = std::sync::Arc::new(std::sync::atomic::AtomicUsize::new(0));
    let n_successful = std::sync::Arc::new(std::sync::atomic::AtomicUsize::new(0));
    let n_total = dilate_tiles.len();

    let feats_vec = futures::stream::iter(dilate_tiles)
        .map(|(xtile, ytile)| {
            let client = client.clone();
            let n_progress = n_progress.clone();
            let n_successful = n_successful.clone();

            let url = url_gen(xtile, ytile);

            async move {
                let mut out = None;

                let response = client.get(url).send().await.unwrap();

                let status = response.status();
                if status == reqwest::StatusCode::OK {
                    let text = response.text().await.unwrap();

                    let geojson = geojson::GeoJson::from_str(&text).unwrap();

                    let feats = geojson::FeatureCollection::try_from(geojson).unwrap();

                    n_successful.fetch_add(1, std::sync::atomic::Ordering::Release);

                    out = Some(feats);
                } else {
                    println!("RESPONSE ERR: {}", status);
                }

                n_progress.fetch_add(1, std::sync::atomic::Ordering::Release);

                let n_progress = n_progress.load(std::sync::atomic::Ordering::Acquire);
                let n_successful = n_successful.load(std::sync::atomic::Ordering::Acquire);
                println!("PROGRESS: {}/{}, (OK: {}/{})", n_progress, n_total, n_successful, n_total);

                out
            }
        })
        .buffer_unordered(512)
        .collect::<Vec<_>>()
        .await;

    let mut concat_feats = geojson::FeatureCollection {
        bbox: None,
        features: vec![],
        foreign_members: None,
    };

    for feats in feats_vec {
        if let Some(mut feats) = feats {
            concat_feats.features.append(&mut feats.features);
        }
    }

    println!("writting file ...");
    let geojson = geojson::GeoJson::FeatureCollection(concat_feats);
    std::fs::write(output_file, geojson.to_string()).unwrap();
}
