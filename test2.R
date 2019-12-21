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

mat <- compute_correspondance_tables(data, "LandUse", "HgBand")

display_table(mat$P_r, "Conditional Hg given LandUse", "cond. likelihood")

# Burt matrix analogue of variance-covariance matrix for discrete data.
display_table(mat$var_covar_mat, "Burt Matrix", "var. covar")

require(corrplot)
corrplot(mat$var_covar_mat)

# row marginal probabilities
barplot(mat$P_row_margins)

# column marginal probabilities
barplot(mat$P_col_margins)


