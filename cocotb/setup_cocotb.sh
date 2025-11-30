#!/bin/bash
# Setup script for cocotb testbenches

set -e

echo "=========================================="
echo "Cocotb Setup Script"
echo "=========================================="
echo ""

# Check Python version
echo "Checking Python..."
if ! command -v python3 &> /dev/null; then
    echo "ERROR: python3 not found. Please install Python 3."
    exit 1
fi
PYTHON_VERSION=$(python3 --version)
echo "✓ Found: $PYTHON_VERSION"
echo ""

# Get Python user base directory
PYTHON_USER_BASE=$(python3 -m site --user-base 2>/dev/null || echo "$HOME/Library/Python/$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')")
PYTHON_USER_BIN="$PYTHON_USER_BASE/bin"

# Check if cocotb is installed
echo "Checking cocotb installation..."
if ! python3 -m pip show cocotb &> /dev/null; then
    echo "cocotb not found. Installing..."
    python3 -m pip install cocotb --user
    echo "✓ cocotb installed"
else
    COCOTB_VERSION=$(python3 -m pip show cocotb | grep Version | awk '{print $2}')
    echo "✓ cocotb found (version $COCOTB_VERSION)"
fi
echo ""

# Check cocotb-config accessibility
echo "Checking cocotb-config..."
if [ -f "$PYTHON_USER_BIN/cocotb-config" ]; then
    echo "✓ cocotb-config found at $PYTHON_USER_BIN/cocotb-config"
    # Add to PATH if not already there
    if [[ ":$PATH:" != *":$PYTHON_USER_BIN:"* ]]; then
        export PATH="$PYTHON_USER_BIN:$PATH"
        echo "✓ Added $PYTHON_USER_BIN to PATH for this session"
        echo ""
        echo "To make this permanent, add to your ~/.bashrc or ~/.zshrc:"
        echo "  export PATH=\"$PYTHON_USER_BIN:\$PATH\""
    else
        echo "✓ $PYTHON_USER_BIN already in PATH"
    fi
else
    echo "WARNING: cocotb-config not found at expected location"
    echo "Trying to find it..."
    COCOTB_CONFIG=$(python3 -c "import cocotb; import os; print(os.path.join(os.path.dirname(cocotb.__file__), '..', 'bin', 'cocotb-config'))" 2>/dev/null || echo "")
    if [ -f "$COCOTB_CONFIG" ]; then
        echo "✓ Found cocotb-config at $COCOTB_CONFIG"
    else
        echo "ERROR: Could not find cocotb-config"
        exit 1
    fi
fi
echo ""

# Verify cocotb-config works
if command -v cocotb-config &> /dev/null || [ -f "$PYTHON_USER_BIN/cocotb-config" ]; then
    if [ -f "$PYTHON_USER_BIN/cocotb-config" ]; then
        export PATH="$PYTHON_USER_BIN:$PATH"
    fi
    COCOTB_MAKEFILES=$(cocotb-config --makefiles 2>/dev/null || echo "")
    if [ -n "$COCOTB_MAKEFILES" ] && [ -d "$COCOTB_MAKEFILES" ]; then
        echo "✓ cocotb-config working correctly"
        echo "  Makefiles location: $COCOTB_MAKEFILES"
    else
        echo "WARNING: cocotb-config --makefiles returned invalid path"
    fi
else
    echo "ERROR: cocotb-config not accessible"
    exit 1
fi
echo ""

# Check for simulators
echo "Checking for simulators..."
SIMULATOR_FOUND=0

# Check Verilator
if command -v verilator &> /dev/null; then
    VERILATOR_VERSION=$(verilator --version 2>&1 | head -1)
    echo "✓ Verilator found: $VERILATOR_VERSION"
    SIMULATOR_FOUND=1
    RECOMMENDED_SIM="verilator"
else
    echo "✗ Verilator not found"
    echo "  Install with: brew install verilator"
fi

# Check Icarus Verilog
if command -v iverilog &> /dev/null; then
    IVERILOG_VERSION=$(iverilog -v 2>&1 | head -1)
    echo "✓ Icarus Verilog found: $IVERILOG_VERSION"
    SIMULATOR_FOUND=1
    if [ -z "$RECOMMENDED_SIM" ]; then
        RECOMMENDED_SIM="icarus"
    fi
else
    echo "✗ Icarus Verilog not found"
    echo "  Install with: brew install icarus-verilog"
fi

# Check VCS (if available)
if command -v vcs &> /dev/null; then
    echo "✓ VCS found"
    SIMULATOR_FOUND=1
    if [ -z "$RECOMMENDED_SIM" ]; then
        RECOMMENDED_SIM="vcs"
    fi
fi

echo ""

if [ $SIMULATOR_FOUND -eq 0 ]; then
    echo "ERROR: No simulator found!"
    echo ""
    echo "Please install at least one simulator:"
    echo "  - Verilator (recommended): brew install verilator"
    echo "  - Icarus Verilog: brew install icarus-verilog"
    exit 1
else
    echo "✓ At least one simulator is available"
    if [ -n "$RECOMMENDED_SIM" ]; then
        echo "  Recommended: SIM=$RECOMMENDED_SIM"
    fi
fi

echo ""
echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo ""
echo "To run tests, use:"
if [ -n "$RECOMMENDED_SIM" ]; then
    echo "  make test_all SIM=$RECOMMENDED_SIM"
    echo "  make test_max_finder SIM=$RECOMMENDED_SIM"
else
    echo "  make test_all SIM=<simulator_name>"
fi
echo ""
echo "Note: If you see 'cocotb-config: command not found', run:"
echo "  export PATH=\"$PYTHON_USER_BIN:\$PATH\""
echo ""

