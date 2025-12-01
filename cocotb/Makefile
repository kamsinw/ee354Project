# Makefile for cocotb tests

# Default simulator (can be overridden)
SIM ?= verilator

# Top-level module for each test
TOPLEVEL = $(shell basename $(TEST) .py | sed 's/test_//')

# Python test file
TEST ?= test_dominant_full.py

# Extract module name from test file path (just the filename without .py)
MODULE = $(shell basename $(TEST) .py)

# Verilog source files (relative to cocotb directory)
VERILOG_SOURCES = \
	../rtl/abs_diff.v \
	../rtl/max_finder.v \
	../rtl/vector_register.v \
	../rtl/vector_scale.v \
	../rtl/vector_diff.v \
	../rtl/matrix_vector_mult.v \
	../rtl/matrix_memory.v \
	../rtl/multi_cycle_divider.v \
	../top/dominant_fsm.v \
	../top/dominant_datapath.v

# Include cocotb makefile
include $(shell cocotb-config --makefiles)/Makefile.sim

# Run all tests
.PHONY: test_all
test_all:
	@echo "Running all cocotb tests..."
	rm -rf sim_build && $(MAKE) TEST=test_max_finder.py TOPLEVEL=max_finder VERILOG_SOURCES=../rtl/max_finder.v MODULE=test_max_finder
	rm -rf sim_build && $(MAKE) TEST=test_vector_register.py TOPLEVEL=vector_register VERILOG_SOURCES=../rtl/vector_register.v MODULE=test_vector_register
	rm -rf sim_build && $(MAKE) TEST=test_matrix_vector_mult.py TOPLEVEL=matrix_vector_mult VERILOG_SOURCES="../rtl/matrix_vector_mult.v ../rtl/max_finder.v" MODULE=test_matrix_vector_mult
	rm -rf sim_build && $(MAKE) TEST=test_vector_scale.py TOPLEVEL=vector_scale VERILOG_SOURCES="../rtl/vector_scale.v ../rtl/max_finder.v ../rtl/multi_cycle_divider.v" MODULE=test_vector_scale
	rm -rf sim_build && $(MAKE) TEST=test_vector_diff.py TOPLEVEL=vector_diff VERILOG_SOURCES="../rtl/vector_diff.v ../rtl/abs_diff.v ../rtl/max_finder.v" MODULE=test_vector_diff
	rm -rf sim_build && $(MAKE) TEST=test_dominant_fsm.py TOPLEVEL=dominant_fsm VERILOG_SOURCES=../top/dominant_fsm.v MODULE=test_dominant_fsm
	rm -rf sim_build && $(MAKE) TEST=test_dominant_datapath.py TOPLEVEL=dominant_datapath VERILOG_SOURCES="$(VERILOG_SOURCES)" MODULE=test_dominant_datapath
	rm -rf sim_build && $(MAKE) TEST=test_dominant_full.py TOPLEVEL=tb_dominant_wrapper VERILOG_SOURCES="$(VERILOG_SOURCES) tb_dominant_wrapper.v" MODULE=test_dominant_full
	rm -rf sim_build && $(MAKE) TEST=test_vga_display.py TOPLEVEL=tb_vga_wrapper VERILOG_SOURCES="../vga/vga_top.v ../vga/counter.v ../vga/display_controller.v ../vga/block_digit_renderer.v tb_vga_wrapper.v" MODULE=test_vga_display
	@echo ""
	@echo "=========================================="
	@echo "All tests completed!"
	@echo "=========================================="

# Individual test targets
test_max_finder:
	$(MAKE) TEST=test_max_finder.py TOPLEVEL=max_finder VERILOG_SOURCES=../rtl/max_finder.v MODULE=test_max_finder

test_vector_register:
	$(MAKE) TEST=test_vector_register.py TOPLEVEL=vector_register VERILOG_SOURCES=../rtl/vector_register.v MODULE=test_vector_register

test_matrix_vector_mult:
	$(MAKE) TEST=test_matrix_vector_mult.py TOPLEVEL=matrix_vector_mult VERILOG_SOURCES="../rtl/matrix_vector_mult.v ../rtl/max_finder.v" MODULE=test_matrix_vector_mult

test_vector_scale:
	$(MAKE) TEST=test_vector_scale.py TOPLEVEL=vector_scale VERILOG_SOURCES="../rtl/vector_scale.v ../rtl/max_finder.v ../rtl/multi_cycle_divider.v" MODULE=test_vector_scale

test_vector_diff:
	$(MAKE) TEST=test_vector_diff.py TOPLEVEL=vector_diff VERILOG_SOURCES="../rtl/vector_diff.v ../rtl/abs_diff.v ../rtl/max_finder.v" MODULE=test_vector_diff

test_dominant_fsm:
	$(MAKE) TEST=test_dominant_fsm.py TOPLEVEL=dominant_fsm VERILOG_SOURCES=../top/dominant_fsm.v MODULE=test_dominant_fsm

test_dominant_datapath:
	$(MAKE) TEST=test_dominant_datapath.py TOPLEVEL=dominant_datapath VERILOG_SOURCES="$(VERILOG_SOURCES)" MODULE=test_dominant_datapath

test_dominant_full:
	$(MAKE) TEST=test_dominant_full.py TOPLEVEL=tb_dominant_wrapper VERILOG_SOURCES="$(VERILOG_SOURCES) tb_dominant_wrapper.v" MODULE=test_dominant_full

test_vga_display:
	$(MAKE) TEST=test_vga_display.py TOPLEVEL=tb_vga_wrapper VERILOG_SOURCES="../vga/vga_top.v ../vga/counter.v ../vga/display_controller.v ../vga/block_digit_renderer.v tb_vga_wrapper.v" MODULE=test_vga_display

