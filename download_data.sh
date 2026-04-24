#!/usr/bin/env bash
# ============================================================
# download_data.sh
# Download RNA-seq FASTQ files from SRA / ENA
# Project: RNAseq Analysis Pipeline
# ============================================================

set -euo pipefail

# ── Configuration ────────────────────────────────────────────
OUTDIR="data/raw"
LOG="results/logs/download_data.log"
THREADS=4

# SRA accessions (GSE183947 — Human airway smooth muscle cells)
# 3 control + 3 treated samples
SAMPLES=(
  SRR8983579   # Control_rep1
  SRR8983580   # Control_rep2
  SRR8983581   # Control_rep3
  SRR8983582   # Treated_rep1
  SRR8983583   # Treated_rep2
  SRR8983584   # Treated_rep3
)

mkdir -p "$OUTDIR" "results/logs"

echo "[$(date '+%F %T')] Starting FASTQ download — ${#SAMPLES[@]} samples" | tee "$LOG"

# ── Dependency check ─────────────────────────────────────────
for tool in prefetch fasterq-dump pigz; do
  if ! command -v "$tool" &>/dev/null; then
    echo "ERROR: $tool not found. Install SRA-Toolkit (prefetch/fasterq-dump) and pigz." | tee -a "$LOG"
    exit 1
  fi
done

# ── Download loop ─────────────────────────────────────────────
for SRR in "${SAMPLES[@]}"; do
  echo "[$(date '+%F %T')] Downloading $SRR …" | tee -a "$LOG"

  # Prefetch SRA file
  prefetch --output-directory "$OUTDIR" "$SRR" 2>>"$LOG"

  # Dump to paired-end FASTQ
  fasterq-dump \
    --outdir "$OUTDIR" \
    --threads "$THREADS" \
    --split-files \
    --skip-technical \
    --progress \
    "$OUTDIR/$SRR/$SRR.sra" 2>>"$LOG"

  # Compress
  echo "[$(date '+%F %T')] Compressing $SRR …" | tee -a "$LOG"
  pigz -p "$THREADS" "$OUTDIR/${SRR}_1.fastq" "$OUTDIR/${SRR}_2.fastq"

  echo "[$(date '+%F %T')] $SRR done." | tee -a "$LOG"
done

echo "[$(date '+%F %T')] All downloads complete." | tee -a "$LOG"
ls -lh "$OUTDIR"/*.fastq.gz
