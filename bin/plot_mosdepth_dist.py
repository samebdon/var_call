#!/usr/bin/env python3

import argparse
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import seaborn as sns

#Based on a script written by Dominik Laetsch.

def parse_args():
    parser = argparse.ArgumentParser(
        description="Plot cumulative mosdepth coverage distributions per sample."
    )
    parser.add_argument(
        "--dir",
        required=True,
        help="Directory containing *.mosdepth.global.dist.txt files",
    )
    parser.add_argument(
        "--prefix",
        required=True,
        help="Output prefix",
    )
    parser.add_argument(
        "--min",
        dest="min_cov",
        type=int,
        required=True,
        help="Minimum acceptable coverage",
    )
    parser.add_argument(
        "--max",
        dest="max_cov",
        type=int,
        required=True,
        help="Maximum coverage to plot",
    )
    parser.add_argument(
        "--minf",
        dest="min_fraction",
        type=float,
        required=True,
        help="Minimum acceptable genome fraction",
    )
    return parser.parse_args()


def parse_distros(directory: Path, max_cov: int):
    fraction_by_dataset = {}
    dist_files = sorted(directory.glob("*.mosdepth.global.dist.txt"))
    if not dist_files:
        raise SystemExit(f"No '*.mosdepth.global.dist.txt' files found in {directory}")

    for dist_f in dist_files:
        dataset_id = dist_f.name.replace(".mosdepth.global.dist.txt", "")
        df = pd.read_csv(dist_f, sep="\t", names=["region", "depth", "fraction"])
        total_df = df[df["region"] == "total"]
        plot_df = total_df[total_df["depth"] <= max_cov]
        fraction = np.array(plot_df["fraction"], dtype=float)
        fraction_by_dataset[dataset_id] = np.pad(
            fraction,
            [max_cov - len(plot_df) + 1, 0],
        )
    return fraction_by_dataset


def plot_distros(fraction_by_dataset, min_cov: int, max_cov: int, min_fraction: float, prefix: str):
    sns.set_style("white")
    sns.set_style("ticks")
    sns.set_context("notebook")

    fig, ax = plt.subplots(figsize=(14, 5))
    x = np.arange(max_cov, -1, -1)
    sns.despine()

    for dataset, fraction in fraction_by_dataset.items():
        ax.plot(x, fraction, label=dataset, alpha=0.9, linestyle="-")

    ax.set_ylabel("Proportion of genome covered")
    ax.set_xlabel("Reads")
    ax.grid(True)
    ax.axvline(min_cov, color="grey", lw=1)
    ax.text(min_cov + 1, 0.1, f"Min depth={min_cov}", color="grey")
    ax.axhline(min_fraction, 0, max_cov, color="grey", lw=1)
    ax.text(max_cov * 0.8, min_fraction + 0.01, f"Min fraction={min_fraction}", color="grey")
    ax.set_ylim((0, 1))

    legend = ax.legend(fontsize=8, ncol=1)
    legend.get_frame().set_linewidth(0.0)

    out_f = f"{prefix}.global.distro.png"
    fig.savefig(out_f, format="png", dpi=200, bbox_inches="tight")


def main():
    args = parse_args()
    fraction_by_dataset = parse_distros(Path(args.dir), args.max_cov)
    plot_distros(
        fraction_by_dataset,
        args.min_cov,
        args.max_cov,
        args.min_fraction,
        args.prefix,
    )


if __name__ == "__main__":
    main()
