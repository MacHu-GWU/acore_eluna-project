# -*- coding: utf-8 -*-

"""

"""

from acore_server.api import Server
from acore_server_bootstrap.api import Remoter
from acore_eluna.tests.my_syncer import my_syncer

server_id = "sbx-black"

bsm = my_syncer.bsm
my_syncer.sync(server_id=server_id, reload=True)

# server = Server.get(bsm=bsm, server_id=server_id)
# remoter = Remoter(ssm_client=bsm.ssm_client, server=server)
# remoter.apply_mod_lua_engine_conf()
# remoter.run_server()
# remoter.list_session()
# remoter.stop_server()
