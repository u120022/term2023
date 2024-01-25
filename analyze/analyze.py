import pandas as pd
import matplotlib.pyplot as plt


df = pd.read_csv("frame.csv", index_col=0)
df = df[df["count"] == 4].drop("count", axis=1)

plt.figure()
df[df["is_accident"]].hist()
plt.savefig("positive.png")

plt.figure()
df[~df["is_accident"]].hist()
plt.savefig("negative.png")
