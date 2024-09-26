#' 合并某列的重复值，对其他所有行进行字符串拼接 - 压缩行
#' @description
#'  以字符串转表达式方式，实现数据分组以及各列数据的字符串拼接。只能基于一列进行分组，对重复数据的其他列进行字符串的拼接，使用“; ”进行分隔。
#'  主要是简少了dplyr中的summarise function对于多列数据执行同一操作的代码量。
#'  参考[Paste values in a data frame based on duplicated values in other columns in R](https://stackoverflow.com/questions/51579405/paste-values-in-a-data-frame-based-on-duplicated-values-in-other-columns-in-r)
#'  注意，此函数目前只能对各列执行同一操作！不能对不同列执行不同的function。
#'
#' @family Data Frame Related
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



#' 对某列进行字符串切割，复制其他所有行 - 扩展行
#' @description
#'  以字符串转表达式方式，实现某列字符串数据切割和行扩展。只能基于一列进行字符串切割。
#'
#' @family Data Frame Related
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

#' 基于数据库，对ID向量进行转换，返回更新后的向量
#' @description
#' NA值或空字符串会返回NA值，ID向量里的单个元素可以是多个ID的组合。
#' 注意：BiologyDB包依赖此函数，勿轻易修改
#'
#' @param old 要被转换的id向量，元素可以是多个id名的组合，用| ；或其它符号隔开。
#' @param db 注释数据库，包含旧名和新名
#' @param from 注释数据库中对应原来ID的列名
#' @param to 注释数据库中新ID的列名
#' @param split 如果ID向量为多id组合的，需要指定分割符号，默认为NULL，即为单个ID，无需分割
#' @param fixed 默认TRUE，strsplit函数的参数
#'
#' @return 转换后的向量
#' @export
#'
#' @examples
#' #NULL
update_IDs <- function(old, db = ADataframe, from = NULL, to = NULL, split = NULL, fixed = TRUE){
  if (any(duplicated(db[,from]))) {
    warning("from列有重复值，仅保留第一个出现的ID。")
    db <- db[!duplicated(db[,from]),]
  }
  mapping <- db[,to]
  names(mapping) <- db[,from]

  res <- c()
  for (i in old) {
    if (is.null(split)) {
      res <- append(res, mapping[i])
    }else{
      if (is.na(i)) {
        res <- append(res, NA)
      }else{
        old.vector <- trimws(unlist(strsplit(i, split = split, fixed = fixed)))
        res <- append(res, paste0(mapping[old.vector], collapse = ";"))
      }
    }
  }
  return(unname(res))
}

#' 基于多个关键词更新数据框
#' @description
#' 依据数据库信息，和至多3种ID，更新数据。返回1个list，包含两个数据框，第一个matched：更新后的数据框，第二个lost，不能被识别的行。
#' 注意：该函数值更新了第一个关键词，即by.input列。另外，该函数在后两轮匹配时，会输出重复匹配的条目。
#' 注意：BiologyDB包依赖此函数，勿轻易修改
#'
#' @param inputDF 要被更新的数据框
#' @param db 数据库
#' @param by.input 数据框里的第一识别列（也是要被更新的列）
#' @param by.db 数据库里的第一识别列的对应列
#' @param by.input.2 数据框里的第二识别列，当第一识别列不能被识别时才启用（不会被更新），可以为NULL
#' @param by.db.2 数据库里的第二识别列的对应列，可以为NULL
#' @param by.input.3 数据框里的第三识别列，当第一和第二识别列均不能被识别时才启用（不会被更新），可以为NULL
#' @param by.db.3 数据库里的第三识别列的对应列，可以为NULL
#' @param label 默认为TRUE，添加label列，表征被第几个关键词所识别
#' @param verbose 是否输出被第二、三个关键词匹配的条目的详细信息，用于人工校验准确性。
#'
#' @return A list，包含两个数据框，第一个matched：更新后的数据框，第二个lost，不能被识别的行.可能的问题：1. 如果两个ensembl id对应同一个HGNC，那么第二轮
#' 用HGNC匹配时，可能仅能匹配到一个Ensebmbl id。同理第三轮匹配也是。
#' @export
#'
#' @examples
#' #NULL
mapping_update <- function(inputDF, db = ADataframe, by.input = NULL, by.db = NULL, by.input.2 = NULL, by.db.2 = NULL,by.input.3 = NULL, by.db.3 = NULL, label = TRUE,
                           verbose = TRUE){
  message(paste0("1. 依据input里的",by.input,"列和数据库里的",by.db,"列进行数据比对:"))
  check_db <- function(db, column){ # 依据某一列，去除重复行。
    if(any(duplicated(db[,column]))){
      warning("数据库中的",column,"列发现有重复值，仅保留第一个出现的值。")
      return(db[!duplicated(db[,column]),])
    }else{
      return(db)
    }
  }
  ###### First match
  db.1 <- check_db(db, column = by.db)
  mapped <- inputDF[inputDF[,by.input] %in% db.1[,by.db],]
  if (nrow(mapped) == 0) { stop("0行可被匹配，请检查对应列的设置是否正确！") }
  if (label) { mapped$label = "First" } # 标记为被第一个关键词匹配上的
  lost <- inputDF[!inputDF[,by.input] %in% db.1[,by.db],]
  message(paste0(nrow(lost),"行未被对应上。"))
  if(nrow(lost) == 0 | is.null(by.input.2) | is.null(by.db.2)){ # 仅靠一列识别
    return(list(matched = mapped, lost = lost))
  }else{
    ############ Second match
    message(paste0("2. 依据input里的",by.input.2,"列和数据库里的",by.db.2,"列对未匹配的数据再次进行比对:"))
    db.2 <- check_db(db, column = by.db.2)
    lost.mapped <- lost[lost[,by.input.2] %in% db.2[,by.db.2],]
    if (nrow(lost.mapped) != 0) {
      if(label){lost.mapped$label = "Second" }  # 标记为被第二个关键词匹配上的
      if(verbose){message("请手动检查以下替换是否正确！")}
      if(verbose){message("替换前：")}
      if(verbose){print(lost.mapped[,c(by.input, by.input.2, by.input.3)])}
      lost.mapped[,by.input] <- db.2[,by.db][match(lost.mapped[,by.input.2], db.2[,by.db.2])] #修改第一个关键词
      if(verbose){message("替换后：")}
      if(verbose){print(lost.mapped[,c(by.input, by.input.2, by.input.3)])}
      if(any(lost.mapped[,by.input] %in% mapped[,by.input])){
        message("注意：以下条目与第一次匹配到的条目有重复。")
        print(lost.mapped[lost.mapped[,by.input] %in% mapped[,by.input],c(by.input, by.input.2, by.input.3)])
      }
    }
    lost.lost <- lost[!lost[,by.input.2] %in% db.2[,by.db.2],]
    message(paste0(nrow(lost.lost),"行未被对应上。"))
    if (nrow(lost.lost) == 0 | is.null(by.input.3) | is.null(by.db.3)) { # 仅靠两列识别
      if(nrow(lost.mapped) != 0){return(list(matched = rbind(mapped, lost.mapped), lost = lost.lost))
      }else{return(list(matched = mapped, lost = lost.lost))}
    }else{
      ########### Third match
      message(paste0("3. 依据input里的",by.input.3,"列和数据库里的",by.db.3,"列对未匹配的数据再次进行比对:"))
      db.3 <- check_db(db, column = by.db.3)
      lost.lost.mapped <- lost.lost[lost.lost[,by.input.3] %in% db.3[,by.db.3],]
      if (nrow(lost.lost.mapped) != 0) {
        if(label) { lost.lost.mapped$label = "Third" }   # 标记为被第三个关键词匹配上的
        if(verbose){message("请手动检查以下替换是否正确！")}
        if(verbose){message("替换前：")}
        if(verbose){print(lost.lost.mapped[,c(by.input, by.input.2, by.input.3)])}
        lost.lost.mapped[,by.input] <- db.3[,by.db][match(lost.lost.mapped[,by.input.3], db.3[,by.db.3])] # 修改第一个关键词
        # lost.lost.mapped[,by.input.2] <- db.3[,by.db.2][match(lost.lost.mapped[,by.input.3], db.3[,by.db.3])] # 修改第二个关键词
        if(verbose){message("替换后：")}
        if(verbose){print(lost.lost.mapped[,c(by.input, by.input.2, by.input.3)])}
        if(any(lost.lost.mapped[,by.input] %in% mapped[,by.input])){
          message("注意：以下条目与第一次匹配到的条目有重复。")
          print(lost.lost.mapped[lost.lost.mapped[,by.input] %in% mapped[,by.input],c(by.input, by.input.2, by.input.3)])
        }
        if(any(lost.lost.mapped[,by.input] %in% lost.mapped[,by.input])){
          message("注意：以下条目与第二次匹配到的条目有重复。")
          print(lost.lost.mapped[lost.lost.mapped[,by.input] %in% lost.mapped[,by.input],c(by.input, by.input.2, by.input.3)])
        }
      }
      lost.lost.lost <- lost.lost[!lost.lost[,by.input.3] %in% db.3[,by.db.3],]
      message(paste0(nrow(lost.lost.lost),"行未被对应上。"))
      matched = list(mapped, lost.mapped, lost.lost.mapped)
      matched <- matched[c(TRUE, nrow(lost.mapped) > 0, nrow(lost.lost.mapped) > 0)]
      matched <- Reduce(rbind, matched)
      return(list(matched = matched, lost = lost.lost.lost))
    }
  }
}


#' 基于多个关键词合并两个数据
#' @description
#' 与mapping_update的区别，mapping_join不会修改原来的数据，只是在原来数据的基础上，添加新数据到新的列中。
#' 依据多对关键词，合并两个数据。返回1个list，包含两个数据框，第一个matched：合并后的数据框，第二个lost，不能被识别的行。
#' 注意：该函数的第一个关键词，即by.input列，应为绝大多数能被匹配上的。关键词可以重复使用，每次的关键词对不同即可。另外，该函数在后两轮匹配时，会输出重复匹配的条目。
#' 关键词匹配是有优先顺序的，第一次被匹配上了，后续就不会再去做匹配。
#'
#' @param inputDF 原数据框
#' @param db 要被加进来的数据
#' @param by.input 原数据框里的第一识别列（也是要被更新的列）
#' @param by.db 新数据框里的第一识别列的对应列
#' @param by.input.2 原数据框里的第二识别列，当第一识别列不能被识别时才启用（不会被更新），可以为NULL
#' @param by.db.2 新数据框里的第二识别列的对应列，可以为NULL
#' @param by.input.3 原数据框里的第三识别列，当第一和第二识别列均不能被识别时才启用（不会被更新），可以为NULL
#' @param by.db.3 新数据框里的第三识别列的对应列，可以为NULL
#' @param label 默认为TRUE，添加label列，表征被第几对关键词所识别
#' @param verbose 是否输出被第二、三个关键词匹配的条目的详细信息，用于人工校验准确性。
#'
#' @return A list，包含两个数据框，第一个matched：合并后的数据框，第二个lost，不能被识别的行.可能的问题：1. 如果两个ensembl id对应同一个HGNC，那么第二轮
#' 用HGNC匹配时，可能仅能匹配到一个Ensebmbl id。同理第三轮匹配也是。
#' @export
#'
#' @examples
#' #NULL
mapping_join <- function(inputDF, db = ADataframe, by.input = NULL, by.db = NULL, by.input.2 = NULL, by.db.2 = NULL,by.input.3 = NULL, by.db.3 = NULL, label = TRUE,
                         verbose = TRUE){
  message(paste0("1. 依据input里的",by.input,"列和数据库里的",by.db,"列进行数据比对:"))
  check_db <- function(db, column){ # 依据某一列，去除重复行。
    if(any(duplicated(db[,column]))){
      warning("数据库中的",column,"列发现有重复值，仅保留第一个出现的值。")
      return(db[!duplicated(db[,column]),])
    }else{
      return(db)
    }
  }
  ###### First match
  db.1 <- check_db(db, column = by.db)
  mapped <- inputDF[inputDF[,by.input] %in% db.1[,by.db],]
  if (nrow(mapped) == 0) { stop("0行可被匹配，请检查对应列的设置是否正确！") }
  db.1.sub <- db.1[match(mapped[,by.input], db.1[,by.db]),]
  mapped <- cbind(mapped, db.1.sub)
  if (label) { mapped$label = paste("First",by.input,by.db, sep = "_") } # 标记为被第一个关键词匹配上的
  lost <- inputDF[!inputDF[,by.input] %in% db.1[,by.db],]
  message(paste0(nrow(lost),"行未被对应上。"))
  if(nrow(lost) == 0 | is.null(by.input.2) | is.null(by.db.2)){ # 仅靠一列识别
    return(list(matched = mapped, lost = lost))
  }else{
    ############ Second match
    message(paste0("2. 依据input里的",by.input.2,"列和数据库里的",by.db.2,"列对未匹配的数据再次进行比对:"))
    db.2 <- check_db(db, column = by.db.2)
    lost.mapped <- lost[lost[,by.input.2] %in% db.2[,by.db.2],]
    if (nrow(lost.mapped) != 0) {
      db.2.sub <- db.2[match(lost.mapped[,by.input.2], db.2[,by.db.2]),]
      lost.mapped <- cbind(lost.mapped, db.2.sub)
      if(label){lost.mapped$label = paste("Second",by.input,by.db, sep = "_") }  # 标记为被第二个关键词匹配上的
      if(verbose){message("请手动检查以下替换是否正确！")}
      if(verbose){message("替换前：")}
      if(verbose){print(lost.mapped[,c(by.input, by.input.2, by.input.3)])}
      if(verbose){message("替换后：")}
      if(verbose){print(lost.mapped[,c(by.input, by.input.2, by.input.3)])}
      if(any(lost.mapped[,by.input] %in% mapped[,by.input])){
        message("注意：以下条目与第一次匹配到的条目有重复。")
        print(lost.mapped[lost.mapped[,by.input] %in% mapped[,by.input],c(by.input, by.input.2, by.input.3)])
      }
    }
    lost.lost <- lost[!lost[,by.input.2] %in% db.2[,by.db.2],]
    message(paste0(nrow(lost.lost),"行未被对应上。"))
    if (nrow(lost.lost) == 0 | is.null(by.input.3) | is.null(by.db.3)) { # 仅靠两列识别
      if(nrow(lost.mapped) != 0){return(list(matched = rbind(mapped, lost.mapped), lost = lost.lost))
      }else{return(list(matched = mapped, lost = lost.lost))}
    }else{
      ########### Third match
      message(paste0("3. 依据input里的",by.input.3,"列和数据库里的",by.db.3,"列对未匹配的数据再次进行比对:"))
      db.3 <- check_db(db, column = by.db.3)
      lost.lost.mapped <- lost.lost[lost.lost[,by.input.3] %in% db.3[,by.db.3],]
      if (nrow(lost.lost.mapped) != 0) {
        db.3.sub <- db.3[match(lost.lost.mapped[,by.input.3], db.3[,by.db.3]),]
        lost.lost.mapped <- cbind(lost.lost.mapped, db.3.sub)
        if(label) { lost.lost.mapped$label = "Third" }   # 标记为被第三个关键词匹配上的
        if(verbose){message("请手动检查以下替换是否正确！")}
        if(verbose){message("替换前：")}
        if(verbose){print(lost.lost.mapped[,c(by.input, by.input.2, by.input.3)])}
        if(verbose){message("替换后：")}
        if(verbose){print(lost.lost.mapped[,c(by.input, by.input.2, by.input.3)])}
        if(any(lost.lost.mapped[,by.input] %in% mapped[,by.input])){
          message("注意：以下条目与第一次匹配到的条目有重复。")
          print(lost.lost.mapped[lost.lost.mapped[,by.input] %in% mapped[,by.input],c(by.input, by.input.2, by.input.3)])
        }
        if(any(lost.lost.mapped[,by.input] %in% lost.mapped[,by.input])){
          message("注意：以下条目与第二次匹配到的条目有重复。")
          print(lost.lost.mapped[lost.lost.mapped[,by.input] %in% lost.mapped[,by.input],c(by.input, by.input.2, by.input.3)])
        }
      }
      lost.lost.lost <- lost.lost[!lost.lost[,by.input.3] %in% db.3[,by.db.3],]
      message(paste0(nrow(lost.lost.lost),"行未被对应上。"))
      matched = list(mapped, lost.mapped, lost.lost.mapped)
      matched <- matched[c(TRUE, nrow(lost.mapped) > 0, nrow(lost.lost.mapped) > 0)]
      matched <- Reduce(rbind, matched)
      return(list(matched = matched, lost = lost.lost.lost))
    }
  }
}
