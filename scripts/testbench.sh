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

# Compile-time include search paths, and the directory sims run from.
# Running from the project root means `$dumpfile("waveforms/x.fst")` and
# relative `$readmemh` paths in a TB resolve against $project/.
incdirs=("$curdir/$project" "$curdir/$project/rtl" "$curdir/$project/tb")
rundir="$curdir/$project"

for tb in "${tbs[@]}"; do
    name=$(basename "$tb" .sv)
    name=$(basename "$name" .v)

    case "$action" in
    build)
        echo "=== building $tb ==="
        mkdir -p "$build/sim/$name"
        if [ "$simulator" = "vivado" ]; then
            xvinc=(); for d in "${incdirs[@]}"; do xvinc+=(-i "$d"); done
            (
                cd "$build/sim/$name"
                xvlog -sv "${xvinc[@]}" "${srcs[@]/#/$curdir/}" "$curdir/$tb"
                xelab "$name" -s "${name}_sim" -debug typical
            )
        else
            vinc=(); for d in "${incdirs[@]}"; do vinc+=("-I$d"); done
            verilator --binary --timing -sv --Wno-fatal --trace-fst \
                --top-module "$name" -Mdir "$build/sim/$name" \
                "${vinc[@]}" "${srcs[@]}" "$tb"
        fi
        ;;
    run)
        echo "=== running $tb ==="
        mkdir -p "$rundir/waveforms"
        if [ "$simulator" = "vivado" ]; then
            ( cd "$rundir" && xsim --xsimdir "$curdir/$build/sim/$name/xsim.dir" "${name}_sim" -R )
        else
            ( cd "$rundir" && "$curdir/$build/sim/$name/V$name" )
        fi
        ;;
    *)
        echo "unknown action: $action" >&2
        exit 1
        ;;
    esac
done
