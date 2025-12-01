#!/bin/bash
# Run all cocotb tests - will work once verilator is installed

set -e

cd "$(dirname "$0")"
# We're already in cocotb directory

# Setup PATH
export PATH="/opt/homebrew/bin:$HOME/Library/Python/3.9/bin:$PATH"

# Check for verilator
if ! command -v verilator &> /dev/null; then
    echo "ERROR: verilator not found in PATH"
    echo ""
    echo "Trying to find verilator..."
    
    # Try common locations
    if [ -f "/opt/homebrew/bin/verilator" ]; then
        export PATH="/opt/homebrew/bin:$PATH"
    elif [ -d "/opt/homebrew/Cellar/verilator" ]; then
        VERILATOR_BIN=$(find /opt/homebrew/Cellar/verilator -name "verilator" -type f | head -1)
        if [ -n "$VERILATOR_BIN" ]; then
            export PATH="$(dirname $VERILATOR_BIN):$PATH"
        fi
    fi
    
    if ! command -v verilator &> /dev/null; then
        echo "Verilator still not found. Please install it:"
        echo "  brew install verilator"
        echo ""
        echo "Or wait for the current installation to complete."
        exit 1
    fi
fi

echo "Using verilator: $(which verilator)"
verilator --version | head -1
echo ""

# Set PYTHONPATH so Python can find test modules
export PYTHONPATH="$(pwd):$PYTHONPATH"

# Run all tests
echo "=========================================="
echo "Running all cocotb tests"
echo "=========================================="
echo ""

make test_all SIM=verilator

echo ""
echo "=========================================="
echo "All tests completed!"
echo "=========================================="

