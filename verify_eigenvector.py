#!/usr/bin/env python3
"""
Monte-Carlo verification for the 4-bit unsigned dominant eigenvector flow.
Generates random matrices/vectors in the 0..15 range, runs a software model
of the hardware algorithm, and compares it against a floating-point reference.
"""

from __future__ import annotations

import numpy as np

# -----------------------------
# Configuration / constants
# -----------------------------
NIBBLE_MAX = 15
OUT_WIDTH = 12
ACC_MAX = (1 << OUT_WIDTH) - 1
SHIFT_BITS = 8  # matches vector_scale.v SCALE_SHIFT
NUM_TESTS = 10
MAX_ITERS = 64
SEED = 314159

np.random.seed(SEED)


def float_power_iteration(A: np.ndarray, v0: np.ndarray, tol: float = 1e-6, max_iters: int = 256) -> np.ndarray:
    """Floating-point power iteration with L2 normalization."""
    v = v0.astype(np.float64)
    if np.linalg.norm(v) == 0:
        v = np.ones_like(v, dtype=np.float64)
    for _ in range(max_iters):
        y = A @ v
        norm = np.linalg.norm(y)
        if norm == 0:
            break
        v_new = y / norm
        if np.linalg.norm(v_new - v) < tol:
            return v_new
        v = v_new
    return v


def quantize_vector(vec: np.ndarray) -> np.ndarray:
    """Map a floating vector to 4-bit unsigned values by scaling the max to 15."""
    vec = np.abs(vec)
    max_val = np.max(vec)
    if max_val == 0:
        return np.zeros_like(vec, dtype=np.int32)
    scaled = np.round((vec / max_val) * NIBBLE_MAX)
    return np.clip(scaled.astype(np.int32), 0, NIBBLE_MAX)


def hardware_iteration(A: np.ndarray, v_init: np.ndarray) -> tuple[np.ndarray, int]:
    """Software replica of the RTL flow (4-bit unsigned math)."""
    v = v_init.astype(np.int32)
    if not np.any(v):
        v[0] = 1  # avoid zero vector
    for iteration in range(1, MAX_ITERS + 1):
        # Matrix-vector multiply with saturation to 4 bits
        y = A @ v
        y = np.clip(y, 0, ACC_MAX)

        # L2 norm (integer sqrt)
        norm_sq = int(np.sum(y.astype(np.int32) ** 2))
        norm = int(np.floor(np.sqrt(norm_sq)))
        if norm == 0:
            norm = 1

        # Scale numerator by 2^SHIFT_BITS before dividing
        y_shifted = y.astype(np.int32) << SHIFT_BITS
        v_new = np.clip(y_shifted // norm, 0, NIBBLE_MAX)

        if np.array_equal(v_new, v):
            return v_new.astype(np.int32), iteration
        v = v_new
    return v.astype(np.int32), MAX_ITERS


def run_single_test(test_id: int) -> dict:
    """Generate one random matrix/vector and run both models."""
    A = np.random.randint(0, NIBBLE_MAX + 1, size=(4, 4), dtype=np.int32)
    v0 = np.random.randint(0, NIBBLE_MAX + 1, size=4, dtype=np.int32)
    if not np.any(v0):
        v0[0] = 1

    hw_vec, hw_iters = hardware_iteration(A, v0)
    float_vec = float_power_iteration(A.astype(np.float64), v0.astype(np.float64))
    ref_vec = quantize_vector(float_vec)

    match = np.array_equal(hw_vec, ref_vec)

    return {
        "id": test_id,
        "matrix": A,
        "vector_init": v0,
        "hw_vec": hw_vec,
        "hw_iters": hw_iters,
        "ref_vec": ref_vec,
        "match": match,
    }


def main() -> None:
    print("=" * 80)
    print("Dominant Eigenvector Monte-Carlo (4-bit Unsigned Model)")
    print(f"Tests: {NUM_TESTS}, RNG seed: {SEED}, SHIFT_BITS={SHIFT_BITS}")
    print("=" * 80)

    results = [run_single_test(i + 1) for i in range(NUM_TESTS)]
    matches = sum(1 for r in results if r["match"])

    for res in results:
        print("-" * 80)
        print(f"Test #{res['id']}")
        print("Matrix A (0..15):")
        print(res["matrix"])
        print(f"Initial v0: {res['vector_init']}")
        print(f"Hardware vector   : {res['hw_vec']}  (iters={res['hw_iters']})")
        print(f"Reference vector  : {res['ref_vec']}")
        print(f"Match             : {'YES' if res['match'] else 'NO'}")

    print("=" * 80)
    print(f"Summary: {matches}/{NUM_TESTS} tests matched the float reference after quantization.")
    if matches == NUM_TESTS:
        print("All tests passed ✅")
    else:
        print("Discrepancies detected ❌ — review matrices above.")


if __name__ == "__main__":
    main()
