# -*- coding: utf-8 -*-

"""
sudo /home/ubuntu/.pyenv/shims/python3.11 -c "$(curl -fsSL https://raw.githubusercontent.com/MacHu-GWU/acore_server_bootstrap-project/main/install.py)" --acore_server_bootstrap_version 1.0.1 --acore_soap_app_version 0.3.6 --acore_db_app_version 0.2.3
"""

from acore_server.api import Server
from acore_server_bootstrap.api import Remoter
from acore_soap_app.api import run_soap_command
from settings import bsm, sync_lua_scripts

server_id = "sbx-black"
server = Server.get(bsm=bsm, server_id=server_id)
remoter = Remoter(ssm_client=bsm.ssm_client, server=server)

sync_lua_scripts(server_id=server_id, reload=True)
# remoter.apply_mod_lua_engine_conf()
# remoter.run_server()
# remoter.list_session()
# remoter.stop_server()
