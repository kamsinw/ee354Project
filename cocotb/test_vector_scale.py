import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

@cocotb.test()
async def test_vector_scale(dut):
    """Test vector_scale module"""
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    # Reset
    dut.reset.value = 1
    dut.start.value = 0
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.reset.value = 0
    
    # Test: normalize [4, 8, 12, 16] (max=16)
    # Expected: each element divided by 16, then scaled to Q1.15
    V_in = (16 << 48) | (12 << 32) | (8 << 16) | 4
    dut.V_in.value = V_in
    
    dut.start.value = 1
    await RisingEdge(dut.clk)
    dut.start.value = 0
    
    # Wait for done
    timeout = 100
    while dut.done.value == 0 and timeout > 0:
        await RisingEdge(dut.clk)
        timeout -= 1
    
    assert dut.done.value == 1, "Scaling did not complete"
    
    # Check that output is normalized (max absolute value should be <= 32767)
    V_out_val = dut.V_out.value.integer
    v0 = (V_out_val >> 0) & 0xFFFF
    v1 = (V_out_val >> 16) & 0xFFFF
    v2 = (V_out_val >> 32) & 0xFFFF
    v3 = (V_out_val >> 48) & 0xFFFF
    
    # Sign extend
    if v0 & 0x8000:
        v0 = v0 - 0x10000
    if v1 & 0x8000:
        v1 = v1 - 0x10000
    if v2 & 0x8000:
        v2 = v2 - 0x10000
    if v3 & 0x8000:
        v3 = v3 - 0x10000
    
    max_abs = max(abs(v0), abs(v1), abs(v2), abs(v3))
    assert max_abs <= 32767, f"Max absolute value {max_abs} exceeds 32767"
    
    print("✓ vector_scale test passed")

