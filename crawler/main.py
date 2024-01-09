import asyncio

import sqlalchemy

import lib


async def main():
    # points = await lib.async_get_pano_recursive(36.7447799, 137.002534, 2)
    # print("points: {}".format(len(points)))
    #
    # futures = [lib.async_download_pano_img(point.id, 3) for point in points]
    # for point, img in zip(points, await asyncio.gather(*futures)):
    #     print("img: {}".format(point.id))
    #     img.save("img/{}.png".format(point.id))

    rdcl = await lib.async_get_rdcl((137.002534, 36.7447799), (137.012534, 36.7547799))
    rdcl.to_file("rdcl.geojson", driver="GeoJSON")

    fgd = await lib.async_get_fgd((137.002534, 36.7447799), (137.012534, 36.7547799))
    fgd.to_file("fgd.geojson", driver="GeoJSON")

    engine = sqlalchemy.create_engine("postgresql://postgres:0@localhost:5432/postgres")
    rdcl.to_postgis("rdcl", engine)
    fgd.to_postgis("fgd", engine)



loop = asyncio.get_event_loop()
loop.run_until_complete(main())
