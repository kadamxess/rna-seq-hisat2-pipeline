#!/usr/bin/env bash
# ============================================================
# generate_star_idx.sh
# Build STAR genome index from GRCh38 FASTA + GTF
# Requires ~32 GB RAM and ~30 GB disk
# ============================================================

set -euo pipefail

# ── Configuration ────────────────────────────────────────────
GENOME_FA="data/ref/genome.fa"
GTF="data/ref/annotation.gtf"
STAR_IDX="data/index/star"
LOG="results/logs/star_index.log"
THREADS=8
READ_LEN=150          # set to (read_length - 1)
GENOMESA_SPARSE=14    # --genomeSAindexNbases; 14 for human

mkdir -p "$STAR_IDX" "results/logs"

# ── Dependency check ─────────────────────────────────────────
if ! command -v STAR &>/dev/null; then
  echo "ERROR: STAR not found. Install via conda: conda install -c bioconda star" >&2
  exit 1
fi

echo "[$(date '+%F %T')] Building STAR index (this takes ~30–60 min) …" | tee "$LOG"
echo "  Genome : $GENOME_FA" | tee -a "$LOG"
echo "  GTF    : $GTF"       | tee -a "$LOG"
echo "  Threads: $THREADS"   | tee -a "$LOG"

STAR \
  --runMode           genomeGenerate \
  --runThreadN        "$THREADS" \
  --genomeDir         "$STAR_IDX" \
  --genomeFastaFiles  "$GENOME_FA" \
  --sjdbGTFfile       "$GTF" \
  --sjdbOverhang      "$((READ_LEN - 1))" \
  --genomeSAindexNbases "$GENOMESA_SPARSE" \
  --outFileNamePrefix "${STAR_IDX}/" \
  2>&1 | tee -a "$LOG"

echo "[$(date '+%F %T')] STAR index generation complete." | tee -a "$LOG"
ls -lh "$STAR_IDX"
