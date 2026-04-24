#!/usr/bin/env bash
# ============================================================
# featurecounts.sh
# Gene-level read counting with Subread featureCounts
# Output: raw count matrix (genes × samples)
# ============================================================

set -euo pipefail

# ── Configuration ────────────────────────────────────────────
BAM_DIR="results/processed_bam"
GTF="data/ref/annotation.gtf"
OUTDIR="results/counts"
LOG="results/logs/featurecounts.log"
THREADS=8

# featureCounts options
STRANDNESS=2      # 0=unstranded 1=sense 2=antisense (dUTP → 2)
MIN_MAPQ=10       # minimum mapping quality
FEATURE="exon"    # GTF feature type
ATTR="gene_id"    # attribute for grouping

mkdir -p "$OUTDIR" "results/logs"

# ── Dependency check ─────────────────────────────────────────
if ! command -v featureCounts &>/dev/null; then
  echo "ERROR: featureCounts not found." >&2
  echo "Install: conda install -c bioconda subread" >&2
  exit 1
fi

# ── Collect BAMs ──────────────────────────────────────────────
mapfile -t BAMS < <(find "$BAM_DIR" -name "*_dedup.bam" | sort)

[[ ${#BAMS[@]} -eq 0 ]] && \
  { echo "ERROR: No deduplicated BAMs found in $BAM_DIR" >&2; exit 1; }

echo "[$(date '+%F %T')] featureCounts on ${#BAMS[@]} BAM(s)" | tee "$LOG"
printf "  %s\n" "${BAMS[@]}" | tee -a "$LOG"

# ── Run featureCounts ─────────────────────────────────────────
featureCounts \
  -a "$GTF" \
  -o "${OUTDIR}/counts_raw.txt" \
  -T "$THREADS" \
  -s "$STRANDNESS" \
  -Q "$MIN_MAPQ" \
  -t "$FEATURE" \
  -g "$ATTR" \
  -p \
  --countReadPairs \
  -B \
  -C \
  --extraAttributes "gene_name,gene_biotype" \
  "${BAMS[@]}" \
  2>&1 | tee -a "$LOG"

# ── Clean up column headers ───────────────────────────────────
echo "[$(date '+%F %T')] Cleaning count matrix headers …" | tee -a "$LOG"

python3 - <<'EOF'
import pandas as pd, re, sys

df = pd.read_csv("results/counts/counts_raw.txt", sep="\t", comment="#")

# Rename BAM columns → sample names
df.columns = [
    re.sub(r".*/(.+?)_dedup\.bam", r"\1", c) if c.endswith(".bam") else c
    for c in df.columns
]

# Split into count matrix and annotation
ann_cols  = ["Geneid", "gene_name", "gene_biotype", "Chr", "Start", "End", "Strand", "Length"]
keep_ann  = [c for c in ann_cols if c in df.columns]
keep_cnt  = [c for c in df.columns if c not in ann_cols]

df[keep_ann + keep_cnt].to_csv("results/counts/counts_matrix.tsv", sep="\t", index=False)
print(f"Count matrix saved: {df.shape[0]} genes × {len(keep_cnt)} samples")
EOF

echo "[$(date '+%F %T')] featureCounts complete." | tee -a "$LOG"
echo "Matrix: ${OUTDIR}/counts_matrix.tsv"
head -3 "${OUTDIR}/counts_matrix.tsv"
