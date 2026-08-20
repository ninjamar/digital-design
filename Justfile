default:
    @just --list

# List project dirs (anything containing config.mk)
projects:
    @for d in */; do if [ -f "$d/config.mk" ]; then basename "$d"; fi; done

[arg("linter", long="linter")]
lint project linter="vivado":
    make lint PROJECT={{project}} LINTER={{linter}}
alias l := lint

format project:
    make format PROJECT={{project}}
alias fmt := format

[arg("simulator", long="simulator")]
[arg("tb", long="tb")]
testbench project simulator="verilator" tb="":
    make testbench PROJECT={{project}} SIMULATOR={{simulator}} TB={{tb}}
alias tb := testbench

[arg("simulator", long="simulator")]
[arg("tb", long="tb")]
testbench-build project simulator="verilator" tb="":
    make testbench-build PROJECT={{project}} SIMULATOR={{simulator}} TB={{tb}}
alias tbb := testbench-build

[arg("simulator", long="simulator")]
[arg("tb", long="tb")]
testbench-run project simulator="verilator" tb="":
    make testbench-run PROJECT={{project}} SIMULATOR={{simulator}} TB={{tb}}
alias tbr := testbench-run

[arg("fast", long="fast", value="1")]
[arg("threads", long="threads")]
synth project fast="0" threads="":
    make synth PROJECT={{project}} FAST={{fast}} THREADS={{threads}}

[arg("fast", long="fast", value="1")]
[arg("threads", long="threads")]
impl project fast="0" threads="" incremental="0":
    make impl PROJECT={{project}} FAST={{fast}} THREADS={{threads}} INCREMENTAL={{incremental}}

[arg("fast", long="fast", value="1")]
[arg("threads", long="threads")]
bitstream project fast="0" threads="":
    make bitstream PROJECT={{project}} FAST={{fast}} THREADS={{threads}}
alias bit := bitstream

[arg("mode", long="mode")]
program project mode="jtag":
    make program PROJECT={{project}} MODE={{mode}}
alias flash := program

[arg("fast", long="fast", value="1")]
[arg("threads", long="threads")]
all project fast="0" threads="" incremental="0":
    make all PROJECT={{project}} FAST={{fast}} THREADS={{threads}} INCREMENTAL={{incremental}}

clean project:
    make clean PROJECT={{project}}

new-project project board:
    make new-project PROJECT={{project}} BOARD={{board}}
alias new := new-project
