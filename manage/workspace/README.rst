About ``workspace`` Folder
==============================================================================
这个目录是 lua 脚本的开发目录.

- dev: 临时的开发脚本都在这个目录下进行. 这个目录下的文件不会进入到 Git.
- stage: 开发完成, 需要进入到 Git 但不在服务器上启用的脚本放在这里.
- lua_scripts: 在服务器上启用的脚本放在这里.


- `Azerothcore Eluna GitHub <https://github.com/azerothcore/mod-eluna>`_: Eluna 项目 GitHub 官网.
- `AzerothCore Eluna API Document <https://www.azerothcore.org/pages/eluna/>`_: Eluna 项目官方 API 文档.
- `Hooks Reference <https://github.com/ElunaLuaEngine/Eluna/blob/master/hooks/Hooks.h>`_: 所有触发器事件的列表.
- `Global Methods <https://www.azerothcore.org/pages/eluna/Global/index.html>`_: 全局方法的列表, 包含了用于注册所有触发器事件的函数名和文档.
- `Example Scripts <https://github.com/ElunaLuaEngine/Scripts>`_: 一些用 Eluna 实现的具体例子.




Code Style

- 所有函数名称和方法名称都是首字母大写的 camel case. 这是为了跟 elunaengine 的风格保持一致,
    see: https://www.azerothcore.org/pages/eluna/Player/index.html
- 所有的常数变量都是全大写, 用下划线分隔单词.
- 所有的函数的参数都是首字母小写的 camel case. 这也是为了跟 elunaengine 的风格保持一致,
    see: https://www.azerothcore.org/pages/eluna/Player/AddItem.html
--]]