import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge

def pack_matrix(matrix):
    packed = 0
    for row in range(4):
        for col in range(4):
            idx = 4 * row + col
            packed |= (matrix[row][col] & 0xF) << (4 * idx)
    return packed


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
async def test_matrix_vector_mult(dut):
    """Test matrix_vector_mult module"""
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    # Reset
    dut.reset.value = 1
    dut.start.value = 0
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.reset.value = 0
    
    vec_lane_width = len(dut.V.value) // 4
    out_lane_width = len(dut.Y.value) // 4
    
    identity = [
        [1, 0, 0, 0],
        [0, 1, 0, 0],
        [0, 0, 1, 0],
        [0, 0, 0, 1],
    ]
    vec = [1, 2, 3, 4]
    
    dut.A.value = pack_matrix(identity)
    dut.V.value = pack_vector(vec, vec_lane_width)
    
    # Start multiplication
    dut.start.value = 1
    await RisingEdge(dut.clk)
    dut.start.value = 0
    
    # Wait for done
    timeout = 100
    while dut.done.value == 0 and timeout > 0:
        await RisingEdge(dut.clk)
        timeout -= 1
    
    assert dut.done.value == 1, "Multiplication did not complete"
    
    observed = unpack_vector(dut.Y.value.integer, out_lane_width)
    assert observed == vec, f"Expected {vec}, got {observed}"
    
    print("✓ matrix_vector_mult test passed")

