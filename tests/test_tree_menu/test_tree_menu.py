# -*- coding: utf-8 -*-

import typing as T

import polars as pl
from pathlib import Path
from acore_eluna.tree_menu.impl import IconEnum, LuaCodeGenerator, ROOT_PARENT_ID


def data_to_lua_code(data: T.Dict[str, T.Any]) -> str:
    buff_id = data["buff_id"]
    buff_count = data["buff_count"]
    return f"{{ buff_id = {buff_id}, buff_count = {buff_count} }}"


def test_lua_code_generator():
    lua_code_generator = LuaCodeGenerator(
        id_start=1001,
        item_option_icon=IconEnum.GOSSIP_ICON_BATTLE,
        menu_option_icon=IconEnum.GOSSIP_ICON_TRAINER,
    )
    df = pl.read_csv(
        Path(__file__).absolute().parent.joinpath("test_data.tsv"),
        separator="\t",
    )

    menu_data_list = lua_code_generator.dataframe_to_menu_data(df)
    # from rich import print as rprint  # for debug only
    # rprint(menu_data_list)  # for debug only
    assert menu_data_list == [
        {"id": 1001, "name": "牧师", "is_menu": True, "icon": 3, "parent": 0},
        {"id": 1002, "name": "真言术韧", "is_menu": True, "icon": 3, "parent": 1001},
        {
            "id": 1003,
            "name": "真言术韧 60",
            "is_menu": False,
            "icon": 9,
            "parent": 1002,
            "data": {"buff_id": 10938, "buff_count": 1},
        },
        {
            "id": 1004,
            "name": "真言术韧 70",
            "is_menu": False,
            "icon": 9,
            "parent": 1002,
            "data": {"buff_id": 25389, "buff_count": 1},
        },
        {
            "id": 1005,
            "name": "真言术韧 80",
            "is_menu": False,
            "icon": 9,
            "parent": 1002,
            "data": {"buff_id": 48161, "buff_count": 1},
        },
        {
            "id": 1006,
            "name": "Back to 真言术韧",
            "is_menu": True,
            "icon": 7,
            "parent": 1002,
            "back_to": 1002,
        },
        {
            "id": 1007,
            "name": "Back to Top",
            "is_menu": True,
            "icon": 7,
            "parent": 1002,
            "back_to": 0,
        },
        {
            "id": 1008,
            "name": "反恐惧结界",
            "is_menu": False,
            "icon": 9,
            "parent": 1001,
            "data": {"buff_id": 6346, "buff_count": 1},
        },
        {
            "id": 1009,
            "name": "能量灌注",
            "is_menu": False,
            "icon": 9,
            "parent": 1001,
            "data": {"buff_id": 10060, "buff_count": 1},
        },
        {
            "id": 1010,
            "name": "Back to 牧师",
            "is_menu": True,
            "icon": 7,
            "parent": 1001,
            "back_to": 1001,
        },
        {
            "id": 1011,
            "name": "Back to Top",
            "is_menu": True,
            "icon": 7,
            "parent": 1001,
            "back_to": 0,
        },
        {
            "id": 1012,
            "name": "王者祝福",
            "is_menu": False,
            "icon": 9,
            "parent": 0,
            "data": {"buff_id": 56525, "buff_count": 1},
        },
        {
            "id": 1013,
            "name": "Back to None",
            "is_menu": True,
            "icon": 7,
            "parent": 0,
            "back_to": 0,
        },
        {
            "id": 1014,
            "name": "Back to Top",
            "is_menu": True,
            "icon": 7,
            "parent": 0,
            "back_to": 0,
        },
    ]
    lua_code = lua_code_generator.generate_lua_code(
        menu_data_list=menu_data_list,
        data_to_lua_code=data_to_lua_code,
    )
    # print("\n" + lua_code)  # for debug only


if __name__ == "__main__":
    from acore_eluna.tests import run_cov_test

    run_cov_test(__file__, "acore_eluna.tree_menu", preview=False)
