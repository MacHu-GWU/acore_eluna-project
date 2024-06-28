# -*- coding: utf-8 -*-

"""
这个脚本能生成最终的 cpi_multivendor.lua 文件.
"""

from pathlib import Path
import jinja2
import polars as pl

df = pl.read_csv("cpi_multivendor_lua_data.tsv", separator="\t")

tab = " " * 4


def make_vendor(indent: int, name: str, id: int):
    lines.append(f'{indent * tab}{{name = "{name}", vendor_id = {id}}},')


def make_menu(indent: int, name: str):
    lines.append(f'{indent * tab}{{name = "{name}",')


def make_close_menu(indent: int):
    lines.append(f"{indent * tab}}},")


lines = list()
lines.append("CpiMultiVendor.VENDOR_DATA_LIST = {")

df_menu = df.filter(pl.col("h2").is_not_null())
df_vendor = df.filter(pl.col("h2").is_null())

for (h1,), sub_df_1 in df_menu.group_by(["h1"], maintain_order=True):
    make_menu(indent=1, name=h1)

    sub_df_1_menu = sub_df_1.filter(pl.col("h3").is_not_null())
    sub_df_1_vendor = sub_df_1.filter(pl.col("h3").is_null())

    for (h2,), sub_df_2 in sub_df_1_menu.group_by(["h2"], maintain_order=True):
        make_menu(indent=2, name=h2)

        sub_df_2_menu = sub_df_2.filter(pl.col("h4").is_not_null())
        sub_df_2_vendor = sub_df_2.filter(pl.col("h4").is_null())

        for (h3,), sub_df_3 in sub_df_2_menu.group_by(["h3"], maintain_order=True):
            make_menu(indent=3, name=h3)

            sub_df_3_vendor = sub_df_3

            for row in sub_df_3_vendor.to_dicts():
                make_vendor(indent=4, name=row["h4"], id=row["npc_id"])

            make_close_menu(indent=3)

        for row in sub_df_2_vendor.to_dicts():
            make_vendor(indent=3, name=row["h3"], id=row["npc_id"])

        make_close_menu(indent=2)

    for row in sub_df_1_vendor.to_dicts():
        make_vendor(indent=2, name=row["h2"], id=row["npc_id"])

    make_close_menu(indent=1)

for row in df_vendor.to_dicts():
    make_vendor(indent=1, name=row["h1"], id=row["npc_id"])

lines.append("}")

VENDOR_DATA_LIST_CODE = "\n".join(lines)

dir_here = Path(__file__).absolute().parent
path_tpl = dir_here / "cpi_multivendor.lua.jinja2"
path_lua = dir_here / "cpi_multivendor.lua"
code = jinja2.Template(path_tpl.read_text()).render(
    VENDOR_DATA_LIST_CODE=VENDOR_DATA_LIST_CODE
)
path_lua.write_text(code)
