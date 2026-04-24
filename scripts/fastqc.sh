#!/usr/bin/env bash
# ============================================================
# fastqc.sh
# Run FastQC on all raw FASTQ files + MultiQC summary
# ============================================================

set -euo pipefail

# ── Configuration ────────────────────────────────────────────
RAW_DIR="data/raw"
OUTDIR="results/fastqc"
LOG="results/logs/fastqc.log"
THREADS=4
ADAPTERS=""          # optional: path to adapter FASTA for trimming check

mkdir -p "$OUTDIR" "results/logs"

# ── Dependency check ─────────────────────────────────────────
for tool in fastqc multiqc; do
  if ! command -v "$tool" &>/dev/null; then
    echo "ERROR: $tool not found." >&2
    echo "Install: conda install -c bioconda fastqc multiqc" >&2
    exit 1
  fi
done

# ── Collect FASTQ files ───────────────────────────────────────
mapfile -t FASTQS < <(find "$RAW_DIR" -name "*.fastq.gz" | sort)

if [[ ${#FASTQS[@]} -eq 0 ]]; then
  echo "ERROR: No .fastq.gz files found in $RAW_DIR" >&2
  exit 1
fi

echo "[$(date '+%F %T')] FastQC on ${#FASTQS[@]} files …" | tee "$LOG"
for f in "${FASTQS[@]}"; do
  echo "  → $f" | tee -a "$LOG"
done

# ── Run FastQC ────────────────────────────────────────────────
fastqc \
  --outdir  "$OUTDIR" \
  --threads "$THREADS" \
  ${ADAPTERS:+--adapters "$ADAPTERS"} \
  "${FASTQS[@]}" \
  2>&1 | tee -a "$LOG"

echo "[$(date '+%F %T')] FastQC complete. Running MultiQC …" | tee -a "$LOG"

# ── MultiQC aggregate report ──────────────────────────────────
multiqc \
  "$OUTDIR" \
  --outdir "$OUTDIR" \
  --filename "multiqc_fastqc_report" \
  --title  "RNAseq QC — Pre-alignment" \
  --force \
  2>&1 | tee -a "$LOG"

echo "[$(date '+%F %T')] Reports written to $OUTDIR" | tee -a "$LOG"
echo "Open: ${OUTDIR}/multiqc_fastqc_report.html"
