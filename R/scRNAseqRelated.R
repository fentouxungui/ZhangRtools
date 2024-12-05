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
top_genes <- function (SeuratObj, expr.cut = 0.01) {
  requireNamespace("parallel")
  requireNamespace("dplyr")
  requireNamespace("Seurat")
  if (class(SeuratObj@assays$RNA)[1] == "Assay5") {
    SeuratObj <- JoinLayers(SeuratObj)
    counts.expr <- as.matrix(SeuratObj@assays$RNA@layers$counts)
  } else {
    counts.expr <- as.matrix(SeuratObj@assays$RNA$counts)
  }
  colnames(counts.expr) <- colnames(SeuratObj)
  rownames(counts.expr) <- rownames(SeuratObj)
  top.list <- mclapply(1:ncol(SeuratObj), function(x) {
    values <- sort(counts.expr[, x], decreasing = TRUE)
    rates <- values/sum(values)
    top <- values[rates > 0.01]
    data.frame(Gene = names(top), Expr = unname(top))
  }, mc.cores = detectCores())
  top.df <- Reduce(rbind, top.list)
  top.statics <- group_by(top.df, Gene) %>%
    summarise(mean = mean(Expr), median = median(Expr), Cells = length(Expr))
  return(as.data.frame(top.statics))
}




#' 对单个基因绘制splited feature plot，支持使用common legend
#'
#' @param obj A Seurat object
#' @param feature a single feature
#' @param SplitBy group cells by
#' @param PointColor colors for low, middle, high expression
#' @param ncol number of columns to show plots
#' @param remove_axes 是否需要删除xy坐标轴
#' @param ...
#'
#' @return NULL
#' @export
#'
#' @examples
#' # FeaturePlot_Single(obj = cds, feature = "Lgr5", SplitBy = 'class', ncol = 4, remvove_axes = TRUE)
FeaturePlot_Single <- function(obj, feature, SplitBy, PointColor = c("#638ED0", "#ffff33","#ff3300"), n_columns = NULL, remove_axes = FALSE, ...){
  library(ggpubr)
  library(grDevices)
  library(Seurat)

  if (length(feature) > 1) {
    stop("Only support one gene.")
  }
  # define some functions
  color.vector <- colorRampPalette(PointColor)(60) # color used in featureplot, low, middle, high expression

  color.range <- function(all.min = 0, all.max = 25, sub.min = 0, sub.max = 20, color.vector = get("color.vector")){
    range.breaks <- base::seq(from = all.min, to = all.max, length.out = (length(color.vector) + 1))
    range.breaks <- range.breaks[-length(range.breaks)]
    min.color.pos <- sum(sub.min >= range.breaks)
    max.color.pos <- sum(sub.max >= range.breaks)
    return(color.vector[min.color.pos:max.color.pos])
  }

  # plot each group
  all_cells <- colnames(obj)
  if (!is.factor(obj@meta.data[, SplitBy])) {
    obj@meta.data[, SplitBy] <- as.factor(obj@meta.data[, SplitBy])
  }
  groups <- levels(obj@meta.data[, SplitBy])
  # print(groups)
  # the minimal and maximal of the value to make the legend scale the same.
  if (feature %in% colnames(obj@meta.data)) {
    expr.data <- obj@meta.data[, feature]
    names(expr.data) <- colnames(obj)
  }else{
    expr.data <- obj[[DefaultAssay(obj)]]@data[feature,]
  }

  minimal <- min(expr.data)
  maximal <- max(expr.data)
  group_has_the_maximum_value <- as.character(obj@meta.data[, SplitBy][which.max(expr.data)]) # the legend from which, will be used as the common legend
  ps <- list()
  # group.ordered <- c() #group.ordered is used to rearrange plots in final plot list,
  # which will make the plot with maximal expr value as the first plot, and the legend of the first plot will be used for the final merged plot
  for (group in groups) {
    subset_indx <- obj@meta.data[, SplitBy] == group
    subset_cells <- all_cells[subset_indx]
    # print(length(subset_cells))
    if (length(subset_cells) < 2) { # if cells less than 2 will cause an error
      next()
    }else {
      minimal.sub <- min(expr.data[subset_cells])
      maximal.sub <- max(expr.data[subset_cells])
      color.used <- color.range(minimal, maximal, minimal.sub, maximal.sub, color.vector = color.vector)
      if (length(unique(expr.data[subset_cells])) == 1) { # all cells with same expr value
        # if all zero, return the first color, else should be the last color in color vector
        if(unique(expr.data[subset_cells]) == 0) {color.used[1] <- color.vector[1]}
        p <- FeaturePlot(obj,
                         features = feature,
                         # cols = c(minimal.color, color.vector[length(color.vector)]),
                         cells= subset_cells, ...) +
          scale_colour_gradientn(colours = color.used[1]) +
          ggtitle(group) +
          theme(plot.title = element_text(size = 10, face = "bold"))

      }else{
        p <- FeaturePlot(obj, features = feature, cells= subset_cells, ...) +
          # scale_color_viridis_c(limits=c(minimal, maximal), direction = 1) +
          scale_colour_gradientn(colours = color.used) +
          ggtitle(group) +
          theme(plot.title = element_text(size = 10, face = "bold"))
      }

      # if (maximal.sub == maximal) {
      #   group.ordered <- c(group, group.ordered)
      # }else{
      #   group.ordered <- c(group.ordered, group)
      # }
      ps[[group]] <- p
    }
  }

  # because ggarrange only use the legend from the first plot as the common legend,
  # so Here I need to put the plot with largest expr value as the first plot, hope this could be solved in future~
  # ps <- ps[group.ordered]
  # modify the xlim ylim to use same range
  if (length(ps) > 1) {
    range.list <- lapply(ps, function(x){c(ggplot_build(plot = x)$layout$panel_params[[1]]$x.range,
                                           ggplot_build(plot = x)$layout$panel_params[[1]]$y.range)})
    range.df <- Reduce(rbind, range.list)
    range.xlim <- c(min(range.df[,1]),max(range.df[,2]))
    range.ylim <- c(min(range.df[,3]),max(range.df[,4]))
    ps <- lapply(ps, function(x){
      x + xlim(range.xlim) + ylim(range.ylim)
    })

    # 去除xy座标轴
    if (remove_axes) {
      library(ggeasy)
      ps <- lapply(ps, function(p){
        p + easy_remove_axes()
        # p + rremove("ylab") + rremove("xlab")
      })
    }
  }

  if (is.null(n_columns)) {
    n_columns = length(groups)
  }

  # https://github.com/kassambara/ggpubr/issues/347
  legend_max <- get_legend(ps[[group_has_the_maximum_value]], position = NULL)

  ps <- ggarrange(plotlist = ps, common.legend = TRUE, legend="right", ncol = n_columns, legend.grob = legend_max)
  annotate_figure(ps, left = text_grob(feature, face = "italic", size = 10))
}






