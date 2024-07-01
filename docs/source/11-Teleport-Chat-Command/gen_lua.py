# -*- coding: utf-8 -*-

"""
Google Sheet: https://docs.google.com/spreadsheets/d/1yAUSTbGuo-2pAKnb4TOzX_2GeWqnYPf30OVHSqJgoYk/edit?gid=243468138#gid=243468138
"""

import typing as T
from pathlib import Path

import polars as pl
import acore_eluna.tree_menu.api as tree_menu

df_list: T.List[pl.DataFrame] = list()

dir_here = Path(__file__).absolute().parent
path_excel = dir_here.joinpath("World-of-Warcraft-WotLK-Teleport-GPS-传送坐标汇总.xlsx")

schema = dict(
    x=str,
    y=str,
    z=str,
    map=str,
    _icon=int,
    _h1=str,
    _h2=str,
    _h3=str,
    _h4=str,
    _h5=str,
)


def parse_go_cmd(go_cmd: str) -> T.Tuple[str, str, str, str]:
    _, _, x, y, z, map = go_cmd.strip().split(" ")
    return x, y, z, map


# --- 01-common
df = pl.read_excel(f"{path_excel}", sheet_name="01-common")
rows = list()
for row in df.to_dicts():
    x, y, z, map = parse_go_cmd(go_cmd=row["go_cmd"])
    new_row = dict(
        x=x,
        y=y,
        z=z,
        map=map,
        _icon=None,
        _h1="常用地点",
        _h2=row["name"],
        _h3=None,
        _h4=None,
        _h5=None,
    )
    rows.append(new_row)
df = pl.DataFrame(rows, schema=schema)
df_list.append(df)

# --- 02-class_skill_trainer
df = pl.read_excel(f"{path_excel}", sheet_name="02-class_skill_trainer")
df = df.filter(pl.col("go_cmd").is_not_null())
rows = list()
for row in df.to_dicts():
    x, y, z, map = parse_go_cmd(go_cmd=row["go_cmd"])
    new_row = dict(
        x=x,
        y=y,
        z=z,
        map=map,
        _icon=None,
        _h1="职业技能训练师",
        _h2=row["faction"],
        _h3=row["class"],
        _h4=None,
        _h5=None,
    )
    rows.append(new_row)
df = pl.DataFrame(rows, schema=schema)
df_list.append(df)

# --- 03-trade_skill_trainer
df = pl.read_excel(f"{path_excel}", sheet_name="03-trade_skill_trainer")
df = df.filter(pl.col("go_cmd").is_not_null())
rows = list()
for row in df.to_dicts():
    x, y, z, map = parse_go_cmd(go_cmd=row["go_cmd"])
    new_row = dict(
        x=x,
        y=y,
        z=z,
        map=map,
        _icon=None,
        _h1="商业技能训练师",
        _h2=row["faction"],
        _h3=row["category"],
        _h4=row["sub_category"],
        _h5=None,
    )
    rows.append(new_row)
df = pl.DataFrame(rows, schema=schema)
df_list.append(df)

# --- 04-main_city
df = pl.read_excel(f"{path_excel}", sheet_name="04-main_city")
df = df.filter(pl.col("go_cmd").is_not_null())
rows = list()
for row in df.to_dicts():
    x, y, z, map = parse_go_cmd(go_cmd=row["go_cmd"])
    new_row = dict(
        x=x,
        y=y,
        z=z,
        map=map,
        _icon=None,
        _h1="主城",
        _h2=row["zone"],
        _h3=row["loc_name"],
        _h4=None,
        _h5=None,
    )
    rows.append(new_row)
df = pl.DataFrame(rows, schema=schema)
df_list.append(df)

# --- 05-instance
df = pl.read_excel(f"{path_excel}", sheet_name="05-instance")
df = df.filter(pl.col("go_cmd").is_not_null())
rows = list()
for row in df.to_dicts():
    print(row)
    x, y, z, map = parse_go_cmd(go_cmd=row["go_cmd"])
    new_row = dict(
        x=x,
        y=y,
        z=z,
        map=map,
        _icon=None,
        _h1="副本",
        _h2=row["exp"],
        _h3=row["instance_type"],
        _h4=row["name"],
        _h5=row["loc"],
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
            _icon=None,
            _h1="大地图",
            _h2=group_name,
            _h3=row["zone"],
            _h4=row["loc"],
            _h5=None,
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
df.write_csv("teleport_player_chat_command.tsv", separator="\t")


# --- Generate Lua Code
def data_to_lua_code(data: dict) -> str:
    x = data["x"]
    y = data["y"]
    z = data["z"]
    map = data["map"]
    return f"{{ x = {x}, y = {y}, z = {z}, map = {map} }}"


lua_code_generator = tree_menu.LuaCodeGenerator(
    id_start=370001,
    item_option_icon=tree_menu.IconEnum.GOSSIP_ICON_TAXI,
    back_to_prev="返回 {parent_name}",
    back_to_top="返回 主菜单",
)
option_list = lua_code_generator.dataframe_to_option_list(df)
lua_code = lua_code_generator.generate_lua_code(option_list, data_to_lua_code)
path_lua = dir_here / "lua_code.lua"
path_lua.write_text(lua_code)
