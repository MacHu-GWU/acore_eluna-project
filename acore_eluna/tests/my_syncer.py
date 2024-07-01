# -*- coding: utf-8 -*-

import typing as T
import dataclasses
from pathlib_mate import Path
from s3pathlib import S3Path
from boto_session_manager import BotoSesManager

from acore_soap_app.api import run_soap_command

from ..paths import dir_local_lua_scripts
from ..sync_lua_scripts import sync_lua_scripts


@dataclasses.dataclass
class MySyncer:
    aws_profile: str = dataclasses.field()
    bsm: BotoSesManager = dataclasses.field(init=False)
    s3dir_tmp: T.Optional[S3Path] = dataclasses.field(init=False)

    def __post_init__(self):
        self.bsm = BotoSesManager(profile_name=self.aws_profile)
        self.s3dir_tmp = S3Path(
            f"s3://{self.bsm.aws_account_alias}-{self.bsm.aws_region}-data"
            f"/projects/acore_eluna/tmp/lua_scripts/"
        ).to_dir()

    def sync(
        self,
        server_id: str,
        reload: bool = True,
    ):
        print("--- Sync lua scripts to EC2 ...")
        sync_lua_scripts(
            server_id=server_id,
            dir_local_lua_scripts=Path(dir_local_lua_scripts),
            bsm=self.bsm,
            s3dir_tmp=self.s3dir_tmp,
        )
        if reload is True:
            print("--- Reload eluna script ...")
            run_soap_command(
                bsm=self.bsm,
                server_id=server_id,
                request_like="reload eluna",
                sync=True,
            )
        print("Done.")


my_syncer = MySyncer(aws_profile="bmt_app_dev_us_east_1")
