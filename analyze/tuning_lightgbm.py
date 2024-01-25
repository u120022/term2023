import pandas as pd
import sklearn.model_selection
import imblearn.over_sampling
import optuna.integration.lightgbm


df = pd.read_csv("frame.csv", index_col=0)
df = df[df["count"] == 4].drop("count", axis=1)

X = df.drop("is_accident", axis=1)
y = df["is_accident"]

X_train, X_test, y_train, y_test = sklearn.model_selection.train_test_split(X, y, test_size=0.2, random_state=42)
sampler = imblearn.over_sampling.SMOTE(random_state=42)
X_train, y_train = sampler.fit_resample(X_train, y_train)

params = {
    "objective": "binary",
    "metric": "binary_logloss",
    "boosting_type": "gbdt",
}

X_train, X_test, y_train, y_test = sklearn.model_selection.train_test_split(X_train, y_train, test_size=0.2, random_state=42)

db_train = optuna.integration.lightgbm.Dataset(X_train, y_train)
db_test = optuna.integration.lightgbm.Dataset(X_test, y_test)
booster = optuna.integration.lightgbm.train(params, db_train, valid_sets=db_test)

print(booster.params)
