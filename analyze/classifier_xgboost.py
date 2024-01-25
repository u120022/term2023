import pandas as pd
import sklearn.model_selection
import sklearn.decomposition
import sklearn.metrics
import imblearn.over_sampling
import xgboost
import matplotlib.pyplot as plt


df = pd.read_csv("frame.csv", index_col=0)
df = df[df["count"] == 4].drop("count", axis=1)

X = df.drop("is_accident", axis=1)
y = df["is_accident"]

X_train, X_test, y_train, y_test = sklearn.model_selection.train_test_split(X, y, shuffle=True, test_size=0.2, random_state=42)

sampler = imblearn.over_sampling.SMOTE(random_state=42)
X_train, y_train = sampler.fit_resample(X_train, y_train)

model = xgboost.XGBClassifier()
model.fit(X_train, y_train)

y_pred = model.predict(X_test)
print(sklearn.metrics.confusion_matrix(y_test, y_pred))
print("matthews corrcoef", sklearn.metrics.matthews_corrcoef(y_test, y_pred))
print("precision", sklearn.metrics.precision_score(y_test, y_pred))
print("recall", sklearn.metrics.recall_score(y_test, y_pred))
print("f1", sklearn.metrics.f1_score(y_test, y_pred))
print("log loss", sklearn.metrics.log_loss(y_test, y_pred))

xgboost.plot_importance(model)
plt.savefig("importance.png")

# import pandas as pd
# import matplotlib.pyplot as plt
# import sklearn.model_selection
# import sklearn.metrics
# import xgboost
#
# # extract only 4 branch crosspoint accident
# df = pd.read_csv("frame.csv")
# df = df[df["count"] == 4].drop("count", axis=1)
# X = df.drop("is_accident", axis=1)
# y = df["is_accident"]
#
# X_cv, X_eval, y_cv, y_eval = sklearn.model_selection.train_test_split(X, y, test_size=0.2)
# cv = sklearn.model_selection.KFold(n_splits=5, shuffle=True)
#
# model = xgboost.XGBClassifier()
#
# cv_params = {
#     "subsample": [0, 0.1, 0.2, 0.3, 0.4, 0.6, 0.7, 0.8, 0.9, 1.0],
#     "colsample_bytree": [0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0],
#     "reg_alpha": [0, 0.0001, 0.001, 0.01, 0.03, 0.1, 0.3, 1.0],
#     "reg_lambda": [0, 0.0001, 0.001, 0.01, 0.03, 0.1, 0.3, 1.0],
#     "learning_rate": [0, 0.0001, 0.001, 0.01, 0.03, 0.1, 0.3, 1.0],
#     "min_child_weight": [1, 3, 5, 7, 9, 11, 13, 15],
#     "max_depth": [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
#     "gamma": [0, 0.0001, 0.001, 0.01, 0.03, 0.1, 0.3, 1.0]
# }
#
# fit_params = {
#     "eval_set": [(X_eval, y_eval)]
# }
#
# scores = sklearn.model_selection.cross_val_score(model, X_cv, y_cv, cv=cv, scoring="f1", fit_params=fit_params, n_jobs=-1)
# print(scores)

# show fig
# param_scales = {
#     "subsample": "linear",
#     "colsample_bytree": "linear",
#     "reg_alpha": "log",
#     "reg_lambda": "log",
#     "learning_rate": "log",
#     "min_child_weight": "linear",
#     "max_depth": "linear",
#     "gamma": "log"
# }
#
# for i, (k, v) in enumerate(cv_params.items()):
#     train_scores, valid_scores = sklearn.model_selection.validation_curve(estimator=model, X=X_cv, y=y_cv, param_name=k, param_range=v, cv=cv, scoring="f1", fit_params=fit_params, n_jobs=-1)
#
#     plt.figure()
#     plt.plot(v, train_scores, color="blue")
#     plt.plot(v, valid_scores, color="green")
#     plt.xscale(param_scales[k])
#     plt.savefig(k)
#
# # hyper parameters grid search
# cv_params = {
#     "learning_rate": [0.01, 0.03, 0.1, 0.3],
#     "min_child_weight": [2, 4, 6, 8],
#     "max_depth": [1, 2, 3, 4],
#     "colsample_bytree": [0.2, 0.5, 0.8, 1.0],
#     "subsample": [0.2, 0.5, 0.8, 1.0]
# }
# grid_cv = sklearn.model_selection.GridSearchCV(model, cv_params, cv=cv, scoring="f1", n_jobs=-1)
# grid_cv.fit(X, y, **fit_params)
# print(grid_cv.best_params_, grid_cv.best_score_)
