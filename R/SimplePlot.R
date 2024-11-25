#' David富集结果绘图 柱状图
#'
#' @param df David富集结果, A data.frame
#' @param term.prefix Term列中的前缀，会被去除
#' @param fill.color 柱子的颜色,一个向量，分别对应最低值和最高值
#' @param show.top 要展示的Term数目
#' @param x X轴的映射
#' @param xlabel X轴的标签
#' @param arrange.by.x Term是否按照X轴的值进行排序，默认是按照PValue排序的
#' @param decresing 排序方式默认为降序
#'
#' @return a ggplot2 plot
#' @export
#'
#' @import ggplot2
#'
#' @examples
#' requireNamespace("dplyr")
#' requireNamespace("ggplot2")
#' df <- read.delim(system.file("extdata", "David_outputs_GO.txt",
#' package = "ZhangRtools"), stringsAsFactors = FALSE)
#' David_barplot(df, fill.color = c("#ff9999","#ff0000"),x = "Fold.Enrichment",
#'  xlabel = "Fold Enrichment")
#' David_barplot(df, x = "Fold.Enrichment", xlabel = "Fold Enrichment",
#' arrange.by.x = TRUE)
#' df %>% dplyr::mutate(fdr = -log(FDR, base=10)) %>% David_barplot(x = "fdr",
#' xlabel = "-log(10)FDR")
#' kegg.res <- read.delim(system.file("extdata", "David_outputs_KEGG.txt",
#' package = "ZhangRtools"), stringsAsFactors = FALSE)
#' David_barplot(df = kegg.res,  fill.color = c("#ff9999","#ff0000"),
#' x = "Fold.Enrichment", xlabel = "Fold Enrichment")
David_barplot <- function(df,
                          term.prefix = c("(^GO:\\d+~)|(^\\w+\\d+[:~])"),
                          fill.color = c("blue","red"),
                          show.top = 10,
                          x = "Count",
                          xlabel = "Gene Counts",
                          arrange.by.x = FALSE,
                          decresing = TRUE){
  requireNamespace("ggplot2")
  # 去除Term的前缀
  df$TermShort <- gsub(term.prefix,"",df$Term)
  # 1. 过滤和排序，仅保留前多少个
  df <- df[order(df[,"PValue"], decreasing = FALSE),]
  if (nrow(df) > show.top) {
    df <- df[1:show.top, ]
  }
  # 2. 行重新排序
  if (arrange.by.x) {
    df <- df[order(df[,x],decreasing = decresing),]
  }
  # 3. 提取和重命名列
  df <- df[,c("TermShort", "PValue", x)]
  colnames(df) <- c("term", "PValue", "xvalue")
  df$term <- factor(df$term,levels = rev(df$term))
  ggplot(data=df)+
    geom_bar(aes(x= term, y= xvalue, fill=-log10(PValue)), stat='identity') +
    coord_flip() +
    scale_fill_gradient(expression(-log["10"](PValue)),low=fill.color[1], high = fill.color[2]) +
    xlab("") +
    ylab(xlabel) +
    scale_y_continuous(expand=c(0, 0))+
    theme(
      axis.text.x=element_text(color="black",size=rel(1.5)),
      axis.text.y=element_text(color="black", size=rel(1.6)),
      axis.title.x = element_text(color="black", size=rel(1.6)),
      legend.text=element_text(color="black",size=rel(1.0)),
      legend.title = element_text(color="black",size=rel(1.1))
      # legend.position=c(0,1),legend.justification=c(-1,0)
      # legend.position="top",
    )
}


#' David富集结果绘图 气泡图
#'
#' @param df David富集结果, A data.frame
#' @param term.prefix Term列中的前缀，会被去除
#' @param fill.color  柱子的颜色,一个向量，分别对应最低值和最高值
#' @param show.top 要展示的Term数目
#' @param x X轴的映射
#' @param pt.size 点大小的映射
#' @param xlabel X轴的标签
#' @param size.label Legend点大小的label
#' @param arrange.by.x Term是否按照X轴的值进行排序，默认是按照PValue排序的
#' @param decresing 排序方式默认为降序
#'
#' @return a ggplot2 plot
#' @export
#' @import ggplot2
#'
#' @examples
#' requireNamespace("dplyr")
#' requireNamespace("ggplot2")
#' df <- read.delim(system.file("extdata", "David_outputs_KEGG.txt",
#' package = "ZhangRtools"), stringsAsFactors = FALSE)
#' David_dotplot(df)
#' David_dotplot(df, arrange.by.x = TRUE)
David_dotplot <- function(df,
                          term.prefix = c("(^GO:\\d+~)|(^\\w+\\d+[:~])"),
                          fill.color = c("blue","red"),
                          show.top = 10,
                          x = "Fold.Enrichment",
                          pt.size = "Count",
                          xlabel = "Fold Enrichment",
                          size.label = "Gene number",
                          arrange.by.x = FALSE,
                          decresing = TRUE){
  requireNamespace("ggplot2")
  # 去除Term的前缀
  df$TermShort <- gsub(term.prefix,"",df$Term)
  # 1. 过滤和排序，仅保留前多少个
  df <- df[order(df[,"PValue"], decreasing = FALSE),]
  df <- df[order(df[,"PValue"], decreasing = FALSE),]
  if (nrow(df) > show.top) {
    df <- df[1:show.top, ]
  }
  # 2. 行重新排序
  if (arrange.by.x) {
    df <- df[order(df[,x],decreasing = decresing),]
  }
  # 3. 提取和重命名列
  df <- df[,c("TermShort", "PValue", x, pt.size)]
  colnames(df) <- c("term", "PValue", "xvalue", "size")
  df$term <- factor(df$term,levels = rev(df$term))
  ggplot(df, aes(x = term, y = xvalue)) +
    geom_point(aes(size = size, color = -1*log10(PValue))) +
    coord_flip() +
    scale_colour_gradient(low=fill.color[1], high = fill.color[2])+
    labs(color=expression(-log[10](P.value)),
         size = size.label,
         y = xlabel ) +
    theme_bw() +
    theme(axis.text.y = element_text(size = rel(1.3)),
          axis.title.x = element_text(size=rel(1.3)),
          axis.title.y = element_blank()
    )
}


#' 火山图 风格一
#'
#' @param data a data.frame with columns: gene, pval, lfc, 默认lfc以2为底
#' @param markers genes in gene column to be labeled
#' @import ggplot2 dplyr ggrepel
#' @return a plot
#' @export
#'
#' @examples
#' # null
Volcano_plot_1 <- function(plot.data, markers, pvalue.cutoff = 0.05, lfc.cutoff = 1, x.lim = c(-10,10)){
  requireNamespace("ggplot2")
  requireNamespace("dplyr")
  requireNamespace("ggrepel")

  # Remove any rows that have NA as an entry
  plot.data <- na.omit(plot.data)
  markers.up <- markers[markers %in% plot.data$gene[plot.data$lfc > 0]]
  markers.down <- markers[markers %in% plot.data$gene[plot.data$lfc < 0]]
  # # Color the points which are up or down
  # plot.data <- mutate(plot.data, color = case_when(plot.data$lfc > lfc.cutoff & plot.data$pval > -log10(pvalue.cutoff) ~ paste0("Increased (log2(FC) > ", lfc.cutoff, ")"),
  #                                        plot.data$lfc < -lfc.cutoff & plot.data$pval > -log10(pvalue.cutoff) ~ paste0("Decreased (log2(FC) < -", lfc.cutoff,")"),
  #                                        plot.data$lfc >= -lfc.cutoff |  plot.data$lfc <= lfc.cutoff | plot.data$pval < -log10(pvalue.cutoff) ~ "nonsignificant"))
  # vol <- ggplot2::ggplot(plot.data, aes(x = lfc, y = pval, color = color))
  # Make a basic ggplot2 object with x-y values
  vol <- ggplot2::ggplot(plot.data, aes(x = lfc, y = pval))

  # Add ggplot2 layers
  vol +
    ggtitle(label = "Volcano Plot", subtitle = "Markers are colored by fold-change direction") +
    geom_hline(yintercept = log10(pvalue.cutoff), colour = "darkgrey") + # Add p-adj value cutoff line
    geom_vline(xintercept = c(-lfc.cutoff, lfc.cutoff), colour = "darkgrey") + # Add p-adj value cutoff line
    geom_point(size = 1.5, colour = "black", alpha = 0.1, na.rm = T) +
    # 设置一下上下调的颜色
    # upregulated markers
    geom_point(data = plot.data[plot.data$gene %in% markers.up,],colour = "red",cex = 2) +
    # geom_text(data = plot.data[plot.data$gene %in% markers.up,], aes(label = gene),colour = "blue",size = 4,position = position_dodge2(width = 1, padding = 0.5)) +
    geom_text_repel(data = plot.data[plot.data$gene %in% markers.up,], aes(label = gene),colour = "red",size = 4, position = position_dodge2(width = 1, padding = 0.5)) +
    # downregulated markers
    geom_point(data = plot.data[plot.data$gene %in% markers.down,],colour = "blue",cex = 2) +
    geom_text_repel(data = plot.data[plot.data$gene %in% markers.down,], aes(label = gene),colour = "blue",size = 4, position = position_dodge2(width = 1, padding = 0.5)) +
    # scale_color_manual(name = "Directionality",values = c("Increased (log2(FC) > 1)"= "red", "Decreased (log2(FC) < -1)" = "blue", "nonsignificant" = "darkgray")) +
    theme_bw(base_size = 14) + # change overall theme font size?
    theme(legend.position = "right") + # change the legend
    xlab(expression(log[2](case / control))) + # Change X-Axis label
    ylab(expression(-log[10]("adjusted p-value"))) + # Change Y-Axis label
    xlim(x.lim) +
    scale_y_continuous(trans = "log1p") # Scale yaxis due to large p-values
}




