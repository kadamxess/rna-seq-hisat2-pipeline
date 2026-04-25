# RNA-Seq Analysis Pipeline using HISAT2

## Overview
This project implements a complete RNA-seq analysis pipeline using HISAT2 for alignment, followed by transcript assembly and differential gene expression analysis.

##  Tools Used
- HISAT2 (Alignment)
- SAMtools (File processing)
- StringTie (Transcript assembly)
- FastQC (Quality control)
- Trimmomatic (Read trimming)
- DESeq2 (Differential expression)

## Workflow
1. Quality Control (FastQC)
2. Read Trimming (Trimmomatic)
3. Indexing Reference Genome (HISAT2)
4. Alignment (HISAT2)
5. SAM → BAM Conversion (SAMtools)
6. Transcript Assembly (StringTie)
7. Count Matrix Generation
8. Differential Expression Analysis (DESeq2)

## How to Run

### Step 1: Clone Repository
```bash
git clone https://github.com/yourusername/rna-seq-hisat2-pipeline.git
cd rna-seq-hisat2-pipeline
