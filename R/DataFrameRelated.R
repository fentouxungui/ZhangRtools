#' 基于某列的重复值，对其他所有行进行字符串拼接【压缩行】
#' @description
#'  以字符串转表达式方式，实现数据分组以及各列数据的字符串拼接。只能基于一列进行分组，对重复数据的其他列进行字符串的拼接，使用“; ”进行分隔。
#'  主要是简少了dplyr中的summarise function对于多列数据执行同一操作的代码量。
#'  参考[Paste values in a data frame based on duplicated values in other columns in R](https://stackoverflow.com/questions/51579405/paste-values-in-a-data-frame-based-on-duplicated-values-in-other-columns-in-r)
#'  注意，此函数目前只能对各列执行同一操作！不能对不同列执行不同的function。
#'
#'
#' @param df A data.frame
#' @param id 用于分组的列（有重复值的列）
#'
#' @return A data.frame
#' @export
#'
#' @import dplyr
#' @examples
#' dt <- data.frame(genotype = c("X1", "X2", "X3", "X4", "X5", "X6", "X7",  "X8", "X1", "X2", "X3",
#'                               "X4","X5", "X6", "X7",  "X8", "X1", "X2", "X3", "X4", "X5", "X6",
#'                               "X7",  "X8"),
#'                   variable = c("A", "A", "A", "A", "A", "A", "A", "A", "B", "B", "B", "B",
#'                               "B", "B", "B", "B", "C", "C", "C", "C", "C", "C", "C", "C"),
#'                   value = c(1L, 1L, 2L, 3L, 4L, 5L, 6L, 7L, 1L, 2L, 3L, 3L,  3L, 4L, 5L, 5L,
#'                          1L, 2L, 3L, 4L, 5L, 6L, 7L, 8L), stringsAsFactors = FALSE)
#' dt
#'
#' Aggregate_df(df = dt, id = colnames(dt)[1])
#' # 基于两列进行重复值处理
#' # library(dplyr)
#' # dt %>% group_by(variable, value) %>%
#' #  mutate(lab = toString(genotype)) %>%
#' #  as.data.frame()
#'
#'
Aggregate_df <- function(df, id){
  columns <- setdiff(colnames(df), id)
  if (is.data.frame(df)) {
    if (id %in% colnames(df)) {
      requireNamespace("dplyr")
      requireNamespace("magrittr")
      # 使用 parse() 函数将字符串转化为表达式（expression），可以减少代码量，否则需要把每列的处理代码都写出来！
      summarise_string <- paste("df %>% dplyr::group_by(",id,") %>% dplyr::summarise(", paste(paste(columns,"=paste0(",columns,", collapse = '; ')"),collapse = ", "),")")
      as.data.frame(eval(parse(text = summarise_string)))
    }else{
      stop("id and columns must exist in column names of df.")
    }
  }else{
    stop("df must be a data frame.")
  }
}


#' 基于某列的字符串切割，扩展其他所有行【扩展行】
#' @description
#'  以字符串转表达式方式，实现某列字符串数据切割和行扩展。只能基于一列进行字符串切割。
#'
#' @param df A data.frame
#' @param id 用于字符换切割的列
#' @param splitby 字符串切割时的分隔符
#'
#' @return A data.frame with more rows
#' @export
#'
#' @examples
#' #NULL
Expand_df <- function(df, id, splitby = "/"){
  temp.list <- split(df,df[,id])
  columns <- setdiff(colnames(df), id)
  temp.list <- lapply(temp.list, function(x){
    # 使用 parse() 函数将字符串转化为表达式（expression），可以减少代码量，否则需要把每列的处理代码都写出来
    dataframe_string <- paste("data.frame(", paste0(paste(columns, "= ",columns, sep = " "),collapse = ", "), ",", id, "= unlist(strsplit(", id, ", split = '",splitby,"')))",sep = "")
    return(eval(parse(text = dataframe_string), envir = as.list(x)))
  })
  return(Reduce(rbind, temp.list))
}

