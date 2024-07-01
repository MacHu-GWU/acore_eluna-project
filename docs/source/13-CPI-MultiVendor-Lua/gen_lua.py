# -*- coding: utf-8 -*-

"""
Google Sheet: https://docs.google.com/spreadsheets/d/1e4I2-d4JyVbsvOcdePruqev-rkyYYMUPrwkI_fieIYw/edit?gid=1169636448#gid=1169636448
"""

from pathlib import Path

import jinja2
import polars as pl
import acore_eluna.tree_menu.api as tree_menu

from acore_eluna.sync_lua_scripts import sync_lua_script_for_bmt_app_dev_us_east_1
from acore_eluna.paths import dir_local_lua_scripts

df = pl.read_csv("cpi_multivendor_lua_data.tsv", separator="\t")


# --- Generate Lua Code
def data_to_lua_code(data: dict) -> str:
    npc_id = data["npc_id"]
    return f"{{ npc_id = {npc_id} }}"


lua_code_generator = tree_menu.LuaCodeGenerator(
    id_start=374001,
    item_option_icon=tree_menu.IconEnum.GOSSIP_ICON_VENDOR,
    back_to_prev="返回 {parent_name}",
    back_to_top="返回 主菜单",
)
option_list = lua_code_generator.dataframe_to_option_list(df)
lua_code = lua_code_generator.generate_lua_code(option_list, data_to_lua_code)
dir_here = Path(__file__).absolute().parent
path_lua = dir_here / "lua_code.lua"
path_lua.write_text(lua_code)
