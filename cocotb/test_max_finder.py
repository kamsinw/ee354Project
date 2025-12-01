import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
import random

@cocotb.test()
async def test_max_finder(dut):
    """Test max_finder module"""
    await Timer(20, unit="ns")
    
    # Test case 1: All positive values
    dut.a.value = (1 << 48) | (2 << 32) | (3 << 16) | 4
    await Timer(10, unit="ns")
    assert dut.max_val.value.to_signed() == 4, f"Expected 4, got {dut.max_val.value.to_signed()}"
    
    # Test case 2: Mixed positive and negative
    # Pack negative values: -5 = 0xFFFB, -7 = 0xFFF9
    a_val2 = (0xFFFB << 48) | (3 << 32) | (0xFFF9 << 16) | 2  # [-5, 3, -7, 2]
    dut.a.value = a_val2
    await Timer(10, unit="ns")
    # Max absolute value should be 7
    assert dut.max_val.value.to_signed() == 7, f"Expected 7, got {dut.max_val.value.to_signed()}"
    
    # Test case 3: All negative
    # Pack as two's complement: -1 = 0xFFFF, -5 = 0xFFFB, -3 = 0xFFFD, -2 = 0xFFFE
    a_val3 = (0xFFFF << 48) | (0xFFFB << 32) | (0xFFFD << 16) | 0xFFFE
    dut.a.value = a_val3
    await Timer(10, unit="ns")
    assert dut.max_val.value.to_signed() == 5, f"Expected 5, got {dut.max_val.value.to_signed()}"
    
    print("✓ max_finder test passed")

