#!/usr/bin/env bash
# ============================================================
# trim_reads.sh
# Adapter trimming + quality filtering with Trimmomatic
# ============================================================

set -euo pipefail

# ── Configuration ────────────────────────────────────────────
RAW_DIR="data/raw"
TRIM_DIR="data/trimmed"
LOG="results/logs/trim_reads.log"
THREADS=4

# Trimmomatic parameters
ADAPTERS="${CONDA_PREFIX:-/usr}/share/trimmomatic/adapters/TruSeq3-PE-2.fa"
LEADING=3
TRAILING=3
SLIDINGWINDOW="4:15"
MINLEN=36

mkdir -p "$TRIM_DIR" "results/logs"

# ── Dependency check ─────────────────────────────────────────
if ! command -v trimmomatic &>/dev/null; then
  echo "ERROR: trimmomatic not found." >&2
  echo "Install: conda install -c bioconda trimmomatic" >&2
  exit 1
fi

# ── Sample loop ───────────────────────────────────────────────
mapfile -t R1_FILES < <(find "$RAW_DIR" -name "*_1.fastq.gz" | sort)

if [[ ${#R1_FILES[@]} -eq 0 ]]; then
  echo "ERROR: No *_1.fastq.gz files in $RAW_DIR" >&2; exit 1
fi

echo "[$(date '+%F %T')] Trimming ${#R1_FILES[@]} sample(s) …" | tee "$LOG"

PASS=0; FAIL=0
for R1 in "${R1_FILES[@]}"; do
  SAMPLE=$(basename "$R1" _1.fastq.gz)
  R2="${RAW_DIR}/${SAMPLE}_2.fastq.gz"

  if [[ ! -f "$R2" ]]; then
    echo "WARN: R2 not found for $SAMPLE — skipping" | tee -a "$LOG"; continue
  fi

  echo "[$(date '+%F %T')] Trimming $SAMPLE …" | tee -a "$LOG"

  trimmomatic PE \
    -threads "$THREADS" \
    -phred33 \
    "$R1" "$R2" \
    "${TRIM_DIR}/${SAMPLE}_1_paired.fastq.gz"   \
    "${TRIM_DIR}/${SAMPLE}_1_unpaired.fastq.gz" \
    "${TRIM_DIR}/${SAMPLE}_2_paired.fastq.gz"   \
    "${TRIM_DIR}/${SAMPLE}_2_unpaired.fastq.gz" \
    ILLUMINACLIP:"${ADAPTERS}:2:30:10:2:keepBothReads" \
    LEADING:"$LEADING" \
    TRAILING:"$TRAILING" \
    SLIDINGWINDOW:"$SLIDINGWINDOW" \
    MINLEN:"$MINLEN" \
    2>&1 | tee -a "$LOG" && PASS=$((PASS+1)) || FAIL=$((FAIL+1))
done

echo "[$(date '+%F %T')] Trimming done. Passed=$PASS  Failed=$FAIL" | tee -a "$LOG"

# ── Post-trim FastQC ──────────────────────────────────────────
echo "[$(date '+%F %T')] Running post-trim FastQC …" | tee -a "$LOG"
fastqc --outdir results/fastqc --threads "$THREADS" \
  "${TRIM_DIR}"/*_paired.fastq.gz 2>&1 | tee -a "$LOG"
