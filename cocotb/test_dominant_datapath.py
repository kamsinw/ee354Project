import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

@cocotb.test()
async def test_dominant_datapath(dut):
    """Test dominant_datapath module"""
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    # Reset
    dut.reset.value = 1
    dut.load_v_old.value = 0
    dut.load_y.value = 0
    dut.load_max_d.value = 0
    dut.start_mult.value = 0
    dut.start_scale.value = 0
    dut.start_diff.value = 0
    
    # Set up identity matrix
    dut.A00.value = 1
    dut.A01.value = 0
    dut.A02.value = 0
    dut.A03.value = 0
    dut.A10.value = 0
    dut.A11.value = 1
    dut.A12.value = 0
    dut.A13.value = 0
    dut.A20.value = 0
    dut.A21.value = 0
    dut.A22.value = 1
    dut.A23.value = 0
    dut.A30.value = 0
    dut.A31.value = 0
    dut.A32.value = 0
    dut.A33.value = 1
    
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.reset.value = 0
    
    # Initial vector should be [1,1,1,1] after reset
    await RisingEdge(dut.clk)
    v0 = dut.v0.value.signed_integer
    v1 = dut.v1.value.signed_integer
    v2 = dut.v2.value.signed_integer
    v3 = dut.v3.value.signed_integer
    
    # Start matrix-vector multiply
    dut.start_mult.value = 1
    await RisingEdge(dut.clk)
    dut.start_mult.value = 0
    
    # Wait for mul_done
    timeout = 100
    while dut.mul_done.value == 0 and timeout > 0:
        await RisingEdge(dut.clk)
        timeout -= 1
    
    assert dut.mul_done.value == 1, "Matrix multiply did not complete"
    
    # Load y
    dut.load_y.value = 1
    await RisingEdge(dut.clk)
    dut.load_y.value = 0
    
    # Start scaling
    dut.start_scale.value = 1
    await RisingEdge(dut.clk)
    dut.start_scale.value = 0
    
    # Wait for scale_done
    timeout = 100
    while dut.scale_done.value == 0 and timeout > 0:
        await RisingEdge(dut.clk)
        timeout -= 1
    
    assert dut.scale_done.value == 1, "Scaling did not complete"
    
    # Start diff
    dut.start_diff.value = 1
    await RisingEdge(dut.clk)
    dut.start_diff.value = 0
    
    # Wait for diff_done
    timeout = 100
    while dut.diff_done.value == 0 and timeout > 0:
        await RisingEdge(dut.clk)
        timeout -= 1
    
    assert dut.diff_done.value == 1, "Difference calculation did not complete"
    
    print("✓ dominant_datapath test passed")

