include boards.mk


VERIBLE_FORMAT_FLAGS := \
	--indentation_spaces=4 \
	--wrap_spaces=4 \
	--try_wrap_long_lines=true \
	--named_port_alignment=flush-left \
	--named_parameter_alignment=flush-left \
	--port_declarations_alignment=flush-left \
	--formal_parameters_alignment=flush-left \
	--module_net_variable_alignment=flush-left \
	--case_items_alignment=flush-left \
	--struct_union_members_alignment=flush-left \
	--formal_parameters_indentation=indent \
	--port_declarations_indentation=indent \
	--named_parameter_indentation=indent \
	--named_port_indentation=indent

VIVADO := vivado -mode batch -nolog -nojournal -source

MODE        ?= jtag
FAST        ?= 0
THREADS     ?=
INCREMENTAL ?= 0
LINTER      ?= vivado
SIMULATOR   ?= verilator
TB          ?=

.PHONY: lint synth impl bitstream program ensure-hw-server format testbench testbench-build testbench-run all clean new-project check-srcs prebuild

HW_SERVER_PORT ?= 3121

ifneq ($(MAKECMDGOALS),new-project)
ifndef PROJECT
$(error PROJECT is required, e.g. make synth PROJECT=clock)
endif

include $(PROJECT)/config.mk

ifndef TOP
$(error TOP not set in $(PROJECT)/config.mk)
endif
ifndef BOARD
$(error BOARD not set in $(PROJECT)/config.mk)
endif
ifndef PART_$(BOARD)
$(error Unknown BOARD '$(BOARD)' -- add it to boards.mk)
endif

PART        := $(PART_$(BOARD))
CFGMEM      := $(CFGMEM_$(BOARD))
CFGMEM_SIZE := $(CFGMEM_SIZE_$(BOARD))
XDC      := $(PROJECT)/$(notdir $(PROJECT)).xdc
RTL_SRCS := $(wildcard $(PROJECT)/rtl/*.sv $(PROJECT)/rtl/*.v)
TB_SRCS  := $(wildcard $(PROJECT)/tb/*.sv $(PROJECT)/tb/*.v)
ALL_SRCS := $(RTL_SRCS) $(TB_SRCS)
SRCS     := $(RTL_SRCS) $(LIB)
BUILD    := build/$(PROJECT)
endif

# Optional per-project prebuild step (set PREBUILD in $(PROJECT)/config.mk).
PREBUILD ?=
prebuild:
	$(if $(strip $(PREBUILD)),$(PREBUILD),@:)

check-srcs: prebuild
	@test -n "$(strip $(RTL_SRCS))" || { echo "error: no RTL sources in $(PROJECT)/rtl/" >&2; exit 1; }
	@for f in $(SRCS); do test -f "$$f" || { echo "error: missing source: $$f" >&2; exit 1; }; done

lint: check-srcs
ifeq ($(LINTER),verilator)
	verilator --lint-only --sv -Wall --top-module $(TOP) $(SRCS)
else
	$(VIVADO) scripts/lint.tcl -tclargs $(TOP) $(PART) "$(SRCS)" $(XDC)
endif

format:
	verible-verilog-format $(VERIBLE_FORMAT_FLAGS) --inplace $(ALL_SRCS)

testbench: testbench-build testbench-run

testbench-build: check-srcs
	./scripts/testbench.sh build $(PROJECT) $(SIMULATOR) $(BUILD) $(CURDIR) $(SRCS) -- $(if $(TB),$(PROJECT)/tb/$(TB),$(TB_SRCS))

testbench-run:
	./scripts/testbench.sh run $(PROJECT) $(SIMULATOR) $(BUILD) $(CURDIR) $(SRCS) -- $(if $(TB),$(PROJECT)/tb/$(TB),$(TB_SRCS))

$(BUILD)/post_synth.dcp: $(SRCS) $(XDC) | check-srcs
	mkdir -p $(BUILD)
	$(VIVADO) scripts/synth.tcl -tclargs $(TOP) $(PART) "$(SRCS)" $(XDC) $(BUILD) $(FAST) $(THREADS)

synth: $(BUILD)/post_synth.dcp

$(BUILD)/post_route.dcp: $(BUILD)/post_synth.dcp
	$(VIVADO) scripts/impl.tcl -tclargs $(BUILD) $(FAST) $(INCREMENTAL) $(THREADS)

impl: $(BUILD)/post_route.dcp

$(BUILD)/$(TOP).bit: $(BUILD)/post_route.dcp
	$(VIVADO) scripts/bitstream.tcl -tclargs $(BUILD) $(TOP)

bitstream: $(BUILD)/$(TOP).bit

ensure-hw-server:
	@nc -z localhost $(HW_SERVER_PORT) 2>/dev/null && exit 0; \
	echo "Starting hw_server..."; \
	nohup hw_server >/tmp/hw_server.log 2>&1 & \
	for i in $$(seq 1 20); do \
		nc -z localhost $(HW_SERVER_PORT) 2>/dev/null && exit 0; \
		sleep 0.5; \
	done; \
	echo "error: hw_server did not come up on port $(HW_SERVER_PORT), see /tmp/hw_server.log" >&2; \
	exit 1

program: $(BUILD)/$(TOP).bit ensure-hw-server
	$(VIVADO) scripts/program.tcl -tclargs $(BUILD)/$(TOP).bit $(MODE) $(CFGMEM) $(CFGMEM_SIZE)

all: bitstream

clean:
	rm -rf $(BUILD)

new-project:
ifndef PROJECT
	$(error usage: make new-project PROJECT=<dir> BOARD=<board>)
endif
ifndef BOARD
	$(error usage: make new-project PROJECT=<dir> BOARD=<board>)
endif
	@test ! -e $(PROJECT) || (echo "error: $(PROJECT) already exists" && exit 1)
	mkdir -p $(PROJECT)/rtl $(PROJECT)/tb
	cp $(XDC_MASTER_$(BOARD)) $(PROJECT)/$(notdir $(PROJECT)).xdc
	sed 's/@BOARD@/$(BOARD)/' templates/config.mk.template > $(PROJECT)/config.mk
	sed 's/@PROJECT@/$(notdir $(PROJECT))/' templates/README.md.template > $(PROJECT)/README.md
	@echo "Created $(PROJECT)/ with rtl/, tb/, README.md. Set TOP in config.mk, then trim $(PROJECT)/$(notdir $(PROJECT)).xdc"
