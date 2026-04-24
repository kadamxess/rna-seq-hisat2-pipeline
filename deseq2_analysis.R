#!/usr/bin/env Rscript
# ============================================================
# deseq2_analysis.R
# Differential expression analysis with DESeq2
# Input : results/counts/counts_matrix.tsv
# Output: DEGs table, PCA, volcano, heatmap
# ============================================================

suppressPackageStartupMessages({
  library(DESeq2)
  library(ggplot2)
  library(ggrepel)
  library(pheatmap)
  library(RColorBrewer)
  library(dplyr)
  library(tibble)
  library(writexl)
})

# ── Paths ────────────────────────────────────────────────────
COUNT_FILE <- "results/counts/counts_matrix.tsv"
OUT_DIR    <- "results/deseq2"
PLOT_DIR   <- "results/plots"
dir.create(OUT_DIR,  showWarnings = FALSE, recursive = TRUE)
dir.create(PLOT_DIR, showWarnings = FALSE, recursive = TRUE)

cat("[DESeq2] Loading count matrix …\n")
raw <- read.delim(COUNT_FILE, check.names = FALSE)

# ── Build count matrix ────────────────────────────────────────
cnt_cols  <- grep("^SRR|Control|Treated", colnames(raw), value = TRUE)
count_mat <- as.matrix(raw[, cnt_cols])
rownames(count_mat) <- raw$Geneid

cat(sprintf("  Genes: %d | Samples: %d\n", nrow(count_mat), ncol(count_mat)))

# ── Sample metadata ───────────────────────────────────────────
col_data <- data.frame(
  sample    = colnames(count_mat),
  condition = factor(ifelse(grepl("Control|SRR898357[9]|SRR898358[01]",
                                   colnames(count_mat)),
                            "Control", "Treated"),
                     levels = c("Control", "Treated")),
  row.names = colnames(count_mat)
)
cat("Sample table:\n"); print(col_data)

# ── DESeq2 object ─────────────────────────────────────────────
dds <- DESeqDataSetFromMatrix(
  countData = count_mat,
  colData   = col_data,
  design    = ~ condition
)

# Filter low-count genes (≥10 reads in ≥2 samples)
keep <- rowSums(counts(dds) >= 10) >= 2
dds  <- dds[keep, ]
cat(sprintf("  After filtering: %d genes\n", nrow(dds)))

# ── Run DESeq2 ────────────────────────────────────────────────
cat("[DESeq2] Running differential expression …\n")
dds    <- DESeq(dds)
res    <- results(dds, contrast = c("condition", "Treated", "Control"),
                  alpha = 0.05, lfcThreshold = 0)
res_lfc <- lfcShrink(dds, coef = "condition_Treated_vs_Control",
                      type = "apeglm", res = res)

# ── Results table ─────────────────────────────────────────────
res_df <- as.data.frame(res_lfc) %>%
  rownames_to_column("gene_id") %>%
  left_join(raw[, c("Geneid","gene_name","gene_biotype")],
            by = c("gene_id" = "Geneid")) %>%
  arrange(padj)

write.table(res_df,
            file = file.path(OUT_DIR, "DEGs_all.tsv"),
            sep = "\t", quote = FALSE, row.names = FALSE)
write_xlsx(res_df, file.path(OUT_DIR, "DEGs_all.xlsx"))

sig <- filter(res_df, padj < 0.05, abs(log2FoldChange) > 1)
cat(sprintf("  Significant DEGs (|LFC|>1, padj<0.05): %d\n", nrow(sig)))
write.table(sig, file.path(OUT_DIR, "DEGs_significant.tsv"),
            sep = "\t", quote = FALSE, row.names = FALSE)

# ── PCA ───────────────────────────────────────────────────────
cat("[DESeq2] Plotting PCA …\n")
vsd <- vst(dds, blind = FALSE)
pca_data <- plotPCA(vsd, intgroup = "condition", returnData = TRUE)
pvar <- round(100 * attr(pca_data, "percentVar"))

p_pca <- ggplot(pca_data, aes(x = PC1, y = PC2,
                               color = condition, label = name)) +
  geom_point(size = 4, alpha = 0.85) +
  geom_text_repel(size = 3.2) +
  labs(title = "PCA — VST-normalised counts",
       x = paste0("PC1: ", pvar[1], "% variance"),
       y = paste0("PC2: ", pvar[2], "% variance")) +
  scale_color_manual(values = c(Control = "#2196F3", Treated = "#F44336")) +
  theme_bw(base_size = 13) +
  theme(plot.title = element_text(face = "bold"))
ggsave(file.path(PLOT_DIR, "PCA.png"), p_pca, width = 7, height = 5, dpi = 200)

# ── Volcano ───────────────────────────────────────────────────
cat("[DESeq2] Plotting volcano …\n")
vol <- res_df %>%
  mutate(sig = case_when(
    padj < 0.05 & log2FoldChange >  1 ~ "Up",
    padj < 0.05 & log2FoldChange < -1 ~ "Down",
    TRUE ~ "NS"))

top_genes <- vol %>% filter(sig != "NS") %>%
  arrange(padj) %>% slice_head(n = 20)

p_vol <- ggplot(vol, aes(x = log2FoldChange, y = -log10(padj), color = sig)) +
  geom_point(alpha = 0.5, size = 1.2) +
  geom_text_repel(data = top_genes, aes(label = gene_name),
                  size = 2.8, max.overlaps = 15) +
  geom_vline(xintercept = c(-1, 1), linetype = "dashed", color = "grey50") +
  geom_hline(yintercept = -log10(0.05), linetype = "dashed", color = "grey50") +
  scale_color_manual(values = c(Up = "#E53935", Down = "#1E88E5", NS = "grey70")) +
  labs(title = "Volcano — Treated vs Control",
       x = expression(log[2]~fold~change),
       y = expression(-log[10]~(adjusted~italic(p)))) +
  theme_bw(base_size = 13) +
  theme(plot.title = element_text(face = "bold"))
ggsave(file.path(PLOT_DIR, "volcano.png"), p_vol, width = 8, height = 6, dpi = 200)

# ── Heatmap (top 50 DEGs) ─────────────────────────────────────
cat("[DESeq2] Plotting heatmap …\n")
top50 <- sig %>% arrange(padj) %>% slice_head(n = 50) %>% pull(gene_id)
mat   <- assay(vsd)[top50, ]
rownames(mat) <- sig$gene_name[match(rownames(mat), sig$gene_id)]
mat   <- mat - rowMeans(mat)

ann_col <- as.data.frame(col_data["condition"])
colors  <- colorRampPalette(rev(brewer.pal(9, "RdBu")))(100)

png(file.path(PLOT_DIR, "heatmap_top50.png"), width = 900, height = 1200, res = 140)
pheatmap(mat,
         annotation_col   = ann_col,
         color            = colors,
         show_rownames    = TRUE,
         show_colnames    = TRUE,
         fontsize_row     = 7,
         cluster_cols     = TRUE,
         border_color     = NA,
         main             = "Top 50 DEGs (VST, row-centred)")
dev.off()

cat("[DESeq2] Analysis complete.\n")
cat(sprintf("  Results : %s\n", OUT_DIR))
cat(sprintf("  Plots   : %s\n", PLOT_DIR))
