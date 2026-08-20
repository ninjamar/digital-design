#!/usr/bin/env bash
# Build or run testbenches for a project. Invoked from the Makefile's
# testbench-build/testbench-run targets, which resolve which tb files to
# use and pass them after `--`.
set -euo pipefail

action=$1; shift
project=$1; shift
simulator=$1; shift
build=$1; shift
curdir=$1; shift

srcs=()
while [ "$1" != "--" ]; do
    srcs+=("$1")
    shift
done
shift # consume --

tbs=("$@")

if [ ${#tbs[@]} -eq 0 ]; then
    echo "No testbenches found in $project/" >&2
    exit 1
fi

for tb in "${tbs[@]}"; do
    name=$(basename "$tb" .sv)
    name=$(basename "$name" .v)

    case "$action" in
    build)
        echo "=== building $tb ==="
        mkdir -p "$build/sim/$name"
        if [ "$simulator" = "vivado" ]; then
            (
                cd "$build/sim/$name"
                xvlog -sv "${srcs[@]/#/$curdir/}" "$curdir/$tb"
                xelab "$name" -s "${name}_sim" -debug typical
            )
        else
            verilator --binary --timing -sv --Wno-fatal --trace-fst \
                --top-module "$name" -Mdir "$build/sim/$name" "${srcs[@]}" "$tb"
        fi
        ;;
    run)
        echo "=== running $tb ==="
        if [ "$simulator" = "vivado" ]; then
            ( cd "$build/sim/$name" && xsim "${name}_sim" -R )
        else
            "$build/sim/$name/V$name"
        fi
        ;;
    *)
        echo "unknown action: $action" >&2
        exit 1
        ;;
    esac
done
