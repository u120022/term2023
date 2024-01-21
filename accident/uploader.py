import numpy as np
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
x = dx + mx / 60.0 + sx / 3600.0

# convert deg-min-sec to digit for y
dy = y // 10000000
my = y // 100000 % 100
sy = y / 1000.0 % 100
y = dy + my / 60.0 + sy / 3600.0

# interprete as gis
y_rad = np.radians(y)

n_z16 = 2.0 ** 16
xtile_z16 = ((x + 180.0) / 360.0 * n_z16).astype("int")
ytile_z16 = ((1.0 - np.log(np.tan(y_rad) + (1 / np.cos(y_rad))) / np.pi) / 2.0 * n_z16).astype("int")

n_z18 = 2.0 ** 18
xtile_z18 = ((x + 180.0) / 360.0 * n_z18).astype("int")
ytile_z18 = ((1.0 - np.log(np.tan(y_rad) + (1 / np.cos(y_rad))) / np.pi) / 2.0 * n_z18).astype("int")

df["xtile_z16"] = xtile_z16
df["ytile_z16"] = ytile_z16
df["xtile_z18"] = xtile_z18
df["ytile_z18"] = ytile_z18
gdf = gpd.GeoDataFrame(df, geometry=gpd.points_from_xy(x, y), crs="EPSG:6668")
gdf.rename_geometry("geom", inplace=True)

# insert to db
engine = sqlalchemy.create_engine("postgresql://postgres:0@localhost:5432/postgres")
gdf.to_postgis("accident", engine)
