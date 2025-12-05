import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge


NIBBLE_MAX = 15
OUT_WIDTH = 12
ACC_MAX = (1 << OUT_WIDTH) - 1
SHIFT_BITS = 8


def power_iteration_hw_model(matrix, iterations=32, shift_bits=SHIFT_BITS):
    """Reference power iteration matching the 4-bit hardware scaling."""
    vec = [1, 1, 1, 1]
    for _ in range(iterations):
        y = [
            min(ACC_MAX, max(0, sum(matrix[row][col] * vec[col] for col in range(4))))
            for row in range(4)
        ]
        norm_sq = sum(val * val for val in y)
        norm = int(norm_sq ** 0.5)
        if norm == 0:
            break
        next_vec = [min(NIBBLE_MAX, (val << shift_bits) // norm) for val in y]
        if next_vec == vec:
            return next_vec
        vec = next_vec
    return vec

@cocotb.test()
async def test_dominant_full(dut):
    """Test full dominant eigenvector system"""
    # Create clock
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    # Reset
    dut.reset.value = 1
    dut.start.value = 0
    dut.epsilon.value = 0
    
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
    
    hw_vector = [
        dut.v0.value.integer,
        dut.v1.value.integer,
        dut.v2.value.integer,
        dut.v3.value.integer,
    ]
    ref_vector = power_iteration_hw_model(
        [[4, 1, 1, 1],
         [1, 4, 1, 1],
         [1, 1, 4, 1],
         [1, 1, 1, 4]]
    )
    assert hw_vector == ref_vector, f"Mismatch: hw={hw_vector}, ref={ref_vector}"
    
    print(f"✓ Full system test passed after {iterations} cycles")
    print(f"  Final vector: {hw_vector}")


@cocotb.test()
async def test_dominant_full_asymmetric(dut):
    """Ensure asymmetric matrices propagate correctly through the full system."""
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())

    dut.reset.value = 1
    dut.start.value = 0
    dut.epsilon.value = 0

    matrix = [
        [5, 2, 0, 1],
        [1, 4, 1, 0],
        [0, 3, 6, 2],
        [2, 0, 2, 5],
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
        dut.v0.value.integer,
        dut.v1.value.integer,
        dut.v2.value.integer,
        dut.v3.value.integer,
    ]
    
    ref_vector = power_iteration_hw_model(matrix, iterations=40)
    assert hw_vector == ref_vector, f"Mismatch: hw={hw_vector}, ref={ref_vector}"
    
    print(f"✓ Asymmetric matrix converged in {iterations} cycles")
    print(f"  Hardware vector: {hw_vector}")
