#!/bin/bash
# Script to run all cocotb tests

set -e

cd "$(dirname "$0")"

echo "=========================================="
echo "Running Cocotb Tests"
echo "=========================================="
echo ""

# Check if cocotb is installed
if ! python3 -m pip show cocotb > /dev/null 2>&1; then
    echo "Installing cocotb..."
    python3 -m pip install cocotb --user
fi

# Try to find a simulator
SIM=""
if command -v verilator &> /dev/null; then
    SIM="verilator"
    echo "Using Verilator simulator"
elif command -v iverilog &> /dev/null; then
    SIM="icarus"
    echo "Using Icarus Verilog simulator"
elif command -v vcs &> /dev/null; then
    SIM="vcs"
    echo "Using VCS simulator"
else
    echo "ERROR: No simulator found. Please install one of:"
    echo "  - Verilator: brew install verilator"
    echo "  - Icarus Verilog: brew install icarus-verilog"
    exit 1
fi

echo ""
echo "Running tests with SIM=$SIM"
echo ""

# Run tests one by one
TESTS=(
    "test_max_finder:max_finder:rtl/max_finder.v"
    "test_vector_register:vector_register:rtl/vector_register.v"
    "test_matrix_vector_mult:matrix_vector_mult:rtl/matrix_vector_mult.v rtl/max_finder.v"
    "test_vector_scale:vector_scale:rtl/vector_scale.v rtl/max_finder.v"
    "test_vector_diff:vector_diff:rtl/vector_diff.v rtl/abs_diff.v rtl/max_finder.v"
    "test_dominant_fsm:dominant_fsm:top/dominant_fsm.v"
)

PASSED=0
FAILED=0

for test_spec in "${TESTS[@]}"; do
    IFS=':' read -r test_file toplevel sources <<< "$test_spec"
    echo "----------------------------------------"
    echo "Running $test_file..."
    echo "----------------------------------------"
    
    if make SIM=$SIM TEST=tests/$test_file.py TOPLEVEL=$toplevel VERILOG_SOURCES="$sources" 2>&1 | tee /tmp/cocotb_test.log; then
        echo "✓ $test_file PASSED"
        ((PASSED++))
    else
        echo "✗ $test_file FAILED"
        ((FAILED++))
    fi
    echo ""
done

echo "=========================================="
echo "Test Summary: $PASSED passed, $FAILED failed"
echo "=========================================="

if [ $FAILED -eq 0 ]; then
    exit 0
else
    exit 1
fi

