#!/bin/bash
# Run cocotb tests with automatic setup

set -e

cd "$(dirname "$0")"

echo "=========================================="
echo "Cocotb Test Runner"
echo "=========================================="
echo ""

# Run setup script
echo "Running setup..."
source ./setup_cocotb.sh 2>&1 | grep -v "ERROR: No simulator" || true

# Export PATH and PYTHONPATH
export PATH="$HOME/Library/Python/3.9/bin:$PATH"
export PYTHONPATH="$(pwd):$PYTHONPATH"

# Check for simulator again
SIM=""
if command -v verilator &> /dev/null; then
    SIM="verilator"
    echo "Using Verilator"
elif command -v iverilog &> /dev/null; then
    SIM="icarus"
    echo "Using Icarus Verilog"
elif command -v vcs &> /dev/null; then
    SIM="vcs"
    echo "Using VCS"
else
    echo ""
    echo "=========================================="
    echo "ERROR: No simulator found!"
    echo "=========================================="
    echo ""
    echo "Please install a simulator:"
    echo "  brew install verilator"
    echo "  OR"
    echo "  brew install icarus-verilog"
    echo ""
    echo "If verilator installation is in progress, wait for it to complete."
    echo "Then run this script again."
    exit 1
fi

echo ""
echo "Running tests with SIM=$SIM"
echo ""

# Set PYTHONPATH so Python can find test modules
export PYTHONPATH="$(pwd):$PYTHONPATH"

# Run tests
make test_all SIM=$SIM

echo ""
echo "=========================================="
echo "All tests completed!"
echo "=========================================="

