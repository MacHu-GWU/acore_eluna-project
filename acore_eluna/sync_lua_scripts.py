# -*- coding: utf-8 -*-

import typing as T

from pathlib_mate import Path
from s3pathlib import S3Path
from boto_session_manager import BotoSesManager
import aws_ssm_run_command.api as aws_ssm_run_command

from acore_server.api import Server
from acore_paths.api import path_acore_server_bootstrap_cli


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
