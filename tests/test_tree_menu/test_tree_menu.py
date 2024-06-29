# -*- coding: utf-8 -*-

import dataclasses
import typing as T

import polars as pl
from pathlib import Path
from acore_eluna.tree_menu.impl import IconEnum, LuaCodeGenerator


@dataclasses.dataclass
class MyLuaCodeGenerator(LuaCodeGenerator):
    def data_to_lua_code(self, data: T.Dict[str, T.Any]) -> str:
        buff_id = data["buff_id"]
        buff_count = data["buff_count"]
        return f"{{ buff_id = {buff_id}, buff_count = {buff_count} }}"


def test_lua_code_generator():
    lua_code_generator = MyLuaCodeGenerator(
        id_start=1,
        item_icon=IconEnum.GOSSIP_ICON_BATTLE,
        menu_icon=IconEnum.GOSSIP_ICON_TRAINER,
    )
    df = pl.read_csv(
        Path(__file__).absolute().parent.joinpath("test_data.tsv"),
        separator="\t",
    )
    from rich import print as rprint

    menu_data_list = lua_code_generator.dataframe_to_menu_data(df)
    # rprint(menu_data_list)
    assert menu_data_list == [
        {"id": 1, "name": "牧师", "is_menu": True, "icon": 3, "parent": None},
        {"id": 2, "name": "真言术韧", "is_menu": True, "icon": 3, "parent": 1},
        {
            "id": 3,
            "name": "真言术韧 60",
            "is_menu": False,
            "icon": 3,
            "parent": 2,
            "data": {"buff_id": 10938, "buff_count": 1},
        },
        {
            "id": 4,
            "name": "真言术韧 70",
            "is_menu": False,
            "icon": 3,
            "parent": 2,
            "data": {"buff_id": 25389, "buff_count": 1},
        },
        {
            "id": 5,
            "name": "真言术韧 80",
            "is_menu": False,
            "icon": 3,
            "parent": 2,
            "data": {"buff_id": 48161, "buff_count": 1},
        },
        {"id": 6, "name": "法师", "is_menu": True, "icon": 3, "parent": None},
        {"id": 7, "name": "奥术智慧", "is_menu": True, "icon": 3, "parent": 6},
        {
            "id": 8,
            "name": "奥术智慧 60",
            "is_menu": False,
            "icon": 3,
            "parent": 7,
            "data": {"buff_id": 10157, "buff_count": 1},
        },
        {
            "id": 9,
            "name": "奥术智慧 70",
            "is_menu": False,
            "icon": 3,
            "parent": 7,
            "data": {"buff_id": 27126, "buff_count": 1},
        },
        {
            "id": 10,
            "name": "奥术智慧 80",
            "is_menu": False,
            "icon": 3,
            "parent": 7,
            "data": {"buff_id": 42995, "buff_count": 1},
        },
        {"id": 11, "name": "战斗", "is_menu": True, "icon": 3, "parent": None},
        {
            "id": 12,
            "name": "兽群领袖光环",
            "is_menu": False,
            "icon": 3,
            "parent": 11,
            "data": {"buff_id": 24932, "buff_count": 1},
        },
        {
            "id": 13,
            "name": "枭兽光环",
            "is_menu": False,
            "icon": 3,
            "parent": 11,
            "data": {"buff_id": 24907, "buff_count": 1},
        },
        {
            "id": 14,
            "name": "王者祝福",
            "is_menu": False,
            "icon": 3,
            "parent": None,
            "data": {"buff_id": 56525, "buff_count": 1},
        },
    ]
    lua_code = lua_code_generator.generate_lua_code(menu_data_list)
    print(lua_code)


if __name__ == "__main__":
    from acore_eluna.tests import run_cov_test

    run_cov_test(__file__, "acore_eluna.tree_menu", preview=False)
