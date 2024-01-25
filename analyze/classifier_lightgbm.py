import pandas as pd
import sklearn.model_selection
import sklearn.decomposition
import sklearn.metrics
import imblearn.over_sampling
import lightgbm
import matplotlib.pyplot as plt


df = pd.read_csv("frame.csv", index_col=0)
df = df[df["count"] == 4].drop("count", axis=1)

X = df.drop("is_accident", axis=1)
y = df["is_accident"]

X_train, X_test, y_train, y_test = sklearn.model_selection.train_test_split(X, y, shuffle=True, test_size=0.2, random_state=42)

sampler = imblearn.over_sampling.SMOTE(random_state=42)
X_train, y_train = sampler.fit_resample(X_train, y_train)

model = lightgbm.LGBMClassifier()
model.fit(X_train, y_train)

y_pred = model.predict(X_test)
print(sklearn.metrics.confusion_matrix(y_test, y_pred))
print("matthews corrcoef", sklearn.metrics.matthews_corrcoef(y_test, y_pred))
print("precision", sklearn.metrics.precision_score(y_test, y_pred))
print("recall", sklearn.metrics.recall_score(y_test, y_pred))
print("f1", sklearn.metrics.f1_score(y_test, y_pred))
print("log loss", sklearn.metrics.log_loss(y_test, y_pred))

lightgbm.plot_importance(model)
plt.savefig("importance.png")
