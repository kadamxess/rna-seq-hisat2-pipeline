# RNA-Seq Analysis Pipeline using HISAT2

##  Overview

This repository provides a complete, reproducible RNA-seq analysis pipeline built around HISAT2. The workflow performs read quality control, trimming, genome alignment, transcript assembly, and differential gene expression analysis.

---

##  Repository Structure

```
rna-seq-hisat2-pipeline/
│── data/
│   ├── raw/                # Input FASTQ files (paired-end)
│   ├── trimmed/            # Trimmed FASTQ files
│   ├── aligned/            # SAM/BAM alignment files
│
│── reference/
│   ├── genome.fa           # Reference genome FASTA
│   ├── annotation.gtf      # Gene annotation file
│
│── results/
│   ├── qc/                 # FastQC reports
│   ├── counts/             # Gene count matrix
│   ├── differential_expression/  # DESeq2 output
│
│── scripts/
│   ├── run_pipeline.sh     # Main pipeline script
│   ├── deseq2_analysis.R   # Differential expression script
│
│── environment.yml         # Conda environment
│── README.md
│── .gitignore
```

---

##  Tools & Dependencies

* HISAT2 – alignment
* SAMtools – BAM processing
* StringTie – transcript assembly
* FastQC – quality control
* Trimmomatic – read trimming
* DESeq2 – differential expression (R/Bioconductor)

---

##  Input Requirements

### 1. RNA-seq Data

Place raw FASTQ files inside:

```
data/raw/
```

**Naming convention (important):**

```
sample1_1.fastq
sample1_2.fastq
sample2_1.fastq
sample2_2.fastq
```

---

### 2. Reference Files

Download and place inside:

```
reference/
```

Required:

* `genome.fa` (reference genome)
* `annotation.gtf` (gene annotation)

You can obtain these from Ensembl or NCBI.

---

##  Environment Setup

Install Conda (Miniconda/Anaconda), then run:

```bash
conda env create -f environment.yml
conda activate rnaseq_env
```

---

##  Running the Pipeline

Execute the full workflow:

```bash
bash scripts/run_pipeline.sh
```

---

##  Pipeline Steps

1. **Quality Control**
   FASTQ files are analyzed using FastQC → results stored in `results/qc/`

2. **Read Trimming**
   Low-quality bases and adapters removed using Trimmomatic → `data/trimmed/`

3. **Genome Indexing**
   HISAT2 builds index from `reference/genome.fa`

4. **Alignment**
   Reads aligned to reference genome → SAM files in `data/aligned/`

5. **SAM → BAM Conversion**
   Sorted BAM files generated using SAMtools

6. **Transcript Assembly**
   StringTie reconstructs transcripts → `.gtf` files

7. **Count Matrix Generation**
   Expression counts prepared for downstream analysis

8. **Differential Expression**
   Run in R:

```bash
Rscript scripts/deseq2_analysis.R
```

---

## 📊 Outputs

| Output Type      | Location                           |
| ---------------- | ---------------------------------- |
| QC Reports       | `results/qc/`                      |
| Trimmed Reads    | `data/trimmed/`                    |
| BAM Files        | `data/aligned/`                    |
| Transcript Files | `results/`                         |
| Gene Counts      | `results/counts/`                  |
| DE Results       | `results/differential_expression/` |

---

## Important Notes

* Ensure **paired-end file naming is consistent**
* Large datasets require:

  * ≥8 GB RAM (minimum)
  * Multi-core CPU recommended
* For large-scale analysis, run on HPC or cloud

---

## 📎 Data Source

Public RNA-seq datasets can be downloaded from
NCBI Sequence Read Archive

---

##  Author

Kadam Xess

---

##  Future Improvements

* Add Snakemake workflow automation
* Integrate MultiQC for aggregated QC reports
* Add visualization (PCA, heatmaps)
* Functional enrichment (GO/KEGG)

---
