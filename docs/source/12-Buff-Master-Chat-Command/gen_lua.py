# -*- coding: utf-8 -*-

"""
Google Sheet: https://docs.google.com/spreadsheets/d/1SAp5hNKOlWyVzv6sbdOf3LeOTj8q_R2VymB6ALEaE9I/edit?gid=0#gid=0
"""

from pathlib import Path

import polars as pl
import acore_eluna.tree_menu.api as tree_menu

dir_here = Path(__file__).absolute().parent
path_excel = dir_here.joinpath("buff-master-chat-command.xlsx")
df_menu = pl.read_excel(f"{path_excel}", sheet_name="Menu")
df_fact = pl.read_excel(f"{path_excel}", sheet_name="Fact")
df_menu = df_menu.join(
    df_fact.select(["id", "name"]),
    left_on="buff",
    right_on="name",
    how="left",
    coalesce=True,
).filter(pl.col("group").str.contains("Buff"))

rows = list()
for (group,), sub_df in df_menu.group_by(
    [
        "group",
    ],
    maintain_order=True,
):
    buff_list = sub_df.select(["id", "count"]).to_dicts()
    row = {
        "buff_list": buff_list,
        "_icon": None,
        "_h1": group,
    }
    rows.append(row)
df = pl.DataFrame(rows)


# --- Generate Lua Code
def data_to_lua_code(data: dict) -> str:
    """
    .. code-block::

        { id = 56525, count = 1 }, { id = 48161, count = 1 }, { id = 42995, count = 1 }, { id = 48073, count = 1 }, { id = 48469, count = 1 }
    """
    buff_list = data["buff_list"]
    parts = list()
    for row in buff_list:
        id = row["id"]
        count = row["count"]
        part = f"{{ id = {id}, count = {count} }}"
        parts.append(part)
    content = ", ".join(parts)
    return f"{{ {content} }}"


lua_code_generator = tree_menu.LuaCodeGenerator(
    id_start=373001,
    item_option_icon=tree_menu.IconEnum.GOSSIP_ICON_BATTLE,
    back_to_prev="返回 {parent_name}",
    back_to_top="返回 主菜单",
)
option_list = lua_code_generator.dataframe_to_option_list(df)
lua_code = lua_code_generator.generate_lua_code(option_list, data_to_lua_code)
path_lua = dir_here / "lua_code.lua"
path_lua.write_text(lua_code)
