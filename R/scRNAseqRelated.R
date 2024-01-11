#' 各个细胞内的高表达基因
#'
#' @description
#' 对Seurat对象里的各个单细胞，分别统计top表达的基因，即基因的reads比例大于所设定的阈值expt.cut。
#'
#' @param SeuratObj Seurat对象
#' @param expr.cut 针对UMI counts比例所设定的cut off，用于定义高表达的基因。
#'
#' @return A data.frame
#' @export
#'
#' @examples
#' # top_genes(SeuratObj = obj, expr.cut = 0.01)
top_genes <- function(SeuratObj, expr.cut = 0.01){
  require(parallel)
  require(dplyr)
  require(Seurat)
  if (grepl("^5", SeuratObj@version)) { # 对于seurat v5 对象，先要join layers.
    SeuratObj <- JoinLayers(SeuratObj)
    counts.expr <- SeuratObj@assays$RNA@layers$counts
  }else{
    counts.expr <- SeuratObj@assays$RNA$counts
  }
  top.list <- mclapply(1:ncol(SeuratObj), function(x){
    values <- sort(as.matrix(counts.expr)[,x],decreasing = TRUE)
    rates <- values/sum(values)
    top <- values[rates > 0.01]
    data.frame(Gene = names(top), Expr = unname(top))
  }, mc.cores = detectCores())
  top.df <- Reduce(rbind, top.list)
  group_by(top.df, Gene) %>%
    summarise(mean = mean(Expr), median = median(Expr), Cells = length(Expr)) -> top.statics
  return(top.statics)
}

