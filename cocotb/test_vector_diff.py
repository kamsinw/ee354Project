import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

@cocotb.test()
async def test_vector_diff(dut):
    """Test vector_diff module"""
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    # Reset
    dut.reset.value = 1
    dut.start.value = 0
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.reset.value = 0
    
    # Test: V_new = [5,6,7,8], V_old = [1,2,3,4]
    # Expected max_diff = max(|5-1|, |6-2|, |7-3|, |8-4|) = 4
    V_new = (8 << 48) | (7 << 32) | (6 << 16) | 5
    V_old = (4 << 48) | (3 << 32) | (2 << 16) | 1
    
    dut.V_new.value = V_new
    dut.V_old.value = V_old
    
    dut.start.value = 1
    await RisingEdge(dut.clk)
    dut.start.value = 0
    
    # Wait for done
    timeout = 100
    while dut.done.value == 0 and timeout > 0:
        await RisingEdge(dut.clk)
        timeout -= 1
    
    assert dut.done.value == 1, "Difference calculation did not complete"
    
    # Check max_diff
    max_diff = dut.max_diff.value.signed_integer
    assert max_diff == 4, f"Expected max_diff=4, got {max_diff}"
    
    print("✓ vector_diff test passed")

