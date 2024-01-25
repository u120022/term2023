import pandas as pd
import sklearn.model_selection
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

params = {
    'objective': 'binary',
    'metric': 'binary_logloss',
    'boosting_type': 'gbdt',
    'lambda_l1': 5.239920820051315e-08,
    'lambda_l2': 2.628251543274538,
    'num_leaves': 52,
    'feature_fraction': 0.8,
    'bagging_fraction': 0.8968345784165385,
    'bagging_freq': 6,
    'min_child_samples': 20,
}
model = lightgbm.LGBMClassifier(**params)
model.fit(X_train, y_train)

y_pred = model.predict(X_test, num_iterations=1000)

tn, fp, fn, tp = sklearn.metrics.confusion_matrix(y_test, y_pred).ravel()
print(tn, fp, tn + fp, sep="\t")
print(fn, tp, fn + tp, sep="\t")
print(tn + fn, fp + tp, tn + fp + fn + tp, sep="\t")

print("accuracy", sklearn.metrics.accuracy_score(y_test, y_pred))
print("precision", sklearn.metrics.precision_score(y_test, y_pred))
print("recall", sklearn.metrics.recall_score(y_test, y_pred))
print("f1", sklearn.metrics.f1_score(y_test, y_pred))
print("matthews corrcoef", sklearn.metrics.matthews_corrcoef(y_test, y_pred))
print("log loss", sklearn.metrics.log_loss(y_test, y_pred))

lightgbm.plot_importance(model)
plt.savefig("importance.png")
