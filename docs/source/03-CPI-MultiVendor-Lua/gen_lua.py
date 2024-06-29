# -*- coding: utf-8 -*-

"""
这个脚本能生成最终的 cpi_multivendor.lua 文件.
"""

from pathlib import Path
import jinja2
import polars as pl

df = pl.read_csv("cpi_multivendor_lua_data.tsv", separator="\t")

tab = " " * 4


def make_item(indent: int, name: str, row: dict):
    """
    Make a line to present a non-menu Gossip item.
    """
    id = row["npc_id"]
    lines.append(f'{indent * tab}{{name = "{name}", vendor_id = {id}}},')


def make_menu(indent: int, name: str):
    """
    Make a line to present a menu Gossip item.
    """
    lines.append(f'{indent * tab}{{name = "{name}",')


def make_close_menu(indent: int):
    """
    Make a line to close a menu Gossip item. Which is just a ``},``.
    """
    lines.append(f"{indent * tab}}},")


lines = list()
lines.append("CpiMultiVendor.VENDOR_DATA_LIST = {")


def generate_lines(
    df: pl.DataFrame,
    indent: int = 1,
    header: int = 1,
):
    """
    这是一个递归算法. 递归地生成 cpi_multivendor.lua 文件的内容.
    """
    if f"h{header+1}" not in df.schema:
        for row in df.to_dicts():
            make_item(indent=header, name=row[f"h{header}"], row=row)
        return

    df_menu = df.filter(pl.col(f"h{header+1}").is_not_null())
    df_vendor = df.filter(pl.col(f"h{header+1}").is_null())

    for (h,), sub_df in df_menu.group_by([f"h{header}"], maintain_order=True):
        make_menu(indent=indent, name=h)

        generate_lines(sub_df, indent=indent + 1, header=header + 1)

        make_close_menu(indent=indent)

    for row in df_vendor.to_dicts():
        make_item(indent=header, name=row[f"h{header}"], row=row)


generate_lines(df)


lines.append("}")

VENDOR_DATA_LIST_CODE = "\n".join(lines)

dir_here = Path(__file__).absolute().parent
path_tpl = dir_here / "cpi_multivendor.lua.jinja2"
path_lua = dir_here / "cpi_multivendor.lua"
code = jinja2.Template(path_tpl.read_text()).render(
    VENDOR_DATA_LIST_CODE=VENDOR_DATA_LIST_CODE
)
path_lua.write_text(code)
