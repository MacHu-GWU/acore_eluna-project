# -*- coding: utf-8 -*-

import typing as T
from pathlib import Path
import polars as pl

df_list: T.List[pl.DataFrame] = list()

path_excel = Path(__file__).absolute().parent.joinpath("World-of-Warcraft-WotLK-Teleport-GPS-传送坐标汇总.xlsx")

def process_zone(
    sheet_name: str,
    group_name: str,
):

    df = pl.read_excel(f"{path_excel}", sheet_name=sheet_name)
    df = df.filter(pl.col("go_cmd").is_not_null())
    df = df.sort(by="sk")
    df = df.select(["zone", "loc", "go_cmd"])
    rows = list()
    for row in df.to_dicts():
        go_cmd = row["go_cmd"]
        _, _, x, y, z, map = go_cmd.split(" ")
        new_row = dict(
            x=x,
            y=y,
            z=z,
            map=map,
            h1="大地图",
            h2=group_name,
            h3=row["zone"],
            h4=row["loc"],
            h5=None,
        )
        rows.append(new_row)
    df = pl.DataFrame(rows)


    return df

for sheet_name, group_name in [
    ("07-zone_vanilla_eastern_kingdom", "经典旧世东部王国"),
]:
    df_list.append(process_zone(sheet_name=sheet_name, group_name=group_name))

df = pl.concat(df_list)
df.write_csv("teleport_char_command.tsv", separator="\t")