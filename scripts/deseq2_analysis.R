library(DESeq2)

counts <- read.csv("results/counts/gene_count_matrix.csv", row.names=1)
coldata <- data.frame(
  condition = c("control","treated")
)

dds <- DESeqDataSetFromMatrix(
  countData = counts,
  colData = coldata,
  design = ~ condition
)

dds <- DESeq(dds)
res <- results(dds)

write.csv(res, "results/differential_expression/deseq2_results.csv")
