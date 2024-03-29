#' Correct GCAM road transportation data to iso country.
#'
#' @param x a magpie data object
#' @param subtype One of the possible subtypes, see default argument.
#' @return magclass object
#'
#' @examples
#' \dontrun{
#' a <- readSource("GCAM", subtype="histEsDemand")
#' }
#' @author Alois Dirnaichner
#' @seealso \code{\link{readSource}}
#' @importFrom rmndt magpie2dt
#' @importFrom zoo na.approx
#' @importFrom data.table CJ `:=`
#' @importFrom magclass as.magpie
#' @export
correctGCAM <- function(x, subtype) {

  dt <- period <- region <- subsector <- value <-
    technology <- miss <- Units <- frTrain  <- NULL

  switch(
    subtype,
    "histEsDemand" = {
      dt <- magpie2dt(x)
      # HSR data decreases significantly in 2005 and falls to zero in 2010
      #-> that is not right and needs to be corrected
      #linear interpolation from first value in 1990 to value in 2015
      dt[period %in% c(2005, 2010) & region == "EU-12" & subsector == "HSR", value := NA]
      dt[region == "EU-12" & subsector == "HSR", value := na.approx(value, x = period),
                  by = c("region", "sector", "subsector", "technology")]

      ## Electric trains do not exist in certain countries and need to be listed as zero demand
      miss <- CJ(region = dt$region, period = dt$period, sector = "trn_freight", Units = "million ton-km",
                 subsector = "Freight Rail", technology = "Electric",
                 unique = TRUE)
      frTrain <- dt[miss, on = c("region", "period", "sector", "subsector", "technology", "Units")]
      frTrain[is.na(value), value := 0]
      dt <- rbind(dt[!(subsector == "Freight Rail" & technology == "Electric")], frTrain)
      x <- as.magpie(as.data.frame(dt), temporal = 2, spatial = 1)
    })

  return(x)
}
