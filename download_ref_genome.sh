#!/usr/bin/env bash
# ============================================================
# download_ref_genome.sh
# Download human reference genome (GRCh38) + GTF annotation
# ============================================================

set -euo pipefail

# ── Configuration ────────────────────────────────────────────
GENOME_DIR="data/ref"
LOG="results/logs/download_ref.log"
RELEASE=110          # Ensembl release
SPECIES="homo_sapiens"
ASSEMBLY="GRCh38"

GENOME_URL="https://ftp.ensembl.org/pub/release-${RELEASE}/fasta/${SPECIES}/dna/${ASSEMBLY}.dna.primary_assembly.fa.gz"
GTF_URL="https://ftp.ensembl.org/pub/release-${RELEASE}/gtf/${SPECIES}/${ASSEMBLY}.${RELEASE}.gtf.gz"

mkdir -p "$GENOME_DIR" "results/logs"

echo "[$(date '+%F %T')] Downloading reference genome — Ensembl release ${RELEASE}" | tee "$LOG"

# ── Download genome FASTA ─────────────────────────────────────
echo "[$(date '+%F %T')] Fetching genome FASTA …" | tee -a "$LOG"
wget -c --progress=dot:giga \
  -O "${GENOME_DIR}/genome.fa.gz" \
  "$GENOME_URL" 2>>"$LOG"

echo "[$(date '+%F %T')] Decompressing genome …" | tee -a "$LOG"
pigz -dk "${GENOME_DIR}/genome.fa.gz"

# ── Download GTF annotation ───────────────────────────────────
echo "[$(date '+%F %T')] Fetching GTF annotation …" | tee -a "$LOG"
wget -c --progress=dot:giga \
  -O "${GENOME_DIR}/annotation.gtf.gz" \
  "$GTF_URL" 2>>"$LOG"

echo "[$(date '+%F %T')] Decompressing GTF …" | tee -a "$LOG"
pigz -dk "${GENOME_DIR}/annotation.gtf.gz"

# ── Checksums ────────────────────────────────────────────────
echo "[$(date '+%F %T')] Generating checksums …" | tee -a "$LOG"
md5sum "${GENOME_DIR}/genome.fa" "${GENOME_DIR}/annotation.gtf" \
  > "${GENOME_DIR}/checksums.md5"

echo "[$(date '+%F %T')] Reference genome download complete." | tee -a "$LOG"
ls -lh "$GENOME_DIR"
