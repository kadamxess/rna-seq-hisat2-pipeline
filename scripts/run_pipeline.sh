
Workflow Script (scripts/run_pipeline.sh)

```bash
#!/bin/bash

# Create directories
mkdir -p data/trimmed data/aligned results/qc results/counts

# Step 1: Quality Control
fastqc data/raw/*.fastq -o results/qc/

# Step 2: Trimming
for file in data/raw/*_1.fastq
do
    base=$(basename $file "_1.fastq")
    trimmomatic PE \
    data/raw/${base}_1.fastq data/raw/${base}_2.fastq \
    data/trimmed/${base}_1_paired.fastq data/trimmed/${base}_1_unpaired.fastq \
    data/trimmed/${base}_2_paired.fastq data/trimmed/${base}_2_unpaired.fastq \
    SLIDINGWINDOW:4:20 MINLEN:50
done

# Step 3: Build Index
hisat2-build reference/genome.fa reference/genome_index

# Step 4: Alignment
for file in data/trimmed/*_1_paired.fastq
do
    base=$(basename $file "_1_paired.fastq")
    hisat2 -x reference/genome_index \
    -1 data/trimmed/${base}_1_paired.fastq \
    -2 data/trimmed/${base}_2_paired.fastq \
    -S data/aligned/${base}.sam
done

# Step 5: Convert and Sort
for file in data/aligned/*.sam
do
    base=$(basename $file ".sam")
    samtools view -bS $file | samtools sort -o data/aligned/${base}_sorted.bam
done

# Step 6: StringTie Assembly
for file in data/aligned/*_sorted.bam
do
    base=$(basename $file "_sorted.bam")
    stringtie $file -G reference/annotation.gtf -o results/${base}.gtf
done
