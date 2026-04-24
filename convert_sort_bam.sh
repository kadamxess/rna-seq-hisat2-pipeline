#!/usr/bin/env bash
# ============================================================
# convert_sort_bam.sh
# Post-alignment BAM processing:
#   1. Mark duplicates (Picard / samtools markdup)
#   2. Re-sort + index
#   3. Collect insert-size and alignment metrics
# ============================================================

set -euo pipefail

# ── Configuration ────────────────────────────────────────────
ALIGN_DIR="results/aligned"
PROC_DIR="results/processed_bam"
METRICS_DIR="results/metrics"
LOG="results/logs/convert_sort_bam.log"
THREADS=8

mkdir -p "$PROC_DIR" "$METRICS_DIR" "results/logs"

# ── Dependency check ─────────────────────────────────────────
for tool in samtools picard; do
  if ! command -v "$tool" &>/dev/null; then
    echo "ERROR: $tool not found." >&2
    echo "Install: conda install -c bioconda samtools picard" >&2
    exit 1
  fi
done

echo "[$(date '+%F %T')] BAM post-processing started" | tee "$LOG"

# ── Per-sample loop ───────────────────────────────────────────
mapfile -t BAMS < <(find "$ALIGN_DIR" -name "*_sorted.bam" | sort)

[[ ${#BAMS[@]} -eq 0 ]] && \
  { echo "ERROR: No sorted BAMs found in $ALIGN_DIR" >&2; exit 1; }

for BAM in "${BAMS[@]}"; do
  SAMPLE=$(basename "$BAM" _sorted.bam)
  echo "" | tee -a "$LOG"
  echo "━━━━ $SAMPLE ━━━━" | tee -a "$LOG"

  DEDUP_BAM="${PROC_DIR}/${SAMPLE}_dedup.bam"
  METRICS="${METRICS_DIR}/${SAMPLE}_dup_metrics.txt"

  # ── 1. Mark duplicates ────────────────────────────────────
  echo "[$(date '+%F %T')] Marking duplicates …" | tee -a "$LOG"
  picard MarkDuplicates \
    I="$BAM" \
    O="$DEDUP_BAM" \
    M="$METRICS" \
    REMOVE_DUPLICATES=false \
    VALIDATION_STRINGENCY=LENIENT \
    TMP_DIR=/tmp \
    2>&1 | tee -a "$LOG"

  # ── 2. Index deduplicated BAM ─────────────────────────────
  samtools index -@ "$THREADS" "$DEDUP_BAM"

  # ── 3. Flagstat ───────────────────────────────────────────
  samtools flagstat -@ "$THREADS" "$DEDUP_BAM" \
    > "${METRICS_DIR}/${SAMPLE}_flagstat.txt"

  # ── 4. Insert-size metrics ────────────────────────────────
  picard CollectInsertSizeMetrics \
    I="$DEDUP_BAM" \
    O="${METRICS_DIR}/${SAMPLE}_insert_size_metrics.txt" \
    H="${METRICS_DIR}/${SAMPLE}_insert_size_hist.pdf" \
    VALIDATION_STRINGENCY=LENIENT \
    TMP_DIR=/tmp \
    2>&1 | tee -a "$LOG"

  echo "[$(date '+%F %T')] $SAMPLE processed." | tee -a "$LOG"
done

echo "" | tee -a "$LOG"
echo "[$(date '+%F %T')] All BAM files processed. Output: $PROC_DIR" | tee -a "$LOG"
