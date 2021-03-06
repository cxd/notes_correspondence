require(MASS)
require(reshape2)
require(ggplot2)
require(ggrepel)


## Make a set of labels for the breaks derived from a histogram function.
## These labels can be applied to data that is generated by the cut function.
make_break_labels <- function(name, breaks, sep="x") {
  n <- length(breaks)
  m <- n - 1
  sapply(1:m, function(i) {
    j <- i + 1
    lower <- breaks[[i]]
    upper <- breaks[[j]]
    low <- if (lower < 0) {
      paste0("minus", abs(lower))
    } else as.character(lower)
    up <- if (upper < 0) {
      paste0("minus", abs(upper))
    } else as.character(upper)
    
    name <- paste(name, low, up, sep=sep)
    name
  })
}
## Compute the X frequency matrix, Y frequency matrix
## Joint P(A AND B)
## Conditional P_r = P(B given A)
## Condition P_s = P(A given B)
compute_correspondence_tables <- function(data, col1name, col2name) {
  
  ## XMat is the matrix A_i counts
  form1 <- as.formula(paste0("~ ", col1name, " - 1"))
  Amat <- model.matrix(form1, data)
  
  ## YMat is the matrix B_j counts
  form2 <- as.formula(paste0("~ ", col2name, " - 1"))
  Bmat <- model.matrix(form2, data)
  
  
  ## We can build the 2 way contingency table of each class
  ## Rows A_i cols B_j
  two_way_table <- t(as.matrix(Amat)) %*% as.matrix(Bmat)
  
  ## Estimates for frequencies
  
  n <- sum(two_way_table)
  
  ## Total frequencies of X matrix
  D_r <- 1/n * (t(Amat) %*% Amat)
  
  ## Total frequencies of Y matrix
  D_s <- 1/n * (t(Bmat) %*% Bmat)
  
  ## UMV estimateion of $\pi_{ij}$ joint distribution of pairs of variables.
  ## This is also known as the correspondance matrix.
  P_joint <- 1/n * two_way_table
  
  # not that the row margians are also equal to the diagonal of D_r or rowSums(P_joint)
  P_row_margins <- diag(D_r)
  # the column margins are equal to the diagonal D_s or colSums(P_joint)
  P_col_margins <- diag(D_s)
  
  ## Conditional probability that an individual has property B_j given they have property A_i
  ## P_r <- D_r^{-1}P
  ## P_r is also known as the row profile.
  P_r <- ginv(D_r)%*%P_joint
  row.names(P_r) <- row.names(P_joint)
  
  ## Conditional probability of A_i given B_j
  ## This is also known as the column profile.
  P_s <- ginv(D_s)%*%t(P_joint)
  row.names(P_s) <- colnames(P_joint)
  
  ## Burt matrix (r + s) x (r + s) 
  ## The burt matrix divided by n is th analogue of the sample variance-covariance matrix
  t1 <- rbind(n*D_r, t(two_way_table))
  t2 <- rbind(two_way_table, n*D_s)
  burt_mat <- cbind(t1,t2)
  
  ## Analogue of variance-covariance data utilising the burt matrix.
  var_covar_mat <- 1/n * burt_mat
  
  
  ## compute chisq distance matrices.
  row_chisq_dist <- chisq_row_distances(P_r, D_s)
  col_chisq_dist <- chisq_row_distances(P_s, D_r)
  ## Compute center of mass chisq distances.
  row_chisq_center <- chisq_row_center(P_r, diag(D_s), D_s)
  col_chisq_center <- chisq_row_center(P_s, diag(D_r), D_r)
  
  ## Compute chisq statistic
  row_chisq_stat <- n * sum(row_chisq_center)
  col_chisq_stat <- n * sum(col_chisq_center)
  
  r <- nrow(P_r)
  s <- nrow(P_s)
  df <- (r-1)*(s-1)
  # right tailed chisq statistic.
  row_chisq_pvalue <- pchisq(row_chisq_stat, df, lower.tail=FALSE)
  col_chisq_pvalue <- pchisq(col_chisq_stat, df, lower.tail=FALSE)
  
  r <- P_row_margins
  c <- P_col_margins
  ## Relative frequency matrix.
  P_relative <- P_joint - r%*%t(c)
  ## residuals where ijth entry is O_ij - E_ij.
  N_residuals <- n * P_relative
  
  ## compute the R matrix and inertia measures.
  R_inertia <- calculate_r_matrix(D_s, D_r, P_relative) 
  
  ## Compute the principle and standard coordinates.
  profile_coords <- profile_coordinates(D_s, D_r, P_relative)
  
  list(
    A=Amat,
    B=Bmat,
    n=n,
    D_r=D_r,
    D_s=D_s,
    P_joint=P_joint,
    P_relative=P_relative,
    N_residuals=N_residuals,
    P_row_margins=P_row_margins,
    P_col_margins=P_col_margins,
    P_r=P_r,
    P_s=P_s,
    burt_mat=burt_mat,
    var_covar_mat=var_covar_mat,
    row_chisq_dist=row_chisq_dist,
    row_chisq_center=row_chisq_center,
    row_chisq_stat=row_chisq_stat,
    row_chisq_pvalue=row_chisq_pvalue,
    col_chisq_dist=col_chisq_dist,
    col_chisq_center=col_chisq_center,
    col_chisq_stat=col_chisq_stat,
    col_chisq_pvalue=col_chisq_pvalue,
    R_inertia=R_inertia,
    profile_coords=profile_coords
  )
}


display_table <- function(mat, title,legend_title) {
  
  display <- melt(mat)
  
  labels <- round(display$value,2)
  idx <- which(labels == 0)
  labels[idx] <- NA
  
  ggplot(data = display, aes(Var2, Var1, fill = value))+
    geom_tile(color = "white")+
    scale_fill_gradient2(low = "blue", high = "red", mid = "white", 
                         midpoint = 0, limit = c(0,1), space = "Lab", 
                         name=legend_title) +
    theme_minimal()+ 
    theme(axis.text.x = element_text(angle = 45, vjust = 1, 
                                     size = 12, hjust = 1))+
    coord_fixed() +
    geom_text(aes(Var2, Var1), label = labels, color = "black", size = 4) +
    theme(
      axis.title.x = element_blank(),
      axis.title.y = element_blank()) + 
    ggtitle(title)
  
}

## Compute row distances
## Paramters P - profile matrix with dimenstion r x c
## D - diagonal matrix having dimension c x c
chisq_row_distances <- function(P, D) {
  # The distance matrix is r x r
  M <- matrix(nrow=nrow(P), ncol=nrow(P))
  # distance i,j = (a_i - a_j)^{T} D_c^{-1} (a_i - a_j)
  D_i <- ginv(D)
  for(i in 1:nrow(M)) {
    for(j in 1:nrow(M)) {
      a_i <- P[i,]
      a_j <- P[j,]
      delta <- a_i - a_j
      d <- t(delta)%*%D_i%*%delta 
      M[i,j] <- d
    }
  }
  M
}

## Chisq distances from center of mass
## This is a vector result where each entry is the chisq distance of the ith row from the center of mass.
## P - profile matrix dimension r x c
## c - center of mass dimension c
## D - diagonal matrix having dimension c x c
chisq_row_center <- function(P, c, D) {
  # Distance matrix is r x r
  M <- matrix(nrow=nrow(P), ncol=1) 
  # distance i,j = (a_i - c)^{T} D_c^{-1} (a_i - c)
  D_i <- ginv(D)
  for(i in 1:nrow(M)) {
    delta <- P[i,] - c
    d <- t(delta)%*%D_i%*%delta
    M[i,1] <- sum(d[1,1] * P[i,])
  }
  M
}

## Calculate the R matrix the eigenvalues or directions of inertia for the data set.
calculate_r_matrix <- function(Dc, Dr, P_hat) {
  Dc_sinv <- matrix_root(Dc)
  Dr_inv <- ginv(Dr)
  R <- Dc_sinv%*%t(P_hat)%*%Dr_inv%*%P_hat%*%Dc_sinv
  R_e <- eigen(R)
  total_inertia <- sum(diag(R))
  list(
    R=R,
    total_inertia=total_inertia,
    R_eigen=R_e)
} 

"%^%" <- function(x, n) 
	with(eigen(x), vectors %*% (values^n * t(vectors)))

## Compute X^{-1/2}
matrix_root <- function(X) {
  E <- eigen(X)
  V <- E$values
  A <- E$vectors
  idx <- which(V %in% 0)
  if (length(idx) > 0) {
    V[idx] <- V[idx]+0.0000000000000000000000001
  }
  Y <-A%*%diag(1/sqrt(V))%*%t(A)
  Y
}

# Compute the profile coordinate matrices.
## 17.2.7 Principle coordinates for row and column profiles.
## From Modern Multivariate Statistical Techniques.
profile_coordinates <- function(Dc, Dr, P_hat) {
  Dc_sinv <- matrix_root(Dc)
  Dr_sinv <- matrix_root(Dr)
  M <- Dr_sinv%*%P_hat%*%Dc_sinv
  M_svd <- svd(M)
  A <- (Dr%^%(0.5))%*%M_svd$u
  B <- (Dc%^%0.5)%*%M_svd$v
  D_lambda <- matrix(0, nrow=length(M_svd$d), ncol=length(M_svd$d))
  diag(D_lambda) <- M_svd$d
  ## G^t_P and H^t_P are principle coordinates of row and column profiles.
  Gt_p <- Dr_sinv%*%M_svd$u%*%D_lambda
  Ht_p <- Dc_sinv%*%M_svd$v%*%D_lambda
  G_p <- t(Gt_p)
  H_p <- t(Ht_p)
  ## G_S and H_S are standard coordinates of the row and column profiles.
  G_s <- t(M_svd$u)%*%Dr_sinv
  H_s <- t(M_svd$v)%*%Dc_sinv
  ## Graphical display.
  ## Row profiles G_P and H_S
  ## Column profiles G_s and H_p
  ## Both profiles G_p and H_p
  list(
    M=M,
    M_svd=M_svd,
    A=A,
    B=B,
    G_p_row_principle_coords=G_p,
    H_p_col_principle_coords=H_p,
    G_s_row_standard_coords=G_s,
    H_s_col_standard_coords=H_s
  )
}

## Draw profile using the matrix resulting from the output of compute correspondance tables.
## supply a title.
draw_profiles <- function(mat, title) {
  G_p <- mat$profile_coords$G_p_row_principle_coords
  H_p <- mat$profile_coords$H_p_col_principle_coords
  temp1 <- data.frame(X=G_p[1,], Y=G_p[2,],
                      Labels=rownames(mat$P_joint),
                      type=rep("ROW", nrow(mat$P_joint)),
                      margins=mat$P_row_margins)
  temp2 <- data.frame(X=H_p[1,], Y=H_p[2,],
                      Labels=colnames(mat$P_joint),
                      type=rep("COL", ncol(mat$P_joint)),
                      margins=mat$P_col_margins)
  temp1 <- rbind(temp1,temp2)
  
  temp1$type <- as.factor(temp1$type)
  
  
  ggplot(data=temp1, aes(x=X, y=Y, label=Labels, col=type)) +
    geom_point() +
    geom_text_repel(arrow=arrow(length=unit(0.02, "npc"), type="closed", ends="first")) + 
    scale_color_discrete(name="type") +
    ggtitle(title)
}