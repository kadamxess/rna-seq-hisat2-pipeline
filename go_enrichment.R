#!/usr/bin/env Rscript
# ============================================================
# go_enrichment.sh  →  go_enrichment.R
# GO / KEGG pathway enrichment with clusterProfiler
# Input : results/deseq2/DEGs_significant.tsv
# Output: enrichment tables + dot/bar plots
# ============================================================

suppressPackageStartupMessages({
  library(clusterProfiler)
  library(org.Hs.eg.db)
  library(ggplot2)
  library(dplyr)
  library(enrichplot)
  library(writexl)
})

OUT_DIR  <- "results/enrichment"
PLOT_DIR <- "results/plots"
dir.create(OUT_DIR,  showWarnings = FALSE, recursive = TRUE)
dir.create(PLOT_DIR, showWarnings = FALSE, recursive = TRUE)

cat("[Enrichment] Loading DEGs …\n")
sig <- read.delim("results/deseq2/DEGs_significant.tsv")

# ── ID conversion: Ensembl → Entrez ──────────────────────────
ids <- bitr(sig$gene_id,
            fromType = "ENSEMBL",
            toType   = c("ENTREZID", "SYMBOL"),
            OrgDb    = org.Hs.eg.db)

cat(sprintf("  Mapped %d / %d gene IDs\n", nrow(ids), nrow(sig)))

up_ids   <- ids$ENTREZID[ids$ENSEMBL %in% filter(sig, log2FoldChange > 0)$gene_id]
down_ids <- ids$ENTREZID[ids$ENSEMBL %in% filter(sig, log2FoldChange < 0)$gene_id]
all_ids  <- ids$ENTREZID

# ── Helper: run & save enrichment ────────────────────────────
run_enrich <- function(gene_ids, label) {
  # GO Biological Process
  go_bp <- enrichGO(gene      = gene_ids,
                    OrgDb     = org.Hs.eg.db,
                    ont       = "BP",
                    pAdjustMethod = "BH",
                    pvalueCutoff  = 0.05,
                    qvalueCutoff  = 0.2,
                    readable  = TRUE)

  # KEGG
  kegg <- enrichKEGG(gene     = gene_ids,
                     organism = "hsa",
                     pvalueCutoff = 0.05)

  if (!is.null(go_bp) && nrow(go_bp) > 0) {
    write.table(as.data.frame(go_bp),
                file.path(OUT_DIR, paste0("GO_BP_", label, ".tsv")),
                sep = "\t", quote = FALSE, row.names = FALSE)

    # Dot plot
    p <- dotplot(go_bp, showCategory = 20, title = paste("GO BP —", label)) +
         theme(axis.text.y = element_text(size = 8))
    ggsave(file.path(PLOT_DIR, paste0("GO_dotplot_", label, ".png")),
           p, width = 10, height = 8, dpi = 180)

    # Enrichment map
    go_bp2 <- pairwise_termsim(go_bp)
    p2 <- emapplot(go_bp2, showCategory = 30)
    ggsave(file.path(PLOT_DIR, paste0("GO_emapplot_", label, ".png")),
           p2, width = 10, height = 8, dpi = 180)
  }

  if (!is.null(kegg) && nrow(kegg) > 0) {
    write.table(as.data.frame(kegg),
                file.path(OUT_DIR, paste0("KEGG_", label, ".tsv")),
                sep = "\t", quote = FALSE, row.names = FALSE)

    p3 <- barplot(kegg, showCategory = 20,
                  title = paste("KEGG —", label))
    ggsave(file.path(PLOT_DIR, paste0("KEGG_barplot_", label, ".png")),
           p3, width = 10, height = 6, dpi = 180)
  }

  list(go_bp = go_bp, kegg = kegg)
}

cat("[Enrichment] All DEGs …\n");  r_all  <- run_enrich(all_ids,  "all_DEGs")
cat("[Enrichment] Up-regulated …\n"); r_up   <- run_enrich(up_ids,   "upregulated")
cat("[Enrichment] Down-regulated …\n"); r_down <- run_enrich(down_ids, "downregulated")

# ── GSEA (ranked by LFC) ─────────────────────────────────────
cat("[Enrichment] GSEA …\n")
gene_list <- setNames(sig$log2FoldChange, sig$gene_id)
gene_list <- sort(gene_list, decreasing = TRUE)

gsea_ids <- bitr(names(gene_list), "ENSEMBL", "ENTREZID", org.Hs.eg.db)
gene_list_entrez <- setNames(
  gene_list[match(gsea_ids$ENSEMBL, names(gene_list))],
  gsea_ids$ENTREZID)
gene_list_entrez <- sort(gene_list_entrez[!duplicated(names(gene_list_entrez))],
                         decreasing = TRUE)

gsea_res <- gseKEGG(geneList     = gene_list_entrez,
                    organism     = "hsa",
                    minGSSize    = 10,
                    pvalueCutoff = 0.05,
                    verbose      = FALSE)

if (!is.null(gsea_res) && nrow(gsea_res) > 0) {
  write.table(as.data.frame(gsea_res),
              file.path(OUT_DIR, "GSEA_KEGG.tsv"),
              sep = "\t", quote = FALSE, row.names = FALSE)

  p_gsea <- ridgeplot(gsea_res, showCategory = 20) +
            labs(title = "GSEA KEGG Ridgeplot")
  ggsave(file.path(PLOT_DIR, "GSEA_ridgeplot.png"),
         p_gsea, width = 10, height = 8, dpi = 180)
}

cat("[Enrichment] Analysis complete.\n")
cat(sprintf("  Results : %s\n", OUT_DIR))
