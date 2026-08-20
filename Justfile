default:
    @just --list

# List project dirs (anything containing config.mk)
projects:
    @for d in */; do if [ -f "$d/config.mk" ]; then basename "$d"; fi; done

# Lint sources. --linter=vivado|verilator (default: vivado)
[arg("linter", long="linter")]
lint project linter="vivado":
    make lint PROJECT={{project}} LINTER={{linter}}
alias l := lint

# Format sources with verible-verilog-format.
format project:
    make format PROJECT={{project}}
alias fmt := format

# Build and run testbenches. --simulator=verilator|vivado (default: verilator), --tb=<file> (default: all testbenches in project)
[arg("simulator", long="simulator")]
[arg("tb", long="tb")]
testbench project simulator="verilator" tb="":
    make testbench PROJECT={{project}} SIMULATOR={{simulator}} TB={{tb}}
alias tb := testbench

# Build testbenches only. --simulator=verilator|vivado (default: verilator), --tb=<file> (default: all testbenches in project)
[arg("simulator", long="simulator")]
[arg("tb", long="tb")]
testbench-build project simulator="verilator" tb="":
    make testbench-build PROJECT={{project}} SIMULATOR={{simulator}} TB={{tb}}
alias tbb := testbench-build

# Run already-built testbenches. --simulator=verilator|vivado (default: verilator), --tb=<file> (default: all testbenches in project)
[arg("simulator", long="simulator")]
[arg("tb", long="tb")]
testbench-run project simulator="verilator" tb="":
    make testbench-run PROJECT={{project}} SIMULATOR={{simulator}} TB={{tb}}
alias tbr := testbench-run

# Synthesize. --fast, --threads=<n> (default: nproc)
[arg("fast", long="fast", value="1")]
[arg("threads", long="threads")]
synth project fast="0" threads=`nproc`:
    make synth PROJECT={{project}} FAST={{fast}} THREADS={{threads}}

# Place and route. --fast, --threads=<n> (default: nproc), --incremental
[arg("fast", long="fast", value="1")]
[arg("threads", long="threads")]
[arg("incremental", long="incremental", value="1")]
impl project fast="0" threads=`nproc` incremental="0":
    make impl PROJECT={{project}} FAST={{fast}} THREADS={{threads}} INCREMENTAL={{incremental}}

# Generate bitstream. --fast, --threads=<n> (default: nproc)
[arg("fast", long="fast", value="1")]
[arg("threads", long="threads")]
bitstream project fast="0" threads=`nproc`:
    make bitstream PROJECT={{project}} FAST={{fast}} THREADS={{threads}}
alias bit := bitstream

# Program the board. --mode=jtag|flash (default: jtag)
[arg("mode", long="mode")]
program project mode="jtag":
    make program PROJECT={{project}} MODE={{mode}}
alias flash := program

# Run the full flow (synth -> impl -> bitstream). --fast, --threads=<n> (default: nproc), --incremental
[arg("fast", long="fast", value="1")]
[arg("threads", long="threads")]
[arg("incremental", long="incremental", value="1")]
all project fast="0" threads=`nproc` incremental="0":
    make all PROJECT={{project}} FAST={{fast}} THREADS={{threads}} INCREMENTAL={{incremental}}

# Remove build output for a project.
clean project:
    make clean PROJECT={{project}}

# Scaffold a new project. board must exist in boards.mk (currently: basys3).
new-project project board:
    make new-project PROJECT={{project}} BOARD={{board}}
alias new := new-project
