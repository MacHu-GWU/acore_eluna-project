# -*- coding: utf-8 -*-

"""
Google Sheet: https://docs.google.com/spreadsheets/d/1yAUSTbGuo-2pAKnb4TOzX_2GeWqnYPf30OVHSqJgoYk/edit?gid=243468138#gid=243468138
"""

import typing as T
from pathlib import Path
import polars as pl

df_list: T.List[pl.DataFrame] = list()

path_excel = (
    Path(__file__)
    .absolute()
    .parent.joinpath("World-of-Warcraft-WotLK-Teleport-GPS-传送坐标汇总.xlsx")
)


# --- 01-common
schema = dict(
    x=str,
    y=str,
    z=str,
    map=str,
    h1=str,
    h2=str,
    h3=str,
    h4=str,
    h5=str,
)


def parse_go_cmd(go_cmd: str) -> T.Tuple[str, str, str, str]:
    _, _, x, y, z, map = go_cmd.strip().split(" ")
    return x, y, z, map


df = pl.read_excel(f"{path_excel}", sheet_name="01-common")
rows = list()
for row in df.to_dicts():
    x, y, z, map = parse_go_cmd(go_cmd=row["go_cmd"])
    new_row = dict(
        x=x,
        y=y,
        z=z,
        map=map,
        h1="常用地点",
        h2=row["name"],
        h3=None,
        h4=None,
        h5=None,
    )
    rows.append(new_row)
df = pl.DataFrame(rows, schema=schema)
df_list.append(df)


# --- 07-zone_vanilla_eastern_kingdom
# --- 08-zone_vanilla_kalimdor
# --- 09-zone_tbc
# --- 10-zone_wlk
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
        # print(go_cmd.split(" ")) # for debug only
        x, y, z, map = parse_go_cmd(go_cmd=go_cmd)
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
    df = pl.DataFrame(rows, schema=schema)

    return df


for sheet_name, group_name in [
    ("07-zone_vanilla_eastern_kingdom", "经典旧世 东部王国"),
    ("08-zone_vanilla_kalimdor", "经典旧世 卡利姆多"),
    ("09-zone_tbc", "燃烧的远征 外域"),
    ("10-zone_wlk", "巫妖王之怒 北裂境"),
]:
    # print(sheet_name) # for debug only
    df_list.append(process_zone(sheet_name=sheet_name, group_name=group_name))

df = pl.concat(df_list)
df.write_csv("teleport_chat_command.tsv", separator="\t")
