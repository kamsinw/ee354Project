import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

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
    
    # Set up 4x4 identity matrix and vector [1,2,3,4]
    # Matrix: row-major, packed as A[255:0] = {A33, A32, A31, A30, ..., A00}
    # Identity matrix: A00=1, A11=1, A22=1, A33=1, others=0
    A = 0
    A |= (1 << 0)   # A00
    A |= (1 << 80)  # A11
    A |= (1 << 160) # A22
    A |= (1 << 240) # A33
    
    V = (4 << 48) | (3 << 32) | (2 << 16) | 1  # [4,3,2,1]
    
    dut.A.value = A
    dut.V.value = V
    
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
    
    # Check result: Y should be [1,2,3,4] for identity matrix
    Y_val = dut.Y.value.integer
    y0 = (Y_val >> 0) & 0xFFFF
    y1 = (Y_val >> 16) & 0xFFFF
    y2 = (Y_val >> 32) & 0xFFFF
    y3 = (Y_val >> 48) & 0xFFFF
    
    # Sign extend
    if y0 & 0x8000:
        y0 = y0 - 0x10000
    if y1 & 0x8000:
        y1 = y1 - 0x10000
    if y2 & 0x8000:
        y2 = y2 - 0x10000
    if y3 & 0x8000:
        y3 = y3 - 0x10000
    
    assert y0 == 1 and y1 == 2 and y2 == 3 and y3 == 4, f"Expected [1,2,3,4], got [{y0},{y1},{y2},{y3}]"
    
    print("✓ matrix_vector_mult test passed")

