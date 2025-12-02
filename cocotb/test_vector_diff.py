import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge

def pack_vector(values, lane_width):
    packed = 0
    mask = (1 << lane_width) - 1
    for idx, val in enumerate(values):
        packed |= (val & mask) << (lane_width * idx)
    return packed


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
    
    lane_width = len(dut.V_new.value) // 4
    vec_new = [5, 6, 7, 8]
    vec_old = [1, 2, 3, 4]
    
    dut.V_new.value = pack_vector(vec_new, lane_width)
    dut.V_old.value = pack_vector(vec_old, lane_width)
    
    dut.start.value = 1
    await RisingEdge(dut.clk)
    dut.start.value = 0
    
    # Wait for done
    timeout = 100
    while dut.done.value == 0 and timeout > 0:
        await RisingEdge(dut.clk)
        timeout -= 1
    
    assert dut.done.value == 1, "Difference calculation did not complete"
    
    max_diff = dut.max_diff.value.integer
    assert max_diff == 4, f"Expected max_diff=4, got {max_diff}"
    
    print("✓ vector_diff test passed")

