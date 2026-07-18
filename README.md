# Amazon Buy Box Analysis

This repository contains a graduate-level industrial engineering course project analyzing how Amazon selects the winner of its Buy Box. The project uses the training and test datasets provided for the assignment and applies Bayesian network modeling to study the relationship between seller identity, pricing, fulfilment, credibility, and position in the marketplace listing.

## Project overview

The analysis focuses on the factors that influence whether a seller wins Amazon’s Buy Box. The workflow includes:

- descriptive analysis of the marketplace data,
- exploratory inspection of price, seller credibility, fulfilment, and ranking variables,
- structure learning for a discrete Bayesian network using the bnlearn package,
- inference and prediction on held-out test data.

## Repository structure

- data/ — training and test data files in .rds format
- src/ — R analysis script for the full workflow
- output/ — intermediate model objects and fitted results
- reports/ — project report files and assignment reference materials

## Data files

The repository includes the following data files:

- data/amz_train.rds — training dataset
- data/amz_test.rds — test dataset
- data/amz_test_full.rds — full test dataset used for evaluation

## Analysis workflow

The main R script is located at [src/amazon_buy_box_analysis.R](src/amazon_buy_box_analysis.R). It performs the complete analysis pipeline, including:

1. data preparation and feature engineering,
2. descriptive summaries and exploratory plots,
3. Bayesian network structure learning,
4. parameter fitting and inference,
5. prediction on test data and model evaluation.

## Report

A report draft is available in [reports/amazon_buy_box_report_draft.md](reports/amazon_buy_box_report_draft.md), and the PDF version is in [reports/amazon_buy_box_report.pdf](reports/amazon_buy_box_report.pdf).

## Requirements

The analysis uses the following R packages:

- bnlearn
- corrplot

Install dependencies in R with:

```r
install.packages(c("bnlearn", "corrplot"))
```

## Reproducing the analysis

From the project root, run:

```r
source("src/amazon_buy_box_analysis.R")
```

This will read the data from the data/ directory and write outputs into the output/ directory.

