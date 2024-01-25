import numpy as np
import pandas as pd
import pandarallel as pdl


pdl.pandarallel.initialize(progress_bar=True, nb_workers=12)


def extract_three_branch_crosspoint(df):
    df = df[df["count"] == 3].drop("count", axis=1)
    # df = df[(df["width_sw_1"] < 13.0) & (df["width_sw_2"] < 13.0) & (df["width_sw_3"] < 13.0)]

    df["argmin"] = np.argmin(df[["width_sw_1", "width_sw_2", "width_sw_3"]], axis=1)

    def applyer(row):
        argmin = row["argmin"]

        tmp = [row["width_sw_1"], row["width_sw_2"], row["width_sw_3"]]
        row["width_sw_1"] = tmp[(argmin + 0) % 3]
        row["width_sw_2"] = tmp[(argmin + 1) % 3]
        row["width_sw_3"] = tmp[(argmin + 2) % 3]

        tmp = [row["width_nosw_1"], row["width_nosw_2"], row["width_nosw_3"]]
        row["width_nosw_1"] = tmp[(argmin + 0) % 3]
        row["width_nosw_2"] = tmp[(argmin + 1) % 3]
        row["width_nosw_3"] = tmp[(argmin + 2) % 3]

        tmp = [row["dist_ob_1"], row["dist_ob_2"], row["dist_ob_3"]]
        row["dist_ob_1"] = tmp[(argmin + 0) % 3]
        row["dist_ob_2"] = tmp[(argmin + 1) % 3]
        row["dist_ob_3"] = tmp[(argmin + 2) % 3]

        tmp = [row["dist_noob_1"], row["dist_noob_2"], row["dist_noob_3"]]
        row["dist_noob_1"] = tmp[(argmin + 0) % 3]
        row["dist_noob_2"] = tmp[(argmin + 1) % 3]
        row["dist_noob_3"] = tmp[(argmin + 2) % 3]

        tmp = [row["angle_1"], row["angle_2"], row["angle_3"]]
        row["angle_1"] = tmp[(argmin + 0) % 3]
        row["angle_2"] = tmp[(argmin + 1) % 3]
        row["angle_3"] = tmp[(argmin + 2) % 3]

        return row

    df = df.parallel_apply(applyer, axis=1).drop("argmin", axis=1)
    return df


def extract_four_branch_crosspoint(df):
    df = df[df["count"] == 4].drop("count", axis=1)
    # df = df[(df["width_sw_1"] < 13.0) & (df["width_sw_2"] < 13.0) & (df["width_sw_3"] < 13.0) & (df["width_sw_4"] < 13.0)]
    df = df[(df["width_sw_1"] < 20.0) & (df["width_sw_2"] < 20.0) & (df["width_sw_3"] < 20.0) & (df["width_sw_4"] < 20.0)]

    df["argmin"] = np.argmin(df[["width_sw_1", "width_sw_2", "width_sw_3", "width_sw_4"]], axis=1)

    def applyer(row):
        argmin = row["argmin"]

        tmp = [row["width_sw_1"], row["width_sw_2"], row["width_sw_3"], row["width_sw_4"]]
        row["width_sw_1"] = tmp[(argmin + 0) % 4]
        row["width_sw_2"] = tmp[(argmin + 1) % 4]
        row["width_sw_3"] = tmp[(argmin + 2) % 4]
        row["width_sw_4"] = tmp[(argmin + 3) % 4]

        tmp = [row["width_nosw_1"], row["width_nosw_2"], row["width_nosw_3"], row["width_nosw_4"]]
        row["width_nosw_1"] = tmp[(argmin + 0) % 4]
        row["width_nosw_2"] = tmp[(argmin + 1) % 4]
        row["width_nosw_3"] = tmp[(argmin + 2) % 4]
        row["width_nosw_4"] = tmp[(argmin + 3) % 4]

        tmp = [row["dist_ob_1"], row["dist_ob_2"], row["dist_ob_3"], row["dist_ob_4"]]
        row["dist_ob_1"] = tmp[(argmin + 0) % 4]
        row["dist_ob_2"] = tmp[(argmin + 1) % 4]
        row["dist_ob_3"] = tmp[(argmin + 2) % 4]
        row["dist_ob_4"] = tmp[(argmin + 3) % 4]

        tmp = [row["dist_noob_1"], row["dist_noob_2"], row["dist_noob_3"], row["dist_noob_4"]]
        row["dist_noob_1"] = tmp[(argmin + 0) % 4]
        row["dist_noob_2"] = tmp[(argmin + 1) % 4]
        row["dist_noob_3"] = tmp[(argmin + 2) % 4]
        row["dist_noob_4"] = tmp[(argmin + 3) % 4]

        tmp = [row["angle_1"], row["angle_2"], row["angle_3"], row["angle_4"]]
        row["angle_1"] = tmp[(argmin + 0) % 4]
        row["angle_2"] = tmp[(argmin + 1) % 4]
        row["angle_3"] = tmp[(argmin + 2) % 4]
        row["angle_4"] = tmp[(argmin + 3) % 4]

        return row

    df = df.parallel_apply(applyer, axis=1).drop("argmin", axis=1)
    return df


def main():
    df = pd.read_csv("../compute/frame.csv")

    df = df.drop("geom", axis=1)

    df["is_accident"] = df["accident"] == 't'
    df = df.drop("accident", axis=1)

    df = df.iloc[df.index.repeat(df["accident_count"].where(df["is_accident"], 1))]
    df = df.drop("accident_count", axis=1)

    df["pref_code"] = df["city_code"] // 1000
    df = df.drop("city_code", axis=1)

    df_tbc = extract_three_branch_crosspoint(df)
    df_tbc["count"] = 3
    df_fbc = extract_four_branch_crosspoint(df)
    df_fbc["count"] = 4
    df = pd.concat([df_tbc, df_fbc]).reset_index(drop=True)

    return df


df = main()
df.to_csv("frame.csv")
