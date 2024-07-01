# -*- coding: utf-8 -*-

from acore_eluna.tree_menu import api


def test():
    _ = api.IconEnum
    _ = api.ItemOptionType
    _ = api.MenuOptionType
    _ = api.LuaCodeGenerator


if __name__ == "__main__":
    from acore_eluna.tests import run_cov_test

    run_cov_test(__file__, "acore_eluna.tree_menu.api", preview=False)
