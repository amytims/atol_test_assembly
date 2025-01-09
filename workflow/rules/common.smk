#!/usr/bin/env python3

import requests
import os
from functools import cache


configfile: "config/config.yaml"


globals().update(config)



def get_apikey():
    apikey = os.getenv("BPI_APIKEY")
    if not apikey:
        raise ValueError(
            "Set the BPI_APIKEY environment variable. "
            "This Snakefile uses a hack to pass the API key to `requests.get`. "
            "See  https://github.com/snakemake/snakemake-storage-plugin-http/issues/27."
        )
    return apikey


# @cache
def get_container(container_name):
    if container_name not in containers:
        raise ValueError(f"Container {container_name} not found in config.")
    my_container = containers[container_name]
    return (
        f"{my_container['prefix']}://"
        f"{my_container['url']}:"
        f"{my_container['tag']}"
    )


# This is a hack. Redefine requests.get to include the Authorization header.
# snakemake_storage_plugin_http only supports predifined AuthBase classes, see
# https://github.com/snakemake/snakemake-storage-plugin-http/issues/27
requests_get = requests.get


def requests_get_with_auth_header(url, **kwargs):
    if "headers" not in kwargs:
        kwargs["headers"] = {}
    kwargs["headers"]["Authorization"] = get_apikey()
    return requests_get(url, **kwargs)


requests.get = requests_get_with_auth_header
