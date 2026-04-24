#!/usr/bin/env bash
# ============================================================
# align_hisat2_reads.sh
# Align trimmed paired-end reads with HISAT2
# Outputs: sorted BAM per sample + alignment stats
# ============================================================

set -euo pipefail

# ── Configuration ────────────────────────────────────────────
TRIM_DIR="data/trimmed"
IDX_DIR="data/index/hisat2"
ALIGN_DIR="results/aligned"
LOG="results/logs/hisat2_align.log"
THREADS=8

# HISAT2 index prefix (basename without .N.ht2 suffix)
IDX_PREFIX="${IDX_DIR}/genome"

mkdir -p "$ALIGN_DIR" "results/logs"

# ── Dependency check ─────────────────────────────────────────
for tool in hisat2 samtools; do
  if ! command -v "$tool" &>/dev/null; then
    echo "ERROR: $tool not found." >&2
    echo "Install: conda install -c bioconda hisat2 samtools" >&2
    exit 1
  fi
done

echo "[$(date '+%F %T')] HISAT2 alignment started" | tee "$LOG"
echo "  Index  : $IDX_PREFIX" | tee -a "$LOG"
echo "  Threads: $THREADS"    | tee -a "$LOG"

# ── Sample loop ───────────────────────────────────────────────
mapfile -t R1_FILES < <(find "$TRIM_DIR" -name "*_1_paired.fastq.gz" | sort)

[[ ${#R1_FILES[@]} -eq 0 ]] && \
  { echo "ERROR: no trimmed R1 files found" >&2; exit 1; }

TOTAL=0; SUCCESS=0

for R1 in "${R1_FILES[@]}"; do
  SAMPLE=$(basename "$R1" _1_paired.fastq.gz)
  R2="${TRIM_DIR}/${SAMPLE}_2_paired.fastq.gz"
  SAM="${ALIGN_DIR}/${SAMPLE}.sam"
  BAM="${ALIGN_DIR}/${SAMPLE}_sorted.bam"
  STATS="${ALIGN_DIR}/${SAMPLE}_flagstat.txt"
  TOTAL=$((TOTAL+1))

  echo "" | tee -a "$LOG"
  echo "━━━━ [$TOTAL] $SAMPLE ━━━━" | tee -a "$LOG"

  # ── Align ──────────────────────────────────────────────────
  hisat2 \
    -x  "$IDX_PREFIX" \
    -1  "$R1" \
    -2  "$R2" \
    -p  "$THREADS" \
    --dta \
    --rna-strandness RF \
    --no-mixed \
    --no-discordant \
    -S  "$SAM" \
    2>&1 | tee -a "$LOG"

  # ── SAM → sorted BAM → index ───────────────────────────────
  echo "[$(date '+%F %T')] Converting & sorting $SAMPLE …" | tee -a "$LOG"
  samtools view  -@ "$THREADS" -bS "$SAM" | \
  samtools sort  -@ "$THREADS" -o "$BAM"
  samtools index "$BAM"
  rm -f "$SAM"

  # ── Flagstat ───────────────────────────────────────────────
  samtools flagstat "$BAM" > "$STATS"
  echo "  Flagstat → $STATS" | tee -a "$LOG"
  cat "$STATS" | tee -a "$LOG"

  SUCCESS=$((SUCCESS+1))
done

echo "" | tee -a "$LOG"
echo "[$(date '+%F %T')] HISAT2 alignment done. Success=$SUCCESS/$TOTAL" | tee -a "$LOG"
