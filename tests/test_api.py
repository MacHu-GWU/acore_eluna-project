# -*- coding: utf-8 -*-

from acore_eluna import api


def test():
    _ = api


if __name__ == "__main__":
    from acore_eluna.tests import run_cov_test

    run_cov_test(__file__, "acore_eluna.api", preview=False)
