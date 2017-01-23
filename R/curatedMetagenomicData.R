#' Title curatedMetagenomicData
#'
#' @param x
#' A character vector of dataset names, regexes, or globs, that will be matched
#' to available datasets. If x.is.glob is TRUE (default), wildcards such as "*"
#' and "?" are supported (see ?glob2rx), otherwise, regexes are supported (see
#' ?grep)
#' @param counts = FALSE
#' If TRUE, relative abundances will be multiplied by read depth, then rounded to
#' the nearest integer.
#' @param bugs.as.phyloseq = FALSE 
#' If TRUE, tables of taxonomic abundance (metaphlan datasets) will be converted
#' to phyloseq objects for use with the phyloseq package.
#' @param x.is.glob = TRUE
#' Set to FALSE to actually download the datasets
#'
#' @return
#' A list of ExpressionSet and/or phyloseq objects
#' @export
#' curatedMetagenomicData
#' @examples
#' curatedMetagenomicData()
#' curatedMetagenomicData("ZellerG*")
#' curatedMetagenomicData("ZellerG.+marker", x.is.glob=FALSE)
#' curatedMetagenomicData("ZellerG_2014.metaphlan_bugs_list.stool", dryrun=FALSE)
#' curatedMetagenomicData("ZellerG_2014.metaphlan_bugs_list.stool", 
#'         counts=TRUE, dryrun=FALSE, bugs.as.phyloseq=TRUE)
curatedMetagenomicData <- function(x = "*",
           dryrun = TRUE,
           counts = FALSE,
           bugs.as.phyloseq = FALSE,
           x.is.glob = TRUE) {
    requested.datasets <- x
    all.datasets <- ls("package:curatedMetagenomicData")
    all.datasets <-
      grep("marker|gene|path|metaphlan_bugs", all.datasets, val = TRUE)
    regex <-
      ifelse(x.is.glob,
             paste(glob2rx(requested.datasets), collapse = "|"),
             requested.datasets)
    matched.datasets <- grep(regex, all.datasets, value = TRUE)
    if (dryrun) {
      message("Dry run: see return values for datasets that would be downloaded. Run with `dryrun=FALSE` to actually download these datasets.")
      return(matched.datasets)
    }
    if (!any(matched.datasets %in% all.datasets))
      stop("requested datasets do not match any available datasets.")
    eset.list <- lapply(seq_along(matched.datasets), function(i) {
      message(paste0("Working on ", matched.datasets[i]))
      eset <- do.call(get(matched.datasets[i]), list())
      if (counts) {
        exprs(eset) <-
          round(sweep(exprs(eset), 2, eset$number_reads / 100, "*"))
      }
      if(bugs.as.phyloseq && grepl("metaphlan", matched.datasets[i])){
        eset <- ExpressionSet2phyloseq(eset)
      }
      return(eset)
    })
    names(eset.list) <- matched.datasets
    return(eset.list)
  }