require(NADA)
require(MASS)

source("lib/ca_tools.R")

data(HgFish)

summary(HgFish)

data <- HgFish

## To be able to associate mercury levels we will generate 15 cuts.
hg_hist <- hist(HgFish$Hg, breaks=15, plot=FALSE)

hg_labels <- make_break_labels("Hg", hg_hist$breaks)

data$HgBand <- cut(HgFish$Hg, breaks=hg_hist$breaks, labels=hg_labels, include.lowest=TRUE)

mat <- compute_tables(data, "LandUse", "HgBand")

display_table(mat$P_r, "Conditional Hg given LandUse", "cond. likelihood")