import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import sklearn.ensemble
import sklearn.model_selection
import sklearn.metrics
import xgboost


def prepare():
    df = pd.read_csv("../compute/frame.csv")
    df.drop("geom", axis=1, inplace=True)

    df_c3 = df[df["count"] == 3]
    df_c4 = df[df["count"] == 4]

    df_c3 = df_c3.apply(df_c3_apply, axis=1)
    df_c4 = df_c4.apply(df_c4_apply, axis=1)

    df_c3 = df_c3[(df_c3["width_sw_1"] < 11.0) & (df_c3["width_sw_2"] < 11.0) & (df_c3["width_sw_3"] < 11.0)]
    df_c4 = df_c4[(df_c4["width_sw_1"] < 11.0) & (df_c4["width_sw_2"] < 11.0) & (df_c4["width_sw_3"] < 11.0) & (df_c4["width_sw_4"] < 11.0)]

    # # plot histogram
    # df_c3[df_c3["category"] == 1].hist(figsize=(20, 20))
    # plt.savefig("c3_true.png")
    #
    # df_c3[df_c3["category"] == 0].hist(figsize=(20, 20))
    # plt.savefig("c3_false.png")
    #
    # df_c4[df_c4["category"] == 1].hist(figsize=(20, 20))
    # plt.savefig("c4_true.png")
    #
    # df_c4[df_c4["category"] == 0].hist(figsize=(20, 20))
    # plt.savefig("c4_false.png")

    # df = pd.concat([df_c3, df_c4])
    # return df
    return df_c4


def df_c3_apply(row):
    angles = [
        row["angle_1"],
        row["angle_2"],
        row["angle_3"],
    ]

    dists_ob = [
        row["dist_ob_1"],
        row["dist_ob_2"],
        row["dist_ob_3"],
    ]

    dists_noob = [
        row["dist_noob_1"],
        row["dist_noob_2"],
        row["dist_noob_3"],
    ]

    widths_sw = [
        row["width_sw_1"],
        row["width_sw_2"],
        row["width_sw_3"],
    ]

    widths_nosw = [
        row["width_nosw_1"],
        row["width_nosw_2"],
        row["width_nosw_3"],
    ]

    idx_0 = np.argsort(widths_sw)[0]
    idx_1 = (idx_0 + 1) % 3
    idx_2 = (idx_1 + 1) % 3

    row["angle_1"] = angles[idx_0]
    row["angle_2"] = angles[idx_1]
    row["angle_3"] = angles[idx_2]

    row["dist_ob_1"] = dists_ob[idx_0]
    row["dist_ob_2"] = dists_ob[idx_1]
    row["dist_ob_3"] = dists_ob[idx_2]

    row["dist_noob_1"] = dists_noob[idx_0]
    row["dist_noob_2"] = dists_noob[idx_1]
    row["dist_noob_3"] = dists_noob[idx_2]

    row["width_sw_1"] = widths_sw[idx_0]
    row["width_sw_2"] = widths_sw[idx_1]
    row["width_sw_3"] = widths_sw[idx_2]

    row["width_nosw_1"] = widths_nosw[idx_0]
    row["width_nosw_2"] = widths_nosw[idx_1]
    row["width_nosw_3"] = widths_nosw[idx_2]

    return row


def df_c4_apply(row):
    angles = [
        row["angle_1"],
        row["angle_2"],
        row["angle_3"],
        row["angle_4"],
    ]

    dists_ob = [
        row["dist_ob_1"],
        row["dist_ob_2"],
        row["dist_ob_3"],
        row["dist_ob_4"],
    ]

    dists_noob = [
        row["dist_noob_1"],
        row["dist_noob_2"],
        row["dist_noob_3"],
        row["dist_noob_4"],
    ]

    widths_sw = [
        row["width_sw_1"],
        row["width_sw_2"],
        row["width_sw_3"],
        row["width_sw_4"],
    ]

    widths_nosw = [
        row["width_nosw_1"],
        row["width_nosw_2"],
        row["width_nosw_3"],
        row["width_nosw_4"],
    ]

    idx_0 = np.argsort(widths_sw)[0]
    idx_1 = (idx_0 + 1) % 4
    idx_2 = (idx_1 + 1) % 4
    idx_3 = (idx_2 + 1) % 4

    row["angle_1"] = angles[idx_0]
    row["angle_2"] = angles[idx_1]
    row["angle_3"] = angles[idx_2]
    row["angle_4"] = angles[idx_3]

    row["dist_ob_1"] = dists_ob[idx_0]
    row["dist_ob_2"] = dists_ob[idx_1]
    row["dist_ob_3"] = dists_ob[idx_2]
    row["dist_ob_4"] = dists_ob[idx_3]

    row["dist_noob_1"] = dists_noob[idx_0]
    row["dist_noob_2"] = dists_noob[idx_1]
    row["dist_noob_3"] = dists_noob[idx_2]
    row["dist_noob_4"] = dists_noob[idx_3]

    row["width_sw_1"] = widths_sw[idx_0]
    row["width_sw_2"] = widths_sw[idx_1]
    row["width_sw_3"] = widths_sw[idx_2]
    row["width_sw_4"] = widths_sw[idx_3]

    row["width_nosw_1"] = widths_nosw[idx_0]
    row["width_nosw_2"] = widths_nosw[idx_1]
    row["width_nosw_3"] = widths_nosw[idx_2]
    row["width_nosw_4"] = widths_nosw[idx_3]

    return row


df = prepare()
x = df.drop("category", axis=1)
y = df["category"]
x_train, x_test, y_train, y_test = sklearn.model_selection.train_test_split(x, y, test_size=0.2)

# # random forest classifier
# model = sklearn.ensemble.RandomForestClassifier()
# model.fit(x_train, y_train)
# y_pred = model.predict(x_test).round(decimals=1)
#
# print("confusion matrix", sklearn.metrics.confusion_matrix(y_test, y_pred))
# print("accuracy", sklearn.metrics.accuracy_score(y_test, y_pred))
# print("precision", sklearn.metrics.precision_score(y_test, y_pred))
# print("recall", sklearn.metrics.recall_score(y_test, y_pred))
# print("f1", sklearn.metrics.f1_score(y_test, y_pred))
#
# impl_df = pd.DataFrame()
# impl_df["name"] = df.columns[:-1]
# impl_df["importance"] = model.feature_importances_
# impl_df.sort_values("importance", inplace=True)
# print("importance", impl_df)

# XGBoost
model = xgboost.XGBClassifier()
model.fit(x_train, y_train, eval_set=[(x_test, y_test)], verbose=True)
y_pred = model.predict(x_test).round(decimals=1)

print("confusion matrix", sklearn.metrics.confusion_matrix(y_test, y_pred))
print("accuracy", sklearn.metrics.accuracy_score(y_test, y_pred))
print("precision", sklearn.metrics.precision_score(y_test, y_pred))
print("recall", sklearn.metrics.recall_score(y_test, y_pred))
print("f1", sklearn.metrics.f1_score(y_test, y_pred))
