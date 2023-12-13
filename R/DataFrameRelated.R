#' 对于重复行的各列，分别进行字符串拼接
#' @description
#'  以字符串转表达式方式，实现数据分组以及各列数据的字符串拼接。只能基于一列进行分组，对重复数据的其他列进行操作。
#'  参考[Paste values in a data frame based on duplicated values in other columns in R](https://stackoverflow.com/questions/51579405/paste-values-in-a-data-frame-based-on-duplicated-values-in-other-columns-in-r)
#'  注意，此函数目前只能对各列执行同一操作！不能对不同列执行不同的function。
#'
#'
#' @param df A data.frame
#' @param id 用于分组的列
#' @param columns 需要被处理的列，对于同一组的数据，对于各列进行字符串的拼接，使用“; ”进行分隔
#'
#' @return A data.frame
#' @export
#'
#' @examples
#' dt <- data.frame(genotype = c("X1", "X2", "X3", "X4", "X5", "X6", "X7",  "X8", "X1", "X2", "X3",
#'                               "X4","X5", "X6", "X7",  "X8", "X1", "X2", "X3", "X4", "X5", "X6", "X7",  "X8"),
#'                   variable = c("A", "A", "A", "A", "A", "A", "A", "A", "B", "B", "B", "B",
#'                               "B", "B", "B", "B", "C", "C", "C", "C", "C", "C", "C", "C"),
#'                   value = c(1L, 1L, 2L, 3L, 4L, 5L, 6L, 7L, 1L, 2L, 3L, 3L,  3L, 4L, 5L, 5L,
#'                          1L, 2L, 3L, 4L, 5L, 6L, 7L, 8L), stringsAsFactors = FALSE)
#' dt
#'
#' aggregate_df(df = dt, id = colnames(dt)[1], columns = colnames(dt)[2:3])
#' # 基于两列进行重复值处理
#' # library(dplyr)
#' # dt %>% group_by(variable, value) %>%
#' #  mutate(lab = toString(genotype)) %>%
#' #  as.data.frame()
#'
#'
aggregate_df <- function(df, id, columns){
  if (is.data.frame(df)) {
    if (all(c(id, columns) %in% colnames(df))) {
      require(dplyr)
      # 使用 parse() 函数将字符串转化为表达式（expression），可以减少代码量，否则需要把每列的处理代码都写出来！
      summarise_string <- paste("df %>% dplyr::group_by(",id,") %>% dplyr::summarise(", paste(paste(columns,"=paste0(",columns,", collapse = '; ')"),collapse = ", "),")")
      eval(parse(text = summarise_string))
    }else{
      stop("id and columns must exist in column names of df.")
    }
  }else{
    stop("df must be a data frame.")
  }
}
