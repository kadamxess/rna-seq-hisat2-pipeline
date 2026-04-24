#!/usr/bin/env bash
# ============================================================
# run_pipeline.sh
# Master script — executes all pipeline steps in order
# Usage: bash run_pipeline.sh [--from STEP] [--to STEP] [--help]
# Steps: download | ref | index | fastqc | trim | align | count | deseq2 | enrich
# ============================================================

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${SCRIPT_DIR}/results/logs"
mkdir -p "$LOG_DIR"

# ── Colours ──────────────────────────────────────────────────
RED='\033[0;31m'; GRN='\033[0;32m'; YLW='\033[1;33m'
BLU='\033[0;34m'; NC='\033[0m'; BOLD='\033[1m'

# ── Step registry (ordered) ───────────────────────────────────
declare -A STEP_SCRIPTS=(
  [download]="download_data.sh"
  [ref]="download_ref_genome.sh"
  [idx_hisat2]="download_hisat2_idx.sh"
  [idx_star]="generate_star_idx.sh"
  [fastqc]="fastqc.sh"
  [trim]="trim_reads.sh"
  [align]="align_hisat2_reads.sh"
  [postbam]="convert_sort_bam.sh"
  [count]="featurecounts.sh"
  [deseq2]="deseq2_analysis.R"
  [enrich]="go_enrichment.R"
)

ORDERED_STEPS=(download ref idx_hisat2 fastqc trim align postbam count deseq2 enrich)

FROM_STEP=""
TO_STEP=""
SKIP_STEPS=()

# ── Argument parsing ──────────────────────────────────────────
usage() {
  echo -e "${BOLD}Usage:${NC} bash run_pipeline.sh [options]"
  echo ""
  echo "Options:"
  echo "  --from STEP     Start from this step"
  echo "  --to   STEP     Stop after this step"
  echo "  --skip STEP     Skip a specific step (repeatable)"
  echo "  --list          List all available steps"
  echo "  --help          Show this help"
  echo ""
  echo -e "Steps: ${YLW}${ORDERED_STEPS[*]}${NC}"
}

while [[ $# -gt 0 ]]; do
  case $1 in
    --from)  FROM_STEP="$2"; shift 2 ;;
    --to)    TO_STEP="$2";   shift 2 ;;
    --skip)  SKIP_STEPS+=("$2"); shift 2 ;;
    --list)  printf "%s\n" "${ORDERED_STEPS[@]}"; exit 0 ;;
    --help)  usage; exit 0 ;;
    *) echo "Unknown option: $1"; usage; exit 1 ;;
  esac
done

# ── Helpers ───────────────────────────────────────────────────
in_array() { local e; for e in "${@:2}"; do [[ "$e" == "$1" ]] && return 0; done; return 1; }

run_step() {
  local step="$1"
  local script="${SCRIPT_DIR}/scripts/${STEP_SCRIPTS[$step]}"
  local t_start t_end elapsed

  echo -e "\n${BLU}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}▶  Step: ${YLW}${step}${NC}  →  ${script##*/}"
  echo -e "${BLU}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

  if [[ ! -f "$script" ]]; then
    echo -e "${RED}ERROR: Script not found: $script${NC}" >&2; exit 1
  fi

  t_start=$SECONDS

  if [[ "$script" == *.R ]]; then
    Rscript "$script"
  else
    bash "$script"
  fi

  t_end=$SECONDS; elapsed=$(( t_end - t_start ))
  echo -e "${GRN}✔  ${step} completed in ${elapsed}s${NC}"
}

# ── Pipeline execution ────────────────────────────────────────
ACTIVE=false
[[ -z "$FROM_STEP" ]] && ACTIVE=true

PIPELINE_START=$SECONDS
echo -e "${BOLD}╔══════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║   RNAseq Analysis Pipeline — $(date '+%F %T')   ║${NC}"
echo -e "${BOLD}╚══════════════════════════════════════════════╝${NC}"

for step in "${ORDERED_STEPS[@]}"; do
  [[ "$step" == "$FROM_STEP" ]] && ACTIVE=true
  if $ACTIVE; then
    if in_array "$step" "${SKIP_STEPS[@]}"; then
      echo -e "${YLW}⏭  Skipping: $step${NC}"
    else
      run_step "$step"
    fi
  fi
  [[ "$step" == "$TO_STEP" ]] && break
done

ELAPSED=$(( SECONDS - PIPELINE_START ))
echo -e "\n${GRN}${BOLD}Pipeline finished in ${ELAPSED}s — $(date '+%F %T')${NC}"
