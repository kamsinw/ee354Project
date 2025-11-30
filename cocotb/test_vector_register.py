import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
import random

@cocotb.test()
async def test_vector_register(dut):
    """Test vector_register module"""
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    # Reset
    dut.reset.value = 1
    dut.load.value = 0
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.reset.value = 0
    
    # Check initial value (should be [1,1,1,1])
    await RisingEdge(dut.clk)
    out_val = dut.out.value.integer
    v0 = (out_val >> 0) & 0xFFFF
    v1 = (out_val >> 16) & 0xFFFF
    v2 = (out_val >> 32) & 0xFFFF
    v3 = (out_val >> 48) & 0xFFFF
    
    # Sign extend if needed
    if v0 & 0x8000:
        v0 = v0 - 0x10000
    if v1 & 0x8000:
        v1 = v1 - 0x10000
    if v2 & 0x8000:
        v2 = v2 - 0x10000
    if v3 & 0x8000:
        v3 = v3 - 0x10000
    
    assert v0 == 1 and v1 == 1 and v2 == 1 and v3 == 1, f"Initial value should be [1,1,1,1], got [{v0},{v1},{v2},{v3}]"
    
    # Load new value
    new_val = (5 << 48) | (6 << 32) | (7 << 16) | 8
    dut._id("in", extended=False).value = new_val
    dut.load.value = 1
    await RisingEdge(dut.clk)
    dut.load.value = 0
    await RisingEdge(dut.clk)
    
    # Check loaded value
    out_val = dut.out.value.integer
    v0 = (out_val >> 0) & 0xFFFF
    v1 = (out_val >> 16) & 0xFFFF
    v2 = (out_val >> 32) & 0xFFFF
    v3 = (out_val >> 48) & 0xFFFF
    
    if v0 & 0x8000:
        v0 = v0 - 0x10000
    if v1 & 0x8000:
        v1 = v1 - 0x10000
    if v2 & 0x8000:
        v2 = v2 - 0x10000
    if v3 & 0x8000:
        v3 = v3 - 0x10000
    
    assert v0 == 8 and v1 == 7 and v2 == 6 and v3 == 5, f"Expected [8,7,6,5], got [{v0},{v1},{v2},{v3}]"
    
    print("✓ vector_register test passed")

