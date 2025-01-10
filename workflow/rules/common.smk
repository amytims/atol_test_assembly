#!/usr/bin/env python3

import requests
import os
from functools import cache


configfile: "config/config.yaml"


globals().update(config)


def add_bucket_to_path(path):
    if not isinstance(path, Path):
        raise ValueError("path must be a Path object")
    else:
        path_string = str(path.as_posix())
        output_path = storage.s3(f"{output_bucket}/{path_string}")
        return output_path


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


def get_url(wildcards):
    my_url = data_file_dict[wildcards.readfile]
    return storage.http(my_url)


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


rule download_from_bpa:
    input:
        get_url,
    output:
        temp(Path("resources", "reads", "{readfile}")),
    resources:
        runtime=lambda wildcards, attempt: int(30 * attempt),
    shell:
        "cp {input} {output}"
