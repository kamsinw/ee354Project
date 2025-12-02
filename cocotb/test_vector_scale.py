import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge

def pack_vector(values, lane_width):
    packed = 0
    mask = (1 << lane_width) - 1
    for idx, val in enumerate(values):
        packed |= (val & mask) << (lane_width * idx)
    return packed


def unpack_vector(value, lane_width):
    mask = (1 << lane_width) - 1
    return [(value >> (lane_width * idx)) & mask for idx in range(4)]


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
    
    lane_width_in = len(dut.V_in.value) // 4
    lane_width_out = len(dut.V_out.value) // 4
    assert lane_width_out == 4, "vector_scale should output 4-bit nibbles"
    
    vec = [4, 8, 12, 14]
    norm_sq = sum(v * v for v in vec)
    norm = int(norm_sq ** 0.5) or 1
    
    dut.V_in.value = pack_vector(vec, lane_width_in)
    dut.norm_value.value = norm
    
    dut.start.value = 1
    await RisingEdge(dut.clk)
    dut.start.value = 0
    
    # Wait for done
    timeout = 100
    while dut.done.value == 0 and timeout > 0:
        await RisingEdge(dut.clk)
        timeout -= 1
    
    assert dut.done.value == 1, "Scaling did not complete"
    
    observed = unpack_vector(dut.V_out.value.integer, lane_width_out)
    expected = [min(15, (val << 8) // norm) for val in vec]
    assert observed == expected, f"Expected {expected}, got {observed}"
    
    print("✓ vector_scale test passed")

