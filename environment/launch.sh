#!/usr/bin/env bash
dir="$(dirname "$(realpath "$0")")"
while ! python "$dir/healthcheck.py"; do
    sleep 10
done

python "$dir/main.py"