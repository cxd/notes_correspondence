
mat <- compute_correspondence_tables(data, "LandUse", "HgBand")

display_table(mat$P_r, "Conditional Hg given LandUse", "cond. likelihood")

# Burt matrix analogue of variance-covariance matrix for discrete data.
display_table(mat$var_covar_mat, "Burt Matrix", "var. covar")

require(corrplot)
corrplot(mat$var_covar_mat)

# row marginal probabilities
barplot(mat$P_row_margins)

# column marginal probabilities
barplot(mat$P_col_margins)

## TODO: Example of plotting profile coordinates.
## Row profiles G_P and H_S
## Column profiles G_s and H_p
## Both profiles G_p and H_p
draw_profiles(mat, "LandUse vs HgBand")


v <- mat$R_inertia$R_eigen$vectors

plot(v[1,], v[2,])


