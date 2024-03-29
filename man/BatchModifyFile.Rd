% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/BatchModifyFiles.R
\name{BatchModifyFile}
\alias{BatchModifyFile}
\title{批量修改某类文件里的内容}
\usage{
BatchModifyFile(
  Directory,
  FileNamePattern,
  LineMatchKeyWords,
  LineMatch.ignore.case = FALSE,
  WordOld,
  WordNew,
  Replace = FALSE,
  SummaryFile = paste0("BatchModifyFile.summary.", format(Sys.time(),
    "\%Y-\%b-\%d-\%H:\%M:\%S"), ".csv"),
  SaveOld = TRUE
)
}
\arguments{
\item{Directory}{文件夹,待查文件的检索范围,一个字符串}

\item{FileNamePattern}{待查文件的文件名,使用正则表达式进行匹配,一个字符串}

\item{LineMatchKeyWords}{用于寻找要被修改的行,一个关键词向量}

\item{LineMatch.ignore.case}{依据关键词寻找要被修改的行时,是否需要忽略行关键
词的大小写,一个逻辑值}

\item{WordOld}{要被替换的词,一个字符串}

\item{WordNew}{新词,一个字符串}

\item{Replace}{是否要执行替换,一个逻辑值}

\item{SummaryFile}{文件名,用于输出各个文件的匹配和替换信息}

\item{SaveOld}{是否保存旧文件,一个逻辑值}
}
\value{
csv文件,包含各个文件的匹配和替换信息
}
\description{
以逐行读取的形式,对目标文件中的内容进行文字替换。
}
\examples{
# Not run
# BatchModifyFile(Directory = "./shiny-server/PublicData/scRNAseq",
# FileNamePattern = "^Parameters.R$",
# LineMatchKeyWords = c("SplitBy.levels.max","15"),
# LineMatch.ignore.case = FALSE,
# WordOld = "SplitBy.levels.max <- 15",
# WordNew = "SplitBy.levels.max <- 50",
# Replace = TRUE,
# SaveOld = TRUE)

}
\seealso{
Other Modify Files: 
\code{\link{ModifyFile}()}
}
\concept{Modify Files}
