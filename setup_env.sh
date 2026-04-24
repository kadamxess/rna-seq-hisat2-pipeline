#!/usr/bin/env bash
# ============================================================
# setup_env.sh
# Create conda environment with all required tools
# ============================================================

set -euo pipefail

ENV_NAME="rnaseq_pipeline"

echo "Creating conda environment: $ENV_NAME"

conda create -y -n "$ENV_NAME" \
  -c conda-forge -c bioconda \
  python=3.11 \
  sra-tools \
  fastqc \
  multiqc \
  trimmomatic \
  hisat2 \
  star \
  samtools \
  picard \
  subread \
  r-base=4.3 \
  bioconductor-deseq2 \
  bioconductor-clusterprofiler \
  bioconductor-enrichplot \
  bioconductor-org.hs.eg.db \
  r-ggplot2 \
  r-ggrepel \
  r-pheatmap \
  r-dplyr \
  r-tibble \
  r-writexl \
  r-rcolorbrewer \
  pigz \
  wget

echo ""
echo "✔  Environment '$ENV_NAME' ready."
echo "Activate with: conda activate $ENV_NAME"
