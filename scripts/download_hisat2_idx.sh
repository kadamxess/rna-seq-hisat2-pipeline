#!/usr/bin/env bash
# ============================================================
# download_hisat2_idx.sh
# Download pre-built HISAT2 index for GRCh38
# (saves ~2–4 h of indexing time)
# ============================================================

set -euo pipefail

# ── Configuration ────────────────────────────────────────────
IDX_DIR="data/index/hisat2"
LOG="results/logs/download_hisat2_idx.log"
THREADS=4

# HISAT2 GRCh38 index with SNPs + splice sites (DAEHWAN KIM lab)
BASE_URL="https://genome-idx.s3.amazonaws.com/hisat/grch38_snptran.tar.gz"

mkdir -p "$IDX_DIR" "results/logs"

echo "[$(date '+%F %T')] Downloading HISAT2 GRCh38 index …" | tee "$LOG"

wget -c --progress=dot:giga \
  -O "${IDX_DIR}/grch38_snptran.tar.gz" \
  "$BASE_URL" 2>>"$LOG"

echo "[$(date '+%F %T')] Extracting index …" | tee -a "$LOG"
tar -xzf "${IDX_DIR}/grch38_snptran.tar.gz" \
    --strip-components=1 \
    -C "$IDX_DIR" 2>>"$LOG"

rm -f "${IDX_DIR}/grch38_snptran.tar.gz"

echo "[$(date '+%F %T')] HISAT2 index ready." | tee -a "$LOG"
echo "Index files:"
ls -lh "$IDX_DIR"/*.ht2 | head -5
