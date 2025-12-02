import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge

def pack_vector(vec, lane_width):
    packed = 0
    mask = (1 << lane_width) - 1
    for idx, val in enumerate(vec):
        packed |= (val & mask) << (lane_width * idx)
    return packed


def unpack_vector(value, lane_width):
    mask = (1 << lane_width) - 1
    return [(value >> (lane_width * idx)) & mask for idx in range(4)]


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
    
    lane_width = len(dut.vec_out.value) // 4
    
    # Check initial value (should be [1,1,1,1])
    await RisingEdge(dut.clk)
    observed = unpack_vector(dut.vec_out.value.integer, lane_width)
    assert observed == [1, 1, 1, 1], f"Initial value should be [1,1,1,1], got {observed}"
    
    # Load new value
    new_vec = [8, 7, 6, 5]
    dut.vec_in.value = pack_vector(new_vec, lane_width)
    dut.load.value = 1
    await RisingEdge(dut.clk)
    dut.load.value = 0
    await RisingEdge(dut.clk)
    
    observed = unpack_vector(dut.vec_out.value.integer, lane_width)
    assert observed == new_vec, f"Expected {new_vec}, got {observed}"
    
    print("✓ vector_register test passed")

