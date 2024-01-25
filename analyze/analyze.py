import pandas as pd
import sklearn.cluster
import sklearn.decomposition
import matplotlib.pyplot as plt


df = pd.read_csv("frame.csv", index_col=0)
df = df[df["count"] == 4].drop("count", axis=1)

wcss = []
for i in range(0, 10):
    model = sklearn.cluster.KMeans(n_clusters=i + 1, random_state=0)
    model.fit(df)
    wcss.append(model.inertia_)

plt.figure()
plt.plot(range(0, 10), wcss)
plt.savefig("wcss.png")


pca = sklearn.decomposition.PCA(n_components=3)
pca.fit(df)

plt.figure()
plt.bar(range(0, len(pca.explained_variance_ratio_)), pca.explained_variance_ratio_)
plt.savefig("explain.png")
