include boards.mk

VIVADO := vivado -mode batch -nolog -nojournal -source

.PHONY: lint synth impl bitstream program all clean new-project

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

PART  := $(PART_$(BOARD))
XDC   := $(PROJECT)/$(notdir $(PROJECT)).xdc
SRCS  := $(filter-out $(PROJECT)/tb_%,$(wildcard $(PROJECT)/*.sv $(PROJECT)/*.v))
BUILD := build/$(PROJECT)
endif

lint:
	$(VIVADO) scripts/lint.tcl -tclargs $(TOP) $(PART) "$(SRCS)" $(XDC)

$(BUILD)/post_synth.dcp: $(SRCS) $(XDC)
	mkdir -p $(BUILD)
	$(VIVADO) scripts/synth.tcl -tclargs $(TOP) $(PART) "$(SRCS)" $(XDC) $(BUILD)

synth: $(BUILD)/post_synth.dcp

$(BUILD)/post_route.dcp: $(BUILD)/post_synth.dcp
	$(VIVADO) scripts/impl.tcl -tclargs $(BUILD)

impl: $(BUILD)/post_route.dcp

$(BUILD)/$(TOP).bit: $(BUILD)/post_route.dcp
	$(VIVADO) scripts/bitstream.tcl -tclargs $(BUILD) $(TOP)

bitstream: $(BUILD)/$(TOP).bit

program: $(BUILD)/$(TOP).bit
	$(VIVADO) scripts/program.tcl -tclargs $(BUILD)/$(TOP).bit

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
