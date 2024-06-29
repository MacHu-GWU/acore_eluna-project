# -*- coding: utf-8 -*-

"""
:class:`LuaCodeGenerator`.
"""

import typing as T
import enum
import dataclasses
import polars as pl


class IconEnum(enum.IntEnum):
    """
    下面是所有 ICON 代码的枚举. 你可以在 "OptionIcon" 一节中看到所有图标的说明.
    See: https://www.azerothcore.org/wiki/gossip_menu_option
    """

    GOSSIP_ICON_CHAT = 0  # White chat bubble
    GOSSIP_ICON_VENDOR = 1  # Brown bag
    GOSSIP_ICON_TAXI = 2  # Flight
    GOSSIP_ICON_TRAINER = 3  # Book
    GOSSIP_ICON_INTERACT_1 = 4  # Interaction wheel
    GOSSIP_ICON_INTERACT_2 = 5  # Interaction wheel
    GOSSIP_ICON_MONEY_BAG = 6  # Brown bag with yellow dot (gold)
    GOSSIP_ICON_TALK = 7  # White chat bubble with black dots (...)
    GOSSIP_ICON_TABARD = 8  # Tabard
    GOSSIP_ICON_BATTLE = 9  # Two swords
    GOSSIP_ICON_DOT = 10  # Yellow dot


class ItemType(T.TypedDict):
    id: int
    name: str
    is_menu: bool
    icon: int
    parent: T.Optional[int]
    data: T.Dict[str, T.Any]


class MenuType(T.TypedDict):
    id: int
    name: str
    is_menu: bool
    icon: int
    parent: T.Optional[int]


@dataclasses.dataclass
class LuaCodeGenerator:
    """ """

    id_start: int = dataclasses.field()
    item_icon: IconEnum = dataclasses.field()
    menu_icon: IconEnum = dataclasses.field()

    def make_item(
        self,
        row: T.Dict[str, T.Any],
        header: int,
        parent: T.Optional[int] = None,
    ) -> ItemType:
        """
        一个 item 就是一个 Gossip 中点击了就能产生业务逻辑的选项.
        """
        if row["_icon"] is None:
            icon = self.menu_icon.value
        else:  # pragma: no cover
            icon = row["_icon"]
        item = {
            "id": self.id_start,
            "name": row[f"_h{header}"],
            "is_menu": False,
            "icon": icon,
            "parent": parent,
        }
        self.id_start += 1
        for k in list(row):
            if k.startswith("_"):
                del row[k]
        item["data"] = row
        return item

    def make_menu(
        self,
        name: str,
        parent: T.Optional[int] = None,
    ) -> MenuType:
        """
        一个 menu 就是一个 Gossip 中点击了就进入下级菜单的选项.
        """
        menu = {
            "id": self.id_start,
            "name": name,
            "is_menu": True,
            "icon": self.menu_icon.value,
            "parent": parent,
        }
        self.id_start += 1
        return menu

    def _dataframe_to_menu_data(
        self,
        df: pl.DataFrame,
        _parent: T.Optional[int] = None,
        _header: int = 1,
        _items: T.Optional[T.List[T.Dict[str, T.Any]]] = None,
    ) -> T.List[T.Union[ItemType, MenuType]]:
        """
        输入一个 dataframe, 自动根据层级关系生成 gossip menu 中的 item 和 menu option,
        返回一个列表, 里面的每个元素都是一个按钮.

        这个函数用到了递归实现.

        :param df: see sample table
            https://docs.google.com/spreadsheets/d/1ZLNDemVn_5T1GbZZPd2igMCkPmEpZ1tR5U28nEkE41Y/edit?gid=0#gid=0
        """
        if _items is None:
            _items = list()
        if f"_h{_header + 1}" not in df.schema:
            for row in df.to_dicts():
                item = self.make_item(row, header=_header, parent=_parent)
                _items.append(item)
            return _items

        # 如果下级菜单 (下个 header) 没有数据, 那么这是一个 menu, 如果有数据, 那么这是一个 item
        df_menu = df.filter(pl.col(f"_h{_header + 1}").is_not_null())
        df_vendor = df.filter(pl.col(f"_h{_header + 1}").is_null())

        # 我们优先创建 menu
        for (name,), sub_df in df_menu.group_by([f"_h{_header}"], maintain_order=True):
            menu = self.make_menu(name=name, parent=_parent)
            _items.append(menu)

            self._dataframe_to_menu_data(
                df=sub_df,
                _parent=menu["id"],
                _header=_header + 1,
                _items=_items,
            )

        # 然后创建 item
        for row in df_vendor.to_dicts():
            item = self.make_item(row, header=_header, parent=_parent)
            _items.append(item)

        return _items

    def dataframe_to_menu_data(
        self,
        df: pl.DataFrame,
        _parent: T.Optional[int] = None,
        _header: int = 1,
        _items: T.Optional[T.List[T.Dict[str, T.Any]]] = None,
    ) -> T.List[T.Union[ItemType, MenuType]]:
        """
        输入一个 dataframe, 自动根据层级关系生成 gossip menu 中的 item 和 menu option,
        返回一个列表, 里面的每个元素都是一个按钮.

        这个函数用到了递归实现.

        :param df: see sample table
            https://docs.google.com/spreadsheets/d/1ZLNDemVn_5T1GbZZPd2igMCkPmEpZ1tR5U28nEkE41Y/edit?gid=0#gid=0
        """
        # validate input dataframe
        url = "https://docs.google.com/spreadsheets/d/1ZLNDemVn_5T1GbZZPd2igMCkPmEpZ1tR5U28nEkE41Y/edit?gid=0#gid=0"
        msg = f" See {url} for a good example."
        if "_icon" not in df.schema:  # pragma: no cover
            raise ValueError(
                f"The input dataframe must have a column named '_icon'.{msg}"
            )
        if "_h1" not in df.schema:  # pragma: no cover
            raise ValueError(
                f"The input dataframe must have a column named '_h1'.{msg}"
            )
        h_columns = [int(k[2:]) for k in df.schema if k.startswith("_h")]
        h_columns.sort()
        if all(df[f"_h{h_columns[-1]}"].is_null()):  # pragma: no cover
            raise ValueError(f"The last header column must NOT be ALL NULL.{msg}")
        columns = set(df.schema)
        columns.remove("_icon")
        columns = columns.difference([f"_h{col}" for col in h_columns])
        for col in columns:
            if col.startswith("_"):  # pragma: no cover
                raise ValueError(f"The data column name must NOT start with '_'.{msg}")

        return self._dataframe_to_menu_data(
            df=df,
            _parent=_parent,
            _header=_header,
            _items=_items,
        )

    def data_to_lua_code(self, data: T.Dict[str, T.Any]) -> str:  # pragma: no cover
        """
        这个方法能将你的 gossip menu option 中的核心业务数据转化成 lua 的源代码.
        因为我们无法预测用户的核心业务数据长什么样, 所以只能交给用户来自己实现.

        Example:

            >>> self.data_to_lua_code({"buff_id": 1, "buff_name": "王者祝福"})
            '{ buff_id = 1, buff_name = "王者祝福" }'
        """
        raise NotImplementedError(
            "You have to implement LuaCodeGenerator.data_to_lua_code(data) "
            "method to generate lua code!"
        )

    def generate_lua_code(
        self,
        menu_data_list: T.List[T.Union[ItemType, MenuType]],
    ) -> str:
        """
        根据 menu data 生成业务数据代码.

        例如如果 menu_data_list 长这个样子:

        .. code-block:: python

            [
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
                    "data": {"buff_id": 56525, "buff_count": 1}
                },
            ]

        那么生成的 lua 代码就是这个样子:

        .. code-block:: lua

            [1] = { id = 1, name = "牧师", is_menu = true, icon = 3, parent = nil },
            [2] = { id = 2, name = "真言术韧", is_menu = true, icon = 3, parent = 1 },
            [3] = { id = 3, name = "真言术韧 60", is_menu = false, icon = 3, parent = 2, data = { buff_id = 10938, buff_count = 1 } },
            [4] = { id = 4, name = "真言术韧 70", is_menu = false, icon = 3, parent = 2, data = { buff_id = 25389, buff_count = 1 } },
            [5] = { id = 5, name = "真言术韧 80", is_menu = false, icon = 3, parent = 2, data = { buff_id = 48161, buff_count = 1 } },
            [6] = { id = 6, name = "法师", is_menu = true, icon = 3, parent = nil },
            [7] = { id = 7, name = "奥术智慧", is_menu = true, icon = 3, parent = 6 },
            [8] = { id = 8, name = "奥术智慧 60", is_menu = false, icon = 3, parent = 7, data = { buff_id = 10157, buff_count = 1 } },
            [9] = { id = 9, name = "奥术智慧 70", is_menu = false, icon = 3, parent = 7, data = { buff_id = 27126, buff_count = 1 } },
            [10] = { id = 10, name = "奥术智慧 80", is_menu = false, icon = 3, parent = 7, data = { buff_id = 42995, buff_count = 1 } },
            [11] = { id = 11, name = "战斗", is_menu = true, icon = 3, parent = nil },
            [12] = { id = 12, name = "兽群领袖光环", is_menu = false, icon = 3, parent = 11, data = { buff_id = 24932, buff_count = 1 } },
            [13] = { id = 13, name = "枭兽光环", is_menu = false, icon = 3, parent = 11, data = { buff_id = 24907, buff_count = 1 } },
            [14] = { id = 14, name = "王者祝福", is_menu = false, icon = 3, parent = nil, data = { buff_id = 56525, buff_count = 1 } },
        """
        lines = list()
        tab = " " * 4
        for menu_data in menu_data_list:
            id = menu_data["id"]
            name = menu_data["name"]
            is_menu = "true" if menu_data["is_menu"] else "false"
            icon = menu_data["icon"]
            parent = menu_data["parent"]
            if parent is None:
                parent = "nil"
            if menu_data["is_menu"]:
                line = (
                    f"{tab}[{id}] = {{ "
                    f"id = {id}, "
                    f'name = "{name}", '
                    f"is_menu = {is_menu}, "
                    f"icon = {icon}, "
                    f"parent = {parent} "
                    f"}},"
                )
            else:
                data = self.data_to_lua_code(menu_data["data"])
                line = (
                    f"{tab}[{id}] = {{ "
                    f"id = {id}, "
                    f'name = "{name}", '
                    f"is_menu = {is_menu}, "
                    f"icon = {icon}, "
                    f"parent = {parent}, "
                    f"data = {data} "
                    f"}},"
                )
            lines.append(line)
        return "\n".join(lines)
