import asyncio

import pandas as pd
import geopandas as gpd
import sqlalchemy
import tqdm.asyncio

import lib


async def main():
    # # SVI extracting
    # points = await lib.async_get_pano_recursive(36.7447799, 137.002534, 2)
    # print("points: {}".format(len(points)))
    #
    # futures = [lib.async_download_pano_img(point.id, 3) for point in points]
    # for point, img in zip(points, await asyncio.gather(*futures)):
    #     print("img: {}".format(point.id))
    #     img.save("img/{}.png".format(point.id))

    # # box range vector map extracting
    # rdcl = await lib.async_get_rdcl((137.002534, 36.7447799), (137.012534, 36.7547799))
    # rdcl.to_file("rdcl.geojson", driver="GeoJSON")
    #
    # fgd = await lib.async_get_fgd((137.002534, 36.7447799), (137.012534, 36.7547799))
    # fgd.to_file("fgd.geojson", driver="GeoJSON")
    #
    # engine = sqlalchemy.create_engine("postgresql://postgres:0@localhost:5432/postgres")
    # rdcl.to_postgis("rdcl", engine)
    # fgd.to_postgis("fgd", engine)

    # # accident point vector map extracting
    # engine = sqlalchemy.create_engine("postgresql://postgres:0@localhost:5432/postgres")
    # df = pd.read_sql("tile_z16", engine)
    # 
    # futures = []
    # for _, item in df.iterrows():
    #     z = 16
    #     x = item["xtile"]
    #     y = item["ytile"]
    # 
    #     url_placeholder = "https://cyberjapandata.gsi.go.jp/xyz/experimental_rdcl/{}/{}/{}.geojson"
    #     url_actually = url_placeholder.format(z, x, y)
    #     futures.append(lib.async_request_content(url_actually))
    # 
    # asyncio = tqdm.asyncio.tqdm
    # contents = await asyncio.gather(*futures)
    # futures = [lib.async_content_to_geo(content) for content in contents]
    # gdf_list = await asyncio.gather(*futures)
    # gdf = gpd.pd.concat(gdf_list)
    # gdf.to_postgis("rdcl", engine)

    # accident point vector map extracting
    engine = sqlalchemy.create_engine("postgresql://postgres:0@localhost:5432/postgres")
    df = pd.read_sql("tile_z18", engine)
    
    futures = []
    for _, item in df.iterrows():
        z = 18
        x = item["xtile"]
        y = item["ytile"]
    
        url_placeholder = "https://cyberjapandata.gsi.go.jp/xyz/experimental_fgd/{}/{}/{}.geojson"
        url_actually = url_placeholder.format(z, x, y)
        futures.append(lib.async_request_content(url_actually))
    
    asyncio = tqdm.asyncio.tqdm
    contents = await asyncio.gather(*futures)
    futures = [lib.async_content_to_geo(content) for content in contents]
    gdf_list = await asyncio.gather(*futures)
    gdf = gpd.pd.concat(gdf_list)
    gdf.to_postgis("fgd", engine)


loop = asyncio.get_event_loop()
loop.run_until_complete(main())
