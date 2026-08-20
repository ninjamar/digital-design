include boards.mk

VIVADO := vivado -mode batch -nolog -nojournal -source

MODE        ?= jtag
FAST        ?= 0
THREADS     ?=
INCREMENTAL ?= 0
LINTER      ?= vivado
SIMULATOR   ?= verilator
TB          ?=

.PHONY: lint synth impl bitstream program ensure-hw-server format testbench testbench-build testbench-run all clean new-project

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
ALL_SRCS := $(wildcard $(PROJECT)/*.sv $(PROJECT)/*.v)
SRCS     := $(filter-out $(PROJECT)/tb_%,$(ALL_SRCS))
TB_SRCS  := $(filter $(PROJECT)/tb_%,$(ALL_SRCS))
BUILD    := build/$(PROJECT)
endif

lint:
ifeq ($(LINTER),verilator)
	verilator --lint-only --sv -Wall --Wno-fatal --top-module $(TOP) $(SRCS)
else
	$(VIVADO) scripts/lint.tcl -tclargs $(TOP) $(PART) "$(SRCS)" $(XDC)
endif

format:
	verible-verilog-format --inplace $(ALL_SRCS)

testbench: testbench-build testbench-run

testbench-build:
	@files="$(if $(TB),$(PROJECT)/$(TB),$(TB_SRCS))"; \
	if [ -z "$$files" ]; then echo "No testbenches found in $(PROJECT)/"; exit 1; fi; \
	for tb in $$files; do \
		name=$$(basename "$$tb" .sv); name=$$(basename "$$name" .v); \
		echo "=== building $$tb ==="; \
		mkdir -p $(BUILD)/sim/$$name; \
		if [ "$(SIMULATOR)" = "vivado" ]; then \
			( cd $(BUILD)/sim/$$name && \
			  xvlog -sv $(addprefix $(CURDIR)/,$(SRCS)) $(CURDIR)/$$tb && \
			  xelab $$name -s $${name}_sim -debug typical ); \
		else \
			verilator --binary --timing -sv --Wno-fatal --trace-fst --top-module "$$name" -Mdir $(BUILD)/sim/$$name $(SRCS) "$$tb"; \
		fi; \
	done

testbench-run:
	@files="$(if $(TB),$(PROJECT)/$(TB),$(TB_SRCS))"; \
	if [ -z "$$files" ]; then echo "No testbenches found in $(PROJECT)/"; exit 1; fi; \
	for tb in $$files; do \
		name=$$(basename "$$tb" .sv); name=$$(basename "$$name" .v); \
		echo "=== running $$tb ==="; \
		if [ "$(SIMULATOR)" = "vivado" ]; then \
			( cd $(BUILD)/sim/$$name && xsim $${name}_sim -R ); \
		else \
			$(BUILD)/sim/$$name/V$$name; \
		fi; \
	done

$(BUILD)/post_synth.dcp: $(SRCS) $(XDC)
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
	mkdir -p $(PROJECT)
	cp $(XDC_MASTER_$(BOARD)) $(PROJECT)/$(notdir $(PROJECT)).xdc
	sed 's/@BOARD@/$(BOARD)/' templates/config.mk.template > $(PROJECT)/config.mk
	@echo "Created $(PROJECT)/. Set TOP in config.mk, then trim $(PROJECT)/$(notdir $(PROJECT)).xdc"
