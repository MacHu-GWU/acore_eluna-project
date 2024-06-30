# -*- coding: utf-8 -*-

"""
这个脚本能生成最终的 cpi_multivendor.lua 文件.
"""

import dataclasses
from pathlib import Path

import jinja2
import polars as pl
import acore_eluna.tree_menu.api as tree_menu

df = pl.read_csv("cpi_multivendor_lua_data.tsv", separator="\t")


def data_to_lua_code(data: dict) -> str:
    npc_id = data["npc_id"]
    return f"{{ npc_id = {npc_id} }}"

lua_code_generator = tree_menu.LuaCodeGenerator(
    id_start=1,
    item_icon=tree_menu.IconEnum.GOSSIP_ICON_VENDOR,
    menu_icon=tree_menu.IconEnum.GOSSIP_ICON_CHAT,
)
menu_data_list = lua_code_generator.dataframe_to_menu_data(df)
lua_code = lua_code_generator.generate_lua_code(menu_data_list, data_to_lua_code)

dir_here = Path(__file__).absolute().parent
path_tpl = dir_here / "cpi_multivendor.lua.jinja2"
path_lua = dir_here / "cpi_multivendor.lua"
code = jinja2.Template(path_tpl.read_text()).render(lua_code=lua_code)
path_lua.write_text(code)
