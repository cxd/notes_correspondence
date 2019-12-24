## Notes on Correspondence Analysis.

This repository contains a set of notes on correspondence analysis drawn from readings "Modern Multivariate Statistical Techniques" by Alan J. Izenman. The notebook provides a summary of the method, and an example applied to the HgFish data set from the NADA package.

## Notebook

PDF document [Notes on Correspondence Analysis](https://github.com/cxd/correspondance/blob/master/notes_on_correspondance_analysis.pdf).

## Overview

Correspondence analysis can be a useful data exploration tool when investigating the relationship between two types of factors.
Multiple correspondence analysis provides a similar capability for multiple sets of factors, however this note will only review correspondence analysis.
These sets of scripts are for my own learning about correspondence analysis. For more robust and accurate tools, the R package FactorMineR should be leveraged for this type of analysis (http://factominer.free.fr).

## Data Set.

The data set used for this exploration is from the package NADA, called HgFish, this provides the mercury concentration in fish accross the united states based on land use (see HgFish in the NADA package).
The property Hg is converted into a factor variable given a set of 15 levels, this is a simplistic method of discretising the continuous measure for mercury, and is based on the histogram. 
