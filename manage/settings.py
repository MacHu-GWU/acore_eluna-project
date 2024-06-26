# -*- coding: utf-8 -*-

from pathlib_mate import Path, PosixPath
from s3pathlib import S3Path
from boto_session_manager import BotoSesManager
from acore_paths.api import dir_server_lua_scripts as dir_remote_lua_scripts
from acore_eluna.api import sync_lua_scripts as _sync_lua_scripts
from acore_soap_app.api import run_soap_command

# ------------------------------------------------------------------------------
#
# ------------------------------------------------------------------------------
aws_profile = "bmt_app_dev_us_east_1"

bsm = BotoSesManager(profile_name=aws_profile)

dir_manage = Path.dir_here(__file__)
dir_local_lua_scripts = dir_manage.joinpath("workspace", "lua_scripts")
s3dir_tmp = S3Path(
    f"s3://{bsm.aws_account_alias}-{bsm.aws_region}-data"
    f"/projects/acore_eluna/tmp/lua_scripts/"
).to_dir()
path_remote_aws = PosixPath("/home/ubuntu/.pyenv/shims/aws")


def sync_lua_scripts(server_id: str, reload: bool = True):
    """
    :param server_id: ...
    :param refresh: If True, run ``reload eluna`` command after sync.
    """
    print("Sync lua script")
    _sync_lua_scripts(
        server_id=server_id,
        dir_local_lua_scripts=dir_local_lua_scripts,
        bsm=bsm,
        s3dir_tmp=s3dir_tmp,
    )
    if reload is True:
        print("Reload eluna script: it's OK to see error message")
        run_soap_command(
            bsm=bsm,
            server_id=server_id,
            request_like="reload eluna",
            sync=True,
        )
