import pandas as pd
import matplotlib.pyplot as plt
import sklearn.model_selection
import sklearn.metrics
import xgboost

df = pd.read_csv("frame.csv")
print(df)

# only 4 branch
df = df[df["count"] == 4].drop("count", axis=1)

X = df.drop("is_accident", axis=1)
y = df["is_accident"]

cv = sklearn.model_selection.KFold(n_splits=5, shuffle=True)

cv_params = {
    "subsample": [0, 0.1, 0.2, 0.3, 0.4, 0.6, 0.7, 0.8, 0.9, 1.0],
    "colsample_bytree": [0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0],
    "reg_alpha": [0, 0.0001, 0.001, 0.01, 0.03, 0.1, 0.3, 1.0],
    "reg_lambda": [0, 0.0001, 0.001, 0.01, 0.03, 0.1, 0.3, 1.0],
    "learning_rate": [0, 0.0001, 0.001, 0.01, 0.03, 0.1, 0.3, 1.0],
    "min_child_weight": [1, 3, 5, 7, 9, 11, 13, 15],
    "max_depth": [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
    "gamma": [0, 0.0001, 0.001, 0.01, 0.03, 0.1, 0.3, 1.0]
}

model = xgboost.XGBClassifier()

for i, (k, v) in enumerate(cv_params.items()):
    train_scores, valid_scores = sklearn.model_selection.validation_curve(estimator=model, X=X, y=y, param_name=k, param_range=v, cv=cv)

    plt.figure()
    plt.plot(v, train_scores, color="blue")
    plt.plot(v, valid_scores, color="green")
    plt.savefig(k)
