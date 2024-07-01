# -*- coding: utf-8 -*-

import typing as T

from pathlib_mate import Path
from s3pathlib import S3Path
from boto_session_manager import BotoSesManager

from acore_paths.api import path_acore_server_bootstrap_cli
from acore_server.api import Server
import aws_ssm_run_command.api as aws_ssm_run_command
from acore_soap_app.api import run_soap_command

from .paths import dir_local_lua_scripts


def sync_lua_scripts(
    server_id: str,
    dir_local_lua_scripts: Path,
    bsm: BotoSesManager,
    s3dir_tmp: T.Optional[S3Path] = None,
):
    if s3dir_tmp is None:
        bucket = f"{bsm.aws_account_alias}-{bsm.aws_region}-data"
        key = "projects/acore_eluna/tmp/lua_scripts/"
        s3dir_tmp = S3Path(f"s3://{bucket}/{key}").to_dir()
    s3dir_tmp.delete(bsm=bsm)
    server = Server.get(bsm=bsm, server_id=server_id)

    for path_local_lua in dir_local_lua_scripts.select_by_ext(ext=".lua"):
        relpath = path_local_lua.relative_to(dir_local_lua_scripts)
        s3path = s3dir_tmp.joinpath(*relpath.parts)
        s3path.write_text(path_local_lua.read_text(), bsm=bsm)

    command = f"{path_acore_server_bootstrap_cli} sync_lua_scripts --s3dir_uri {s3dir_tmp.uri}"
    final_command = f"sudo -H -u ubuntu {command}"
    aws_ssm_run_command.better_boto.run_shell_script_sync(
        ssm_client=bsm.ssm_client,
        instance_ids=server.metadata.ec2_inst.id,
        commands=final_command,
        delays=1,
    )


def sync_lua_script_for_bmt_app_dev_us_east_1(
    server_id: str,
    reload: bool = True,
):
    aws_profile = "bmt_app_dev_us_east_1"
    bsm = BotoSesManager(profile_name=aws_profile)

    s3dir_tmp = S3Path(
        f"s3://{bsm.aws_account_alias}-{bsm.aws_region}-data"
        f"/projects/acore_eluna/tmp/lua_scripts/"
    ).to_dir()
    print("Sync lua scripts to EC2")
    sync_lua_scripts(
        server_id=server_id,
        dir_local_lua_scripts=Path(dir_local_lua_scripts),
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
