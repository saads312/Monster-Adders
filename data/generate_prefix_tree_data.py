#!/usr/bin/env python3
"""Generate test data for prefix tree testbench"""

import random
import os

def compute_prefix_tree(g, p, width):
    """
    Compute carry outputs using Sklansky prefix tree algorithm

    Args:
        g: Generate bits (list or int)
        p: Propagate bits (list or int)
        width: Bit width

    Returns:
        c: Carry bits (list)
    """
    # Convert to lists if integers
    if isinstance(g, int):
        g = [(g >> i) & 1 for i in range(width)]
    if isinstance(p, int):
        p = [(p >> i) & 1 for i in range(width)]

    # Make copies for computation
    g_curr = g[:]
    p_curr = p[:]

    # Sklansky prefix tree stages
    stages = 0
    temp = width
    while temp > 1:
        temp = (temp + 1) // 2
        stages += 1

    for stage in range(stages):
        g_next = g_curr[:]
        p_next = p_curr[:]

        for j in range(width):
            if j & (2**stage):
                src_idx = (j & ~((2**stage) - 1)) - 1
                if src_idx >= 0:
                    g_next[j] = g_curr[j] | (p_curr[j] & g_curr[src_idx])
                    p_next[j] = p_curr[j] & p_curr[src_idx]

        g_curr = g_next
        p_curr = p_next

    return g_curr

def generate_test_data(num_tests=8, width=32, output_dir=".", corner_cases=True):
    """
    Generate test vectors for prefix tree

    Args:
        num_tests: Number of test cases
        width: Bit width of operands
        output_dir: Directory to write output hex files
        corner_cases: If True, include corner case tests
    """

    os.makedirs(output_dir, exist_ok=True)

    g_vals = []
    p_vals = []
    c_vals = []

    # Add corner cases first
    if corner_cases and num_tests >= 4:
        test_cases = [
            (0, 0),                           # All zeros
            ((1 << width) - 1, (1 << width) - 1),  # All ones
            ((1 << width) - 1, 0),            # All g, no p
            (0, (1 << width) - 1),            # All p, no g
        ]

        for g, p in test_cases[:min(4, num_tests)]:
            c = compute_prefix_tree(g, p, width)
            c_int = sum(c[i] << i for i in range(width))

            g_vals.append(g)
            p_vals.append(p)
            c_vals.append(c_int)

        num_tests -= len(test_cases[:min(4, num_tests)])

    # Generate random test cases
    for _ in range(num_tests):
        g = random.randint(0, (1 << width) - 1)
        p = random.randint(0, (1 << width) - 1)

        c = compute_prefix_tree(g, p, width)
        c_int = sum(c[i] << i for i in range(width))

        g_vals.append(g)
        p_vals.append(p)
        c_vals.append(c_int)

    # Write hex files
    def write_hex(filename, values):
        path = os.path.join(output_dir, filename)
        with open(path, 'w') as f:
            for val in values:
                f.write(f'{val:x}\n')

    write_hex('g.hex', g_vals)
    write_hex('p.hex', p_vals)
    write_hex('c.hex', c_vals)

    # Print summary
    total_tests = len(g_vals)
    print(f"Generated {total_tests} test vectors ({width}-bit)")
    print(f"Files written to: {os.path.abspath(output_dir)}")
    print(f"Pipeline stages: {width.bit_length() - 1}")
    print("\nSample test cases:")
    for i in range(min(3, total_tests)):
        print(f"  Test {i}:")
        print(f"    g = 0x{g_vals[i]:0{(width+3)//4}x}")
        print(f"    p = 0x{p_vals[i]:0{(width+3)//4}x}")
        print(f"    c = 0x{c_vals[i]:0{(width+3)//4}x}")

def export_defines(args):
    """Generate tb/top.h header file with test configuration"""
    os.makedirs(args.header, exist_ok=True)
    header_path = os.path.join(args.header, "top.h")

    with open(header_path, "w") as f:
        f.write(f"`define TESTS {args.num_tests}\n")

    print(f"Header file written to: {header_path}")

if __name__ == '__main__':
    import argparse

    parser = argparse.ArgumentParser(description='Generate prefix tree test data')
    parser.add_argument('-n', '--num-tests', type=int, default=16,
                        help='Number of test cases (default: 16)')
    parser.add_argument('-w', '--width', type=int, default=32,
                        help='Bit width (default: 32)')
    parser.add_argument('--no-corner-cases', action='store_true',
                        help='Skip corner case generation')
    parser.add_argument('-o', '--output', type=str, default='data/',
                        help='Output directory (default: data/)')
    parser.add_argument('-r', '--header', type=str, default='tb/',
                        help='Output directory for top.h header file (default: tb/)')

    args = parser.parse_args()

    generate_test_data(
        args.num_tests,
        args.width,
        args.output,
        corner_cases=not args.no_corner_cases
    )

    export_defines(args)
