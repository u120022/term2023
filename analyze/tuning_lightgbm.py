import pandas as pd
import sklearn.model_selection
import imblearn.over_sampling
import optuna.integration.lightgbm


df = pd.read_csv("frame.csv", index_col=0)
df = df[df["count"] == 4].drop("count", axis=1)

X = df.drop("is_accident", axis=1)
y = df["is_accident"]

print(len(y), y.sum())

X_train, X_test, y_train, y_test = sklearn.model_selection.train_test_split(X, y, test_size=0.2, random_state=42)

X_train, X_valid, y_train, y_valid = sklearn.model_selection.train_test_split(X_train, y_train, shuffle=True, test_size=0.125, random_state=42)

print(len(X_test), len(X_valid), len(X_train))

sampler = imblearn.over_sampling.SMOTE(random_state=42)
X_train, y_train = sampler.fit_resample(X_train, y_train)

print(len(X_test), len(X_valid), len(X_train))

params = {
    "objective": "binary",
    "metric": "binary_logloss",
    "boosting_type": "gbdt",
}
db_train = optuna.integration.lightgbm.Dataset(X_train, y_train)
db_test = optuna.integration.lightgbm.Dataset(X_valid, y_valid)
model = optuna.integration.lightgbm.train(params, db_train, valid_sets=db_test)

print(model.params)

y_pred = (model.predict(X_test) > 0.5).astype(int)

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
