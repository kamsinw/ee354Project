import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer


def power_iteration_q214(matrix, iterations=32):
    """Reference power iteration that matches hardware normalization."""
    vec = [1.0, 1.0, 1.0, 1.0]
    for _ in range(iterations):
        y = [
            sum(matrix[row][col] * vec[col] for col in range(4))
            for row in range(4)
        ]
        max_abs = max(abs(val) for val in y)
        if max_abs == 0:
            break
        vec = [val / max_abs for val in y]
    scale = 16384  # Q2.14 conversion factor
    return [int(round(val * scale)) for val in vec]

@cocotb.test()
async def test_dominant_full(dut):
    """Test full dominant eigenvector system"""
    # Create clock
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    # Reset
    dut.reset.value = 1
    dut.start.value = 0
    dut.epsilon.value = 2
    
    # Set up test matrix: [4,1,1,1; 1,4,1,1; 1,1,4,1; 1,1,1,4]
    dut.A00.value = 4
    dut.A01.value = 1
    dut.A02.value = 1
    dut.A03.value = 1
    dut.A10.value = 1
    dut.A11.value = 4
    dut.A12.value = 1
    dut.A13.value = 1
    dut.A20.value = 1
    dut.A21.value = 1
    dut.A22.value = 4
    dut.A23.value = 1
    dut.A30.value = 1
    dut.A31.value = 1
    dut.A32.value = 1
    dut.A33.value = 4
    
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.reset.value = 0
    
    # Start computation
    dut.start.value = 1
    await RisingEdge(dut.clk)
    dut.start.value = 0
    
    # Wait for convergence (done signal) - use event-driven wait instead of polling
    iterations = 0
    timeout_cycles = 1000  # Reasonable limit
    converged = False
    
    # Wait for done signal with timeout
    for _ in range(timeout_cycles):
        await RisingEdge(dut.clk)
        iterations += 1
        if dut.done.value == 1:
            converged = True
            break
    
    assert converged, f"Computation did not converge after {iterations} cycles"
    
    # Check that vector has converged (all elements should be approximately equal)
    v0 = dut.v0.value.signed_integer
    v1 = dut.v1.value.signed_integer
    v2 = dut.v2.value.signed_integer
    v3 = dut.v3.value.signed_integer
    
    # For the test matrix, eigenvector should be [1,1,1,1] (normalized)
    # Allow some tolerance due to fixed-point arithmetic
    max_diff = max(abs(v0 - v1), abs(v0 - v2), abs(v0 - v3), 
                   abs(v1 - v2), abs(v1 - v3), abs(v2 - v3))
    
    # Elements should be close to each other (within reasonable tolerance)
    assert max_diff < 1000, f"Vector elements differ too much: [{v0},{v1},{v2},{v3}], max_diff={max_diff}"
    
    print(f"✓ Full system test passed after {iterations} cycles")
    print(f"  Final vector: [{v0}, {v1}, {v2}, {v3}]")
    print(f"  max_diff: {max_diff}")


@cocotb.test()
async def test_dominant_full_asymmetric(dut):
    """Ensure asymmetric matrices propagate correctly through the full system."""
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())

    dut.reset.value = 1
    dut.start.value = 0
    dut.epsilon.value = 2

    matrix = [
        [5, 2, 0, 1],
        [1, 4, -1, 0],
        [0, 3, 6, -2],
        [2, 0, -2, 5],
    ]

    dut.A00.value = matrix[0][0]
    dut.A01.value = matrix[0][1]
    dut.A02.value = matrix[0][2]
    dut.A03.value = matrix[0][3]
    dut.A10.value = matrix[1][0]
    dut.A11.value = matrix[1][1]
    dut.A12.value = matrix[1][2]
    dut.A13.value = matrix[1][3]
    dut.A20.value = matrix[2][0]
    dut.A21.value = matrix[2][1]
    dut.A22.value = matrix[2][2]
    dut.A23.value = matrix[2][3]
    dut.A30.value = matrix[3][0]
    dut.A31.value = matrix[3][1]
    dut.A32.value = matrix[3][2]
    dut.A33.value = matrix[3][3]

    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.reset.value = 0

    dut.start.value = 1
    await RisingEdge(dut.clk)
    dut.start.value = 0

    iterations = 0
    timeout_cycles = 2000
    while dut.done.value == 0 and iterations < timeout_cycles:
        await RisingEdge(dut.clk)
        iterations += 1

    assert dut.done.value == 1, "Asymmetric matrix did not converge"

    hw_vector = [
        dut.v0.value.signed_integer,
        dut.v1.value.signed_integer,
        dut.v2.value.signed_integer,
        dut.v3.value.signed_integer,
    ]

    ref_vector = power_iteration_q214(matrix, iterations=40)
    tolerance = 200  # Allow headroom for fixed-point effects

    for idx, (hw, ref) in enumerate(zip(hw_vector, ref_vector)):
        assert abs(hw - ref) <= tolerance, (
            f"Vector element {idx} mismatch: hw={hw}, ref={ref}, "
            f"diff={abs(hw - ref)}"
        )

    print(f"✓ Asymmetric matrix converged in {iterations} cycles")
    print(f"  Hardware vector: {hw_vector}")
    print(f"  Reference vector: {ref_vector}")
