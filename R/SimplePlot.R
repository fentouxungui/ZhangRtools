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

