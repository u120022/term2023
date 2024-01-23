import numpy as np
import pandas as pd


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


def main():
    df = pd.read_csv("../compute/frame.csv")

    df["prefecture_code"] = df["city_code"] // 1000
    df["is_accident"] = df["accident"] == 't'

    df["accident_count"] = df["accident_count"].where(df["is_accident"], 1)
    df = df.iloc[df.index.repeat(df["accident_count"])]

    df = df.drop("geom", axis=1)
    df = df.drop("accident", axis=1)
    df = df.drop("accident_count", axis=1)

    df_c3 = df[df["count"] == 3]
    df_c4 = df[df["count"] == 4]

    df_c3 = df_c3.apply(df_c3_apply, axis=1)
    df_c4 = df_c4.apply(df_c4_apply, axis=1)

    df_c3 = df_c3[(df_c3["width_sw_1"] < 13.0) & (df_c3["width_sw_2"] < 13.0) & (df_c3["width_sw_3"] < 13.0)]
    df_c4 = df_c4[(df_c4["width_sw_1"] < 13.0) & (df_c4["width_sw_2"] < 13.0) & (df_c4["width_sw_3"] < 13.0) & (df_c4["width_sw_4"] < 13.0)]

    df = pd.concat([df_c3, df_c4])
    return df


df = main()
df.to_csv("frame.csv")
