DUT ?= rca
W ?= 2048
M ?= 2
N ?= 2

PROJ 	:= impl
TEST_FILE   = tb/test.cpp
GROUP := $(shell basename $(CURDIR) | cut -d'-' -f1)
SIM_DIR = /tmp/$(GROUP)/sim
VCD ?= 0
VCD_FILE_STR ?= "test.vcd"

ifeq ($(DUT),prefix_tree)
	TEST_SV = tb/test_prefix_tree.sv
	DUT_PARAMS = +define+N=$(N)
	ARCH_PARAM_NAME := N
	ARCH_PARAM_VAL  := $(N)
else
	# All adder variants use test_adder.sv
	TEST_SV = tb/test_adder.sv
	DUT_PARAMS = +define+W=$(W) +define+M=$(M)
	ARCH_PARAM_NAME := M
	ARCH_PARAM_VAL  := $(M)
endif

SRC = rtl/$(DUT).sv

REV = $(DUT)_$(ARCH_PARAM_NAME)$(ARCH_PARAM_VAL)

VFLAGS += -Wno-SELRANGE -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC -DTESTDIR=\"$(PWD)/data/\" -DTOP=$(TOP)
_CFLAGS = -CFLAGS

ifeq ($(VCD), 1)
VFLAGS+= --trace
_CFLAGS+= -DVCD -CFLAGS -DVCD_FILE=\\\"$(VCD_FILE_STR)\\\"
endif

setup:
	rm -rf $(PROJ)/output_files_$(REV) $(PROJ)/$(REV).qsf
	quartus_sh -t fpga/setup.tcl $(PROJ) $(REV) $(DUT) $(W) $(ARCH_PARAM_VAL)

data:
ifeq ($(DUT),prefix_tree)
	python3 data/generate_prefix_tree_data.py $(if $(TESTS),-n $(TESTS),--exhaustive) -w $(N) -o data/ -r tb/
else
	python3 data/generate_adder_data.py $(if $(TESTS),-n $(TESTS),--exhaustive) -w $(W) -o data/ -r tb/
endif

compile:
	rm -rf sim
	mkdir -p $(SIM_DIR)
	verilator $(VFLAGS) \
		$(_CFLAGS) \
		-Itb\
		-Irtl\
		--cc $(SRC)\
		$(TEST_SV) \
		--exe $(PWD)/$(TEST_FILE) \
		-top-module top \
		--Mdir $(SIM_DIR) \
		+define+TOPNAME=$(DUT) \
		$(DUT_PARAMS)
	make -C $(SIM_DIR) -f Vtop.mk Vtop

# make sim DUT=[rca_pipe|csa_pipe|naiveadder2048b|cleveradder2048b] M=[m] or make DUT=prefix_tree N=[n]
sim: compile
	echo "Verilator Running Test for $(DUT)"
	rm -f $(SIM_DIR)/log_$(REV).csv
	cd $(SIM_DIR) && ./Vtop >> log_$(REV).csv
	cat $(SIM_DIR)/log_$(REV).csv

# make [synth|fit] DUT=[rca_pipe|csa_pipe|naiveadder2048b|cleveradder2048b] M=[m] or make [synth|fit] DUT=prefix_tree N=[n]
synth: setup
	echo "Running Synth for $(DUT)."
	rm -rf $(PROJ)/output_files_$(REV)
	quartus_sh -t fpga/synth.tcl $(REV)
	@echo "Done Synth. Reports in $(PROJ)/output_files_$(REV)/"

fit: setup
	rm -rf $(PROJ)/output_files_$(REV)
	quartus_sh -t fpga/impl.tcl $(REV)
	@echo "Done Fitter. Reports in $(PROJ)/output_files_$(REV)/"

# make extract DUT=[rca_pipe|csa_pipe|naiveadder2048b|cleveradder2048b] M=[m] or make [synth|fit] DUT=prefix_tree N=[n]
extract:
	rm -f results/$(DUT).csv
	@mkdir -p results
	@./extract.sh $(DUT) $(REV)
	@echo "Extract metrics to results/$(REV).csv successfully"

extract_sim:
	@grade=$$(grep "GRADE:" $(SIM_DIR)/log_$(REV).csv | cut -d':' -f2 | tr -      d '[:space:]'); \
	if [ "$$grade" = "1" ]; then echo PASS; else echo FAIL; fi

.PHONY: clean data

clean:
	rm -rf sim impl results
