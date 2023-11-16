#' @title 修正HGNC的Multi-symbol checker工具的输出结果
#' @description
#'  HGNC 提供的[Multi-symbol checker在线工具](https://www.genenames.org/tools/multi-symbol-checker/)可以将基因名更新到最新,
#'  但是会输出所有匹配的结果,也就是说单个input gene可能会有多个hits.此工具可保留主要匹配结果,去除可能的错误hits以及未必对上的input.
#'
#' @param hgnc.hits HGNC在线工具'Multi-symbol checker'的结果, A data.frame
#'
#' @return A data.frame for UniqueHit or A list with two data.frame for UniqueHit and MultiHit
#' @export

check_hgnc_hits <- function(hgnc.hits){ # check the multi-hits from HNGC gene symbol mapping results
  # HGNC数据库中ID和Approved.symbol都是唯一的
  # 检查一下input是否有重复值
  if (any(duplicated(paste0(hgnc.hits$Input, hgnc.hits$HGNC.ID)))) {
    warnings("发现有重复的Input，在使用在线工具前，应先去除重复的input。")
    hgnc.hits <- hgnc.hits[!duplicated(paste0(hgnc.hits$Input, hgnc.hits$HGNC.ID)),]
  }
  # 1. 去除未比对上的
  message("共计",length(unique(hgnc.hits$Input)),"个inputs.")
  print("Hit summary:");print(table(hgnc.hits$Match.type))
  message("1. 去除未能比对上的input, 共计", sum(hgnc.hits$Match.type == "Unmatched"),"个。")
  hgnc.hits <- hgnc.hits[hgnc.hits$Match.type != "Unmatched",]
  # 2. 比对到自己的
  self.hit <- hgnc.hits[toupper(hgnc.hits$Input) == toupper(hgnc.hits$Approved.symbol),]
  message("2. self-hit的input有", length(self.hit$Input),"个, Self hit summary:")
  print(table(self.hit$Match.type))
  hgnc.hits <- hgnc.hits[!hgnc.hits$Input %in% self.hit$Input,] # 去除自我匹配的

  # 3. 依据匹配类型的权重，去除一些hits
  # Previous symbol、Entry withdrawn和Approved symbol的权重 > Alias symbol，如果一个input既有 Previous symbol又有Alias symbol hits，那么删除Alias symbol hits。
  alias.match <- hgnc.hits[hgnc.hits$Match.type == "Alias symbol",]
  if (nrow(alias.match) != 0) {
    other.match <- hgnc.hits[hgnc.hits$Match.type != "Alias symbol",]
    alias.match.dups <- sum(alias.match$Input %in% other.match$Input)
    if (alias.match.dups != 0) {
      message(alias.match.dups, "条hits被去除，因其match type为Alias symbol，但对应的input还有其他匹配类型！")
      alias.match <- alias.match[!alias.match$Input %in% other.match$Input,]
      hgnc.hits <- rbind(other.match, alias.match)
    }
  }
  # 4. 只匹配到一个的
  single.hits <- hgnc.hits[!hgnc.hits$Input %in% hgnc.hits$Input[duplicated(hgnc.hits$Input)],]
  message("3. 唯一hit的input有", nrow(single.hits),"个, Single Hit Summary:")
  print(table(single.hits$Match.type))
  if (any(duplicated(single.hits$HGNC.ID))) {
    dups <- single.hits[single.hits$HGNC.ID %in% c(single.hits$HGNC.ID[duplicated(single.hits$HGNC.ID)], self.hit$HGNC.ID),]
    warning("注意，唯一hit得到的结果中，有", length(dups$Input),"个inputs被hit到相同基因上(Self and Single Hit results)！")
    # print(dups[order(dups$HGNC.ID),])
    # stop("注意：单个hit的基因更新后，有重复的更新值！")
  }
  # 5. hit到多个的
  mult.hits <- hgnc.hits[hgnc.hits$Input %in% hgnc.hits$Input[duplicated(hgnc.hits$Input)],]
  message("4. 共计", length(unique(mult.hits$Input)),"个input有多个hits！")
  # 对于multiple hits: 基因名更新后不变的最优先
  if (nrow(mult.hits) != 0) {
    # 剩余的基因中，依据更新后的基因名，去除hit到已有基因上的（比对到自己的、单一的的基因名）
    warning("仍有",length(unique(mult.hits$Input)), "个input无法确定唯一best hit!")
    # 过滤后，进一步寻找唯一hit的input
    return(list(UniqueHit = rbind(self.hit, single.hits), MultiHit = mult.hits))
  }else{
    return(rbind(rbind(self.hit, single.hits)))
  }
}
