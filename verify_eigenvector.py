#!/usr/bin/env python3
"""
Verify the dominant eigenvector computation by comparing hardware results
with Python/numpy reference implementation.
"""

import numpy as np

# Test matrix from the testbench
# Matrix A: [4,1,1,1; 1,4,1,1; 1,1,4,1; 1,1,1,4]
A = np.array([
    [4, 1, 1, 1],
    [1, 4, 1, 1],
    [1, 1, 4, 1],
    [1, 1, 1, 4]
], dtype=np.float64)

print("=" * 60)
print("Eigenvector Verification using NumPy")
print("=" * 60)
print(f"\nMatrix A:")
print(A)
print()

# ========================================
# Method 1: NumPy's eig function (analytical)
# ========================================
print("=" * 60)
print("Method 1: NumPy eig() - Analytical Solution")
print("=" * 60)
eigenvalues, eigenvectors = np.linalg.eig(A)

# Find the dominant eigenvalue (largest absolute value)
dominant_idx = np.argmax(np.abs(eigenvalues))
dominant_eigenvalue = eigenvalues[dominant_idx]
dominant_eigenvector = eigenvectors[:, dominant_idx]

print(f"All eigenvalues: {eigenvalues}")
print(f"Dominant eigenvalue: {dominant_eigenvalue:.6f}")
print(f"Dominant eigenvector (complex): {dominant_eigenvector}")
print()

# Normalize the eigenvector (make it real and unit length)
# Since the matrix is symmetric, eigenvalues and eigenvectors should be real
dominant_eigenvector_real = np.real(dominant_eigenvector)
dominant_eigenvector_unit = dominant_eigenvector_real / np.linalg.norm(dominant_eigenvector_real)

print(f"Dominant eigenvector (unit normalized): {dominant_eigenvector_unit}")
print()

# Normalize by max absolute value (like the hardware does)
max_abs = np.max(np.abs(dominant_eigenvector_real))
dominant_eigenvector_max_norm = dominant_eigenvector_real / max_abs

print(f"Dominant eigenvector (max-normalized): {dominant_eigenvector_max_norm}")
print()

# Convert to Q2.14 fixed-point format (hardware format)
# In Q2.14: value * 16384 represents the fixed-point number
q2_14_scale = 16384
numpy_result = (dominant_eigenvector_max_norm * q2_14_scale).astype(np.int32)

print(f"NumPy result (Q2.14, max-normalized): {numpy_result}")
print(f"  As 16-bit signed integers: {numpy_result.astype(np.int16)}")
print()

# ========================================
# Method 2: Power iteration (hardware algorithm)
# ========================================
print("=" * 60)
print("Method 2: Power Iteration (Hardware Algorithm)")
print("=" * 60)
v = np.array([1.0, 1.0, 1.0, 1.0])  # Initial vector
epsilon = 2.0  # Convergence threshold (in hardware Q2.14 units)
max_iterations = 100

print(f"Initial vector: {v}")
print(f"Epsilon threshold: {epsilon} (in Q2.14 units)")
print(f"Q2.14 scale factor: {q2_14_scale}")
print()

for i in range(max_iterations):
    # Matrix-vector multiply: y = A * v
    y = A @ v
    
    # Find max absolute value
    max_val = np.max(np.abs(y))
    
    # Normalize by max (like hardware): v_new = y / max_val
    v_new = y / max_val
    
    # Compute difference
    diff = np.abs(v_new - v)
    max_diff = np.max(diff)
    
    # Convert to hardware units (Q2.14)
    v_new_hw = (v_new * q2_14_scale).astype(np.int16)
    max_diff_hw = (max_diff * q2_14_scale).astype(np.int16)
    
    if i < 3 or max_diff_hw <= epsilon:
        print(f"Iteration {i+1}:")
        print(f"  y = {y}")
        print(f"  max_val = {max_val:.6f}")
        print(f"  v_new = {v_new}")
        print(f"  v_new (Q2.14) = {v_new_hw}")
        print(f"  max_diff (Q2.14) = {max_diff_hw}")
        print()
    
    # Check convergence
    if max_diff_hw <= epsilon:
        print(f"✓ Converged after {i+1} iterations!")
        print(f"  Final vector (Q2.14): {v_new_hw}")
        print(f"  Final max_diff (Q2.14): {max_diff_hw}")
        break
    
    v = v_new
else:
    print(f"✗ Did not converge after {max_iterations} iterations")

power_iteration_result = v_new_hw

# ========================================
# Comparison with Hardware Result
# ========================================
print()
print("=" * 60)
print("Comparison with Hardware Result")
print("=" * 60)

# Hardware result from the test
hardware_result = np.array([16384, 16384, 16384, 16384], dtype=np.int16)

print(f"Hardware result:        {hardware_result}")
print(f"NumPy eig() result:     {numpy_result.astype(np.int16)}")
print(f"Power iteration result: {power_iteration_result}")
print()

# Check if they match
numpy_match = np.allclose(hardware_result, numpy_result.astype(np.int16), atol=1)
power_match = np.allclose(hardware_result, power_iteration_result, atol=1)

if numpy_match:
    print("✓ MATCH with NumPy eig(): Hardware result matches analytical solution!")
else:
    print("✗ MISMATCH with NumPy eig(): Hardware result differs")
    diff = np.abs(hardware_result.astype(np.int32) - numpy_result.astype(np.int32))
    print(f"  Differences: {diff}")
    print(f"  Max difference: {np.max(diff)}")

if power_match:
    print("✓ MATCH with Power Iteration: Hardware result matches power iteration!")
else:
    print("✗ MISMATCH with Power Iteration: Hardware result differs")
    diff = np.abs(hardware_result.astype(np.int32) - power_iteration_result.astype(np.int32))
    print(f"  Differences: {diff}")
    print(f"  Max difference: {np.max(diff)}")
print()

# Show what the values represent
print("Value interpretation (Q2.14 format):")
print(f"  Hardware: {hardware_result} represents {hardware_result / q2_14_scale}")
print(f"  NumPy:    {numpy_result.astype(np.int16)} represents {numpy_result / q2_14_scale}")
print(f"  Power:    {power_iteration_result} represents {power_iteration_result / q2_14_scale}")
print()

# ========================================
# Summary
# ========================================
print("=" * 60)
print("Summary")
print("=" * 60)
print(f"Matrix: A = [4,1,1,1; 1,4,1,1; 1,1,4,1; 1,1,1,4]")
print(f"Expected eigenvector (max-normalized): {dominant_eigenvector_max_norm}")
print(f"Expected in Q2.14 format: {numpy_result.astype(np.int16)}")
print(f"Hardware result: {hardware_result}")
print()

if numpy_match and power_match:
    print("✓ VERIFICATION PASSED: Hardware computes correct eigenvector!")
    print("  Both NumPy eig() and power iteration agree with hardware result.")
else:
    print("✗ VERIFICATION FAILED: Hardware result differs from reference")
    if not numpy_match:
        print("  - NumPy eig() mismatch")
    if not power_match:
        print("  - Power iteration mismatch")
