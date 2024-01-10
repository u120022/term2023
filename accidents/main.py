import pandas as pd
import geopandas as gpd
import sqlalchemy

# concat
dfs = [
    pd.read_csv("honhyo_2019.csv", encoding="sjis"),
    pd.read_csv("honhyo_2020.csv", encoding="sjis"),
    pd.read_csv("honhyo_2021.csv", encoding="sjis"),
    pd.read_csv("honhyo_2022.csv", encoding="sjis"),
]
df = pd.concat(dfs)

x = df["地点　経度（東経）"]
y = df["地点　緯度（北緯）"] 

# convert deg-min-sec to digit for x
dx = x // 10000000
mx = x // 100000 % 100
sx = x / 1000.0 % 100
new_x = dx + mx / 60.0 + sx / 3600.0

# convert deg-min-sec to digit for y
dy = y // 10000000
my = y // 100000 % 100
sy = y / 1000.0 % 100
new_y = dy + my / 60.0 + sy / 3600.0

# interprete as gis
gdf = gpd.GeoDataFrame(df, geometry=gpd.points_from_xy(new_x, new_y), crs="EPSG:4326")

# insert to db
engine = sqlalchemy.create_engine("postgresql://postgres:0@localhost:5432/postgres")
gdf.to_postgis("accident", engine)
