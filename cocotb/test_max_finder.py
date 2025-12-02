import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge


def pack_vector(vec):
    packed = 0
    for idx, val in enumerate(vec):
        packed |= (val & 0xF) << (4 * idx)
    return packed


@cocotb.test()
async def test_max_finder(dut):
    """Test max_finder module"""
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    dut.reset.value = 1
    await RisingEdge(dut.clk)
    dut.reset.value = 0
    await RisingEdge(dut.clk)
    
    test_vectors = [
        [1, 2, 3, 4],
        [15, 0, 7, 3],
        [2, 2, 2, 2],
        [9, 12, 4, 11],
    ]
    
    for vec in test_vectors:
        dut.a.value = pack_vector(vec)
        await RisingEdge(dut.clk)
        await RisingEdge(dut.clk)
        assert dut.max_val.value.integer == max(vec), f"Expected {max(vec)}, got {dut.max_val.value.integer}"
    
    print("✓ max_finder test passed")

