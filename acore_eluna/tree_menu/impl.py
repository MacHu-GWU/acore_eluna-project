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


class OptionTypeEnum(str, enum.Enum):
    """
    表示一个 Gossip 中可点击的选项.
    """

    ITEM = "item"
    MENU = "menu"
    BACK = "back"


OptionTypeName = T.Literal[
    OptionTypeEnum.ITEM.value,
    OptionTypeEnum.MENU.value,
    OptionTypeEnum.BACK.value,
]


class ItemOptionType(T.TypedDict):
    """
    表示一个 Gossip 中点击了就能产生业务逻辑的选项.
    """

    id: int
    name: str
    type: OptionTypeName
    icon: int
    parent: int
    data: T.Dict[str, T.Any]


class MenuOptionType(T.TypedDict):
    """
    表示一个 Gossip 中点击了就进入下级菜单的选项.
    """

    id: int
    name: str
    type: OptionTypeName
    icon: int
    parent: int


class BackOptionType(T.TypedDict):
    """
    表示一个 Gossip 中点击了就进入回到上一级或者主菜单的选项.
    """

    id: int
    name: str
    type: OptionTypeName
    icon: int
    parent: int
    back_to: int


OptionType = T.Union[ItemOptionType, MenuOptionType]


ROOT_PARENT_ID = 0


@dataclasses.dataclass
class LuaCodeGenerator:
    """
    这个类能帮助你将一个在 Google sheet 中定义的 dataframe 转化成 Lua 中所需要的
    gossip menu 的数据.

    :param id_start: The starting id for the menu item. If the value is 1,
        then your menu id will be 1, 2, 3, .... If you have multiple gossip
        menus, you have to ensure their id does not overlap.
    :param item_option_icon: The icon for the item. If the ``_icon`` field in the
        data frame is None, then this icon will be used.
    :param menu_option_icon: The icon for the menu. If the ``_icon`` field in the
        data frame is None, then this icon will be used.
    """

    id_start: int = dataclasses.field()
    item_option_icon: IconEnum = dataclasses.field(default=IconEnum.GOSSIP_ICON_CHAT)
    menu_option_icon: IconEnum = dataclasses.field(default=IconEnum.GOSSIP_ICON_CHAT)
    back_option_icon: IconEnum = dataclasses.field(default=IconEnum.GOSSIP_ICON_TALK)
    back_to_prev: str = dataclasses.field(default="Back to {parent_name}")
    back_to_top: str = dataclasses.field(default="Back to Top")

    def __post_init__(self):
        if self.id_start < 1:
            raise ValueError("The id_start must be greater than 0.")

    def make_item_option(
        self,
        row: T.Dict[str, T.Any],
        header: int,
        parent: int = ROOT_PARENT_ID,
    ) -> ItemOptionType:
        """
        一个 item option 就是一个 Gossip 中点击了就能产生业务逻辑的选项.
        """
        if row["_icon"] is None:
            icon = self.item_option_icon.value
        else:  # pragma: no cover
            icon = row["_icon"]
        item_option = {
            "id": self.id_start,
            "name": row[f"_h{header}"],
            "type": OptionTypeEnum.ITEM.value,
            "icon": icon,
            "parent": parent,
        }
        self.id_start += 1
        for k in list(row):
            if k.startswith("_"):
                del row[k]
        item_option["data"] = row
        return item_option

    def make_menu_option(
        self,
        name: str,
        parent: int = ROOT_PARENT_ID,
    ) -> MenuOptionType:
        """
        一个 menu option 就是一个 Gossip 中点击了就进入下级菜单的选项.
        """
        menu_option = {
            "id": self.id_start,
            "name": name,
            "type": OptionTypeEnum.MENU.value,
            "icon": self.menu_option_icon.value,
            "parent": parent,
        }
        self.id_start += 1
        return menu_option

    def make_back_option(
        self,
        name: str,
        parent: int = ROOT_PARENT_ID,
        back_to: int = ROOT_PARENT_ID,
    ) -> BackOptionType:
        """
        一个 back option 就是一个 Gossip 中点击了就进入回到上一级或者主菜单的选项.
        """
        back_option = {
            "id": self.id_start,
            "name": name,
            "type": OptionTypeEnum.BACK.value,
            "icon": self.back_option_icon.value,
            "parent": parent,
            "back_to": back_to,
        }
        self.id_start += 1
        return back_option

    def _dataframe_to_menu_data(
        self,
        df: pl.DataFrame,
        _parent: T.Optional[int] = None,
        _parent_name: T.Optional[str] = None,
        _header: int = 1,
        _items: T.Optional[T.List[T.Dict[str, T.Any]]] = None,
    ) -> T.List[OptionType]:
        """
        输入一个 dataframe, 自动根据层级关系生成 gossip menu 中的 option,
        返回一个列表, 里面的每个元素都是一个按钮.

        这个函数用到了递归实现.

        :param df: see sample table
            https://docs.google.com/spreadsheets/d/1ZLNDemVn_5T1GbZZPd2igMCkPmEpZ1tR5U28nEkE41Y/edit?gid=0#gid=0
        """
        if _items is None:
            _items = list()
        if f"_h{_header + 1}" not in df.schema:
            for row in df.to_dicts():
                item = self.make_item_option(row, header=_header, parent=_parent)
                _items.append(item)
            if _parent is not None:
                _items.extend(
                    [
                        self.make_back_option(
                            name=self.back_to_prev.format(parent_name=_parent_name),
                            parent=_parent,
                            back_to=_parent,
                        ),
                        self.make_back_option(
                            name=self.back_to_top,
                            parent=_parent,
                            back_to=ROOT_PARENT_ID,
                        ),
                    ]
                )
            return _items

        # 如果下级菜单 (下个 header) 没有数据, 那么这是一个 menu, 如果有数据, 那么这是一个 item
        df_menu = df.filter(pl.col(f"_h{_header + 1}").is_not_null())
        df_vendor = df.filter(pl.col(f"_h{_header + 1}").is_null())

        # 我们优先创建 menu
        for (name,), sub_df in df_menu.group_by([f"_h{_header}"], maintain_order=True):
            menu = self.make_menu_option(name=name, parent=_parent)
            _items.append(menu)
            self._dataframe_to_menu_data(
                df=sub_df,
                _parent=menu["id"],
                _parent_name=menu["name"],
                _header=_header + 1,
                _items=_items,
            )

        # 然后创建 item
        for row in df_vendor.to_dicts():
            item = self.make_item_option(row, header=_header, parent=_parent)
            _items.append(item)

        if _parent is not None:
            _items.extend(
                [
                    self.make_back_option(
                        name=self.back_to_prev.format(parent_name=_parent_name),
                        parent=_parent,
                        back_to=_parent,
                    ),
                    self.make_back_option(
                        name="Back to Top",
                        parent=_parent,
                        back_to=ROOT_PARENT_ID,
                    ),
                ]
            )

        return _items

    def dataframe_to_option_list(
        self,
        df: pl.DataFrame,
        _parent: int = ROOT_PARENT_ID,
        _header: int = 1,
        _items: T.Optional[T.List[T.Dict[str, T.Any]]] = None,
    ) -> T.List[OptionType]:
        """
        输入一个 dataframe, 自动根据层级关系生成 gossip menu 中的 option 列表.
        里面的每个元素都是一个按钮.

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

    def generate_lua_code(
        self,
        option_list: T.List[OptionType],
        data_to_lua_code: T.Callable[[T.Dict[str, T.Any]], str],
    ) -> str:
        """
        根据 option list 生成业务数据代码.

        例如如果 ``option_list`` 长这个样子:

        .. code-block:: python

            [
                {'id': 1001, 'name': '牧师', 'type': 'menu', 'icon': 3, 'parent': 0},
                {
                    'id': 1002,
                    'name': '真言术韧',
                    'type': 'menu',
                    'icon': 3,
                    'parent': 1001
                },
                {
                    'id': 1003,
                    'name': '真言术韧 60',
                    'type': 'item',
                    'icon': 9,
                    'parent': 1002,
                    'data': {'buff_id': 10938, 'buff_count': 1}
                },
                {
                    'id': 1004,
                    'name': '真言术韧 70',
                    'type': 'item',
                    'icon': 9,
                    'parent': 1002,
                    'data': {'buff_id': 25389, 'buff_count': 1}
                },
                {
                    'id': 1005,
                    'name': '真言术韧 80',
                    'type': 'item',
                    'icon': 9,
                    'parent': 1002,
                    'data': {'buff_id': 48161, 'buff_count': 1}
                },
                {
                    'id': 1006,
                    'name': 'Back to 真言术韧',
                    'type': 'back',
                    'icon': 7,
                    'parent': 1002,
                    'back_to': 1002
                },
                {
                    'id': 1007,
                    'name': 'Back to Top',
                    'type': 'back',
                    'icon': 7,
                    'parent': 1002,
                    'back_to': 0
                },
                {
                    'id': 1008,
                    'name': '反恐惧结界',
                    'type': 'item',
                    'icon': 9,
                    'parent': 1001,
                    'data': {'buff_id': 6346, 'buff_count': 1}
                },
                {
                    'id': 1009,
                    'name': '能量灌注',
                    'type': 'item',
                    'icon': 9,
                    'parent': 1001,
                    'data': {'buff_id': 10060, 'buff_count': 1}
                },
                {
                    'id': 1010,
                    'name': 'Back to 牧师',
                    'type': 'back',
                    'icon': 7,
                    'parent': 1001,
                    'back_to': 1001
                },
                {
                    'id': 1011,
                    'name': 'Back to Top',
                    'type': 'back',
                    'icon': 7,
                    'parent': 1001,
                    'back_to': 0
                },
                {
                    'id': 1012,
                    'name': '王者祝福',
                    'type': 'item',
                    'icon': 9,
                    'parent': 0,
                    'data': {'buff_id': 56525, 'buff_count': 1}
                },
                {
                    'id': 1013,
                    'name': 'Back to None',
                    'type': 'back',
                    'icon': 7,
                    'parent': 0,
                    'back_to': 0
                },
                {
                    'id': 1014,
                    'name': 'Back to Top',
                    'type': 'back',
                    'icon': 7,
                    'parent': 0,
                    'back_to': 0
                }
            ]

        那么生成的 lua 代码就是这个样子:

        .. code-block:: lua

            { id = 1001, name = "牧师", type = "menu", icon = 3, parent = 0 },
            { id = 1002, name = "真言术韧", type = "menu", icon = 3, parent = 1001 },
            { id = 1003, name = "真言术韧 60", type = "item", icon = 9, parent = 1002, data = { buff_id = 10938, buff_count = 1 } },
            { id = 1004, name = "真言术韧 70", type = "item", icon = 9, parent = 1002, data = { buff_id = 25389, buff_count = 1 } },
            { id = 1005, name = "真言术韧 80", type = "item", icon = 9, parent = 1002, data = { buff_id = 48161, buff_count = 1 } },
            { id = 1006, name = "Back to 真言术韧", type = "back", icon = 7, parent = 1002, back_to = 1002 },
            { id = 1007, name = "Back to Top", type = "back", icon = 7, parent = 1002, back_to = 0 },
            { id = 1008, name = "反恐惧结界", type = "item", icon = 9, parent = 1001, data = { buff_id = 6346, buff_count = 1 } },
            { id = 1009, name = "能量灌注", type = "item", icon = 9, parent = 1001, data = { buff_id = 10060, buff_count = 1 } },
            { id = 1010, name = "Back to 牧师", type = "back", icon = 7, parent = 1001, back_to = 1001 },
            { id = 1011, name = "Back to Top", type = "back", icon = 7, parent = 1001, back_to = 0 },
            { id = 1012, name = "王者祝福", type = "item", icon = 9, parent = 0, data = { buff_id = 56525, buff_count = 1 } },
            { id = 1013, name = "Back to None", type = "back", icon = 7, parent = 0, back_to = 0 },
            { id = 1014, name = "Back to Top", type = "back", icon = 7, parent = 0, back_to = 0 },

        ``data_to_lua_code`` 参数是一个函数, 用来将你的核心业务数据转化成 lua 的源代码.
        也就是上面例子中把 ``{"buff_id": 42995, "buff_count": 1}`` 转化成
        ``{ buff_id = 42995, buff_count = 1 }``.
        因为我们无法预测用户的核心业务数据长什么样, 所以只能交给用户来自己实现.
        """
        lines = list()
        tab = " " * 4
        for option in option_list:
            id = option["id"]
            name = option["name"]
            type = option["type"]
            icon = option["icon"]
            parent = option["parent"]
            if type == OptionTypeEnum.ITEM.value:
                data = data_to_lua_code(option["data"])
                line = (
                    f"{tab}{{ "
                    f"id = {id}, "
                    f'name = "{name}", '
                    f'type = "{type}", '
                    f"icon = {icon}, "
                    f"parent = {parent}, "
                    f"data = {data} "
                    f"}},"
                )
            elif type == OptionTypeEnum.MENU.value:
                line = (
                    f"{tab}{{ "
                    f"id = {id}, "
                    f'name = "{name}", '
                    f'type = "{type}", '
                    f"icon = {icon}, "
                    f"parent = {parent} "
                    f"}},"
                )
            elif type == OptionTypeEnum.BACK.value:
                back_to = option["back_to"]
                line = (
                    f"{tab}{{ "
                    f"id = {id}, "
                    f'name = "{name}", '
                    f'type = "{type}", '
                    f"icon = {icon}, "
                    f"parent = {parent}, "
                    f"back_to = {back_to} "
                    f"}},"
                )
            else:  # pragma: no cover
                raise TypeError(f"Unknown type {type!r}")
            lines.append(line)
        return "\n".join(lines)
