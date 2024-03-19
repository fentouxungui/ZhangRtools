#' @title 批量修改某类文件里的内容
#' @description
#'  以逐行读取的形式,对目标文件中的内容进行文字替换。
#'
#' @family Modify Files
#'
#' @param Directory 文件夹,待查文件的检索范围,一个字符串
#' @param FileNamePattern 待查文件的文件名,使用正则表达式进行匹配,一个字符串
#' @param LineMatchKeyWords 用于寻找要被修改的行,一个关键词向量
#' @param LineMatch.ignore.case 依据关键词寻找要被修改的行时,是否需要忽略行关键
#' 词的大小写,一个逻辑值
#' @param WordOld 要被替换的词,一个字符串
#' @param WordNew 新词,一个字符串
#' @param Replace 是否要执行替换,一个逻辑值
#' @param SaveOld 是否保存旧文件,一个逻辑值
#' @param SummaryFile 文件名,用于输出各个文件的匹配和替换信息
#'
#' @return csv文件,包含各个文件的匹配和替换信息
#' @export
#'
#' @examples
#' # Not run
#' # BatchModifyFile(Directory = "./shiny-server/PublicData/scRNAseq",
#' # FileNamePattern = "^Parameters.R$",
#' # LineMatchKeyWords = c("SplitBy.levels.max","15"),
#' # LineMatch.ignore.case = FALSE,
#' # WordOld = "SplitBy.levels.max <- 15",
#' # WordNew = "SplitBy.levels.max <- 50",
#' # Replace = TRUE,
#' # SaveOld = TRUE)
#'
#' @import utils
#'
#'
BatchModifyFile <- function(Directory,
                            FileNamePattern,
                            LineMatchKeyWords,
                            LineMatch.ignore.case = FALSE,
                            WordOld,
                            WordNew,
                            Replace = FALSE,
                            SummaryFile = paste0("BatchModifyFile.summary.",
                                                 format(Sys.time(),
                                                        "%Y-%b-%d-%H:%M:%S"),
                                                 ".csv"),
                            SaveOld = TRUE){
  # 检查Directory是否存在
  if ( !dir.exists(Directory)) {
    # 中文消息可能在check时，提示警告non-ASCII characters， 这个忽略就可以，因为几乎所有电脑都支持non-ASCII characters。
    stop("错误,目录不存在!")
  }
  # 寻找包含关键词的所有文件
  input.files <- list.files(path = Directory, pattern = FileNamePattern,
                            full.names = TRUE, recursive = TRUE)
  if (length(input.files) == 0) {
    stop("基于设定的文件名pattern,找不到满足条件的文件!")
  }
  message(paste0(">>> 找到",length(input.files),"个文件..."))
  # 批量进行文件检索和修改
  summary.list <- lapply(input.files, function(x){
    ModifyFile(file = x,
               LineMatchKeyWords = LineMatchKeyWords,
               LineMatch.ignore.case = LineMatch.ignore.case,
               WordOld = WordOld,
               wordold.Matchfixed = TRUE,
               WordNew = WordNew,
               Replace = Replace,
               SaveOld = SaveOld,
               silence = TRUE,
               returnSummary = TRUE
    )
  })
  # 保存统计结果
  message(paste0(">>> 替换分析完成,详细统计结果见文件：", SummaryFile))
  summary.df <- Reduce(rbind, summary.list)
  write.csv(summary.df, file = SummaryFile, row.names = FALSE, quote = FALSE)
}


#' @title 修改单个文件里的内容
#' @description
#' 以逐行读取方式,对文件里的内容进行内容匹配和替换。
#'
#' @family Modify Files
#'
#' @param file 要被修改的文件,一个路径字符串
#' @param LineMatchKeyWords 用于寻找要被修改的行,一个关键词向量
#' @param LineMatch.ignore.case 依据关键词寻找要被修改的行时,是否需要忽略行
#' 关键词的大小写,一个逻辑值
#' @param WordOld 要被替换的词,一个字符串
#' @param wordold.Matchfixed 匹配要被替换的词时,是否需要设置为不使用正则表达式,
#' 一个逻辑值
#' @param WordNew 新词,一个字符串
#' @param Replace 是否要执行替换,一个逻辑值
#' @param SaveOld 是否要保存旧的文件,一个逻辑值
#' @param silence 是否屏蔽信息输出,一个逻辑值
#' @param returnSummary 是否输出替换统计结果,一个逻辑值,主要用于批量替换
#'
#' @return A data.frame of 匹配和替换信息 or Nothing
#' @export
#' @import utils
#' @examples
#' # Not Run
#' # ModifyFile(file = "./scRNAseq/Fly/Ovary/Fly-Ovary-Jevitt-PlosBiology-2020/
#' # Parameters.R",
#' # LineMatchKeyWords = c("SplitBy.levels.max","15"),
#' # LineMatch.ignore.case = FALSE,
#' # WordOld = "SplitBy.levels.max <- 15",
#' # wordold.Matchfixed = TRUE,
#' # WordNew = "SplitBy.levels.max <- 50",
#' # Replace = TRUE,
#' # SaveOld = TRUE,
#' # silence = FALSE,
#' # returnSummary = TRUE
#' # )
#'

ModifyFile <- function(file,
                       LineMatchKeyWords,
                       LineMatch.ignore.case = FALSE,
                       WordOld,
                       wordold.Matchfixed = TRUE,
                       WordNew,
                       Replace = FALSE,
                       SaveOld = TRUE,
                       silence = TRUE,
                       returnSummary = FALSE){
  # 检查文件是否存在
  if ( !file.exists(file)) {
    stop("错误,文件不存在!")
  }
  # 逐行读取,判断是否存在符合条件的行, 并进行简单统计
  con <- file(file, "r")
  line = readLines(con, n = 1)
  con.new <- c() # 存储修改后的内容
  LineMatched <- 0 # 匹配到的行数目
  LineMatchedContents <- c() # 行匹配成功后,原来的行内容
  LineMatchedContents.new <- c() # 行匹配成功后,被替换后的行内容
  Content.update <- 0 # 实际发生行替换的次数
  while( length(line) != 0 ) {
    # 基于行关键词进行匹配,判定是否
    LineIndex <- TRUE # 初始值为TRUE
    for (LineMatchKeyWord in LineMatchKeyWords) { # 循环匹配,修改LineIndex
      LineIndex <- LineIndex & grepl(LineMatchKeyWord, line,
                                     ignore.case = LineMatch.ignore.case)
    }
    if (LineIndex) { # LineIndex 仍为TRUE,表示改行成功匹配到了所有关键词
      LineMatched <- LineMatched + 1 # 匹配到的行数目+1
      LineMatchedContents <- c( LineMatchedContents, line)
      if (!silence) { message(paste0("找到了符合条件的第", LineMatched, "行：", line)) }
      if (grepl(WordOld, line, fixed = wordold.Matchfixed)) {
        line.new <- gsub(WordOld, WordNew, line, fixed = wordold.Matchfixed) # 新的行内容
        Content.update <- Content.update + 1 # 行替换次数加1
        if (!silence) { message(paste0("--并且找到了要被替换的内容,该行会被替换为：", line.new)) }
        LineMatchedContents.new <- c(LineMatchedContents.new, line.new)
        con.new <- append(con.new, line.new)
      }else{
        if (!silence) { message("--未找到要被替换的内容!") }
        con.new <- append(con.new, line)
      }
    }else{ # 该行未匹配到全部关键词
      con.new <- append(con.new, line)
    }
    line=readLines(con, n=1)
  }
  close(con = con)
  # 如果发生了替换,保存替换结果
  if (Replace & Content.update != 0) { # 如果发生了替换
    # 保存旧的结果
    if (SaveOld) {
      file.rename(from = file, to = paste0(file, ".", format(Sys.time(), "%Y-%b-%d-%H:%M:%S")))
    }else(
      file.remove(file)
    )
    # 写入新结果
    write.table(con.new, file = file, row.names = FALSE, quote = FALSE, col.names = FALSE)
    if (!silence) { message("文件已更新!") }
  }

  # 输出统计信息,适用于批量替换
  if (returnSummary) {
    return(data.frame("文件" = file,
                      "匹配到的行数目" = LineMatched,
                      "原行内容" = ifelse(length(LineMatchedContents) == 0, "-",
                                      paste0(LineMatchedContents,
                                             collapse = "<<||>>")),
                      "新行内容" = ifelse(length(LineMatchedContents.new) == 0,
                                      "-", paste0(LineMatchedContents.new,
                                                  collapse = "<<||>>")),
                      "内容替换次数" =  Content.update))
  }
}

















