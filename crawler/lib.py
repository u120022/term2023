import asyncio
import urllib.request
import re
import io
import json
import math

import PIL.Image
import geopandas as gpd


class Pano:
    id: str
    lat: float
    lon: float
    year: int
    month: int

    def __init__(self, id: str, lat: float, lon: float, year: int, month: int) -> None:
        self.id = id
        self.lat = lat
        self.lon = lon
        self.year = year
        self.month = month


class NeighborPano:
    id: str
    lat: float
    lon: float

    def __init__(self, id: str, lat: float, lon: float) -> None:
        self.id = id
        self.lat = lat
        self.lon = lon


async def async_request_content(url: str) -> bytes | None:
    def request_content(url: str) -> bytes:
        try:
            request = urllib.request.Request(url)
            with urllib.request.urlopen(request) as responce:
                print("OK", url)
                return responce.read()
        except Exception as e:
            print(e, url)
    loop = asyncio.get_running_loop()
    return await loop.run_in_executor(None, request_content, url)


async def async_get_panoid(lat: float, lon: float) -> tuple[Pano, list[NeighborPano]]:
    url_placeholder = "https://maps.googleapis.com/maps/api/js/GeoPhotoService.SingleImageSearch?pb=!1m5!1sapiv3!5sUS!11m2!1m1!1b0!2m4!1m2!3d{}!4d{}!2d50!3m10!2m2!1sen!2sGB!9m1!1e2!11m4!1m3!1e2!2b1!3e2!4m10!1e1!1e2!1e3!1e4!1e8!1e6!5m1!1e2!6m1!1e2&callback=_xdc_._v2mub5"
    url_actualy = url_placeholder.format(lat, lon)
    content = await async_request_content(url_actualy)
    text = content.decode()

    matches = re.findall('\[[0-9]+,"(.+?)"\].+?\[\[null,null,(-?[0-9]+.[0-9]+),(-?[0-9]+.[0-9]+)', text)
    entries_0 = [(id, float(lat), float(lon)) for id, lat, lon in matches]

    matches = re.findall('\[(20[0-9][0-9]),([1-9]|1[0-2])\]', text)
    entries_1 = [(int(year), int(month)) for year, month in matches]

    (id, lat, lon), (year, month) = entries_0[0], entries_1[-1]
    pano = Pano(id, lat, lon, year, month)
    neighbors = [NeighborPano(id, lat, lon) for id, lat, lon in entries_0[1:]]
    return pano, neighbors


async def async_get_panoid_recursive(lat: float, lon: float, level: int) -> list[Pano]:
    result, next, history = set(), set(), set()
    next.add((None, lat, lon))

    for _ in range(0, level):
        history |= set([id for id, _, _ in next])
        futures = [async_get_panoid(lat, lon) for _, lat, lon in next]

        flatten = set()
        for pano, neighbors in await asyncio.gather(*futures):
            result.add((pano.id, pano.lat, pano.lon, pano.year, pano.month))
            flatten |= set([(neighbor.id, neighbor.lat, neighbor.lon) for neighbor in neighbors])

        next = set(flatten) - history

    return [Pano(id, lat, lon, year, month) for id, lat, lon, year, month in result]


def get_panoid_recursive(lat: float, lon: float, level: int) -> list[Pano]:
    loop = asyncio.get_event_loop()
    return loop.run_until_complete(async_get_panoid_recursive(lat, lon, level))


async def async_decode_img(content: bytes) -> PIL.Image.Image:
    def decode_img(content: bytes) -> PIL.Image.Image:
        return PIL.Image.open(io.BytesIO(content))
    
    loop = asyncio.get_running_loop()
    return await loop.run_in_executor(None, decode_img, content)


async def async_stitch_img(entries: list[tuple[PIL.Image.Image, tuple[int, int]]], size: tuple[int, int]) -> PIL.Image.Image:
    def stitch_pano_img(entries: list[tuple[PIL.Image.Image, tuple[int, int]]], size: tuple[int, int]) -> PIL.Image.Image:
        size_x, size_y = size
        img = PIL.Image.new("RGB", (size_x * 512, size_y * 512))
        for tile_img, (x, y) in entries:
            img.paste(tile_img, (x * 512, y * 512))
        return img
    
    loop = asyncio.get_running_loop()
    return await loop.run_in_executor(None, stitch_pano_img, entries, size)


async def async_get_panoimg(id: str, subdivision: int) -> PIL.Image.Image:
    idx, futures = [], []

    max_x, max_y = 2 << (subdivision - 1), 1 << (subdivision - 1)
    for x in range(0, max_x):
        for y in range(0, max_y):
            idx.append((x, y))

            url_placeholder = "https://streetviewpixels-pa.googleapis.com/v1/tile?cb_client=maps_sv.tactile&panoid={}&x={}&y={}&zoom={}"
            url_actualy = url_placeholder.format(id, x, y, subdivision)
            futures.append(async_request_content(url_actualy))

    contents = await asyncio.gather(*futures)

    futures = [async_decode_img(content) for content in contents]
    tile_imgs = await asyncio.gather(*futures)

    return await async_stitch_img(zip(tile_imgs, idx), (max_x, max_y))


def get_panoimg(id: str, subdivision: int) -> PIL.Image.Image:
    loop = asyncio.get_event_loop()
    return loop.run_until_complete(async_get_panoimg(id, subdivision))

async def async_content_to_geo(content: bytes) -> gpd.GeoDataFrame:
    def content_to_geo(content: bytes | None) -> gpd.GeoDataFrame:
        if content:
            data = json.loads(content)
            gdf = gpd.GeoDataFrame.from_features(data["features"], crs="EPSG:6668") # JGD2011 degree
            gdf = gdf.to_crs("EPSG:3857") # WGS84 meter
            return gdf
        else:
            return gpd.GeoDataFrame()
    loop = asyncio.get_running_loop()
    return await loop.run_in_executor(None, content_to_geo, content)

def to_tile(x: float, y: float, z: int) -> tuple[int, int]:
    x = int((x / 180.0 + 1.0) * 2.0 ** z / 2.0)
    y = int((-math.log(math.tan((45.0 + y / 2.0) * math.pi / 180.0)) + math.pi) * 2.0 ** z / (2.0 * math.pi))
    return x, y

async def async_get_rdcl(p0: tuple[float, float], p1: tuple[float, float]) -> gpd.GeoDataFrame:
    zoom = 16
    t0 = to_tile(*p0, zoom)
    t1 = to_tile(*p1, zoom)
    x0, x1 = min(t0[0], t1[0]), max(t0[0], t1[0])
    y0, y1 = min(t0[1], t1[1]), max(t0[1], t1[1])
    print("({}, {}) - ({}, {})".format(x0, y0, x1, y1))

    futures = []
    for x in range(x0, x1):
        for y in range(y0, y1):
            url_placeholder = "https://cyberjapandata.gsi.go.jp/xyz/experimental_rdcl/{}/{}/{}.geojson"
            url_actually = url_placeholder.format(zoom, x, y)
            futures.append(async_request_content(url_actually))

    contents = await asyncio.gather(*futures)
    futures = [async_content_to_geo(content) for content in contents]
    gdf_list = await asyncio.gather(*futures)
    gdf = gpd.pd.concat(gdf_list)
    return gdf

async def async_get_fgd(p0: tuple[float, float], p1: tuple[float, float]) -> gpd.GeoDataFrame:
    zoom = 18
    t0 = to_tile(*p0, zoom)
    t1 = to_tile(*p1, zoom)
    x0, x1 = min(t0[0], t1[0]), max(t0[0], t1[0])
    y0, y1 = min(t0[1], t1[1]), max(t0[1], t1[1])
    print("({}, {}) - ({}, {})".format(x0, y0, x1, y1))

    futures = []
    for x in range(x0, x1):
        for y in range(y0, y1):
            url_placeholder = "https://cyberjapandata.gsi.go.jp/xyz/experimental_fgd/{}/{}/{}.geojson"
            url_actually = url_placeholder.format(zoom, x, y)
            futures.append(async_request_content(url_actually))

    contents = await asyncio.gather(*futures)
    futures = [async_content_to_geo(content) for content in contents]
    gdf_list = await asyncio.gather(*futures)
    gdf = gpd.pd.concat(gdf_list)
    return gdf
