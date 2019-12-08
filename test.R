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

## Two indicator matrices. 
col1 <- "LandUse"
col2 <- "HgBand"

## XMat is the matrix A_i counts
form1 <- as.formula("~ LandUse - 1")
Xmat <- model.matrix(form1, data)

## YMat is the matrix B_j counts
form2 <- as.formula("~ HgBand - 1")
Ymat <- model.matrix(form2, data)

## We can build the 2 way contingency table of each class
## Rows A_i cols B_j
two_way_table <- t(as.matrix(Xmat)) %*% as.matrix(Ymat)

## Estimates for frequencies

n <- sum(two_way_table)

## Total frequencies of X matrix
D_r <- 1/n * (t(Xmat) %*% Xmat)

## Total frequencies of Y matrix
D_s <- 1/n * (t(Ymat) %*% Ymat)

## UMV estimateion of $P_{ij}$ joint distribution of pairs of variables.
P_joint <- 1/n * two_way_table

## Conditional probability that an individual has property B_j given they have property A_i
## P_r <- D_r^{-1}P
P_r <- ginv(D_r)%*%P_joint
row.names(P_r) <- row.names(P_joint)

## Conditional probability of A_i given B_j
P_s <- ginv(D_s)%*%t(P_joint)
row.names(P_s) <- colnames(P_joint)

heatmap(P_r, Colv=NA, Rowv=NA)

require(reshape2)
require(ggplot2)

display <- melt(P_r)

labels <- round(display$value,2)
idx <- which(labels == 0)
labels[idx] <- NA

ggplot(data = display, aes(Var2, Var1, fill = value))+
  geom_tile(color = "white")+
  scale_fill_gradient2(low = "blue", high = "red", mid = "white", 
                       midpoint = 0, limit = c(0,1), space = "Lab", 
                       name="cond. likelihood") +
  theme_minimal()+ 
  theme(axis.text.x = element_text(angle = 45, vjust = 1, 
                                   size = 12, hjust = 1))+
  coord_fixed() +
  geom_text(aes(Var2, Var1), label = labels, color = "black", size = 4) +
  theme(
    axis.title.x = element_blank(),
    axis.title.y = element_blank()) + 
  ggtitle("Likelihood Hg given LandUse")







