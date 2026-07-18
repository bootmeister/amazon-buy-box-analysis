# Amazon Buy Box Analysis

## Executive Summary

This project examines the factors associated with winning Amazon’s Buy Box using a supervised learning approach based on probabilistic graphical models. The analysis uses a training dataset of marketplace offers and evaluates the resulting model on a held-out test set. The central finding is that the Buy Box outcome is strongly associated with seller identity, fulfilment status, price competitiveness, credibility signals, and listing position. Among third-party sellers, lower price and stronger placement are especially important, while seller credibility acts as a gatekeeping factor.

## Background

On Amazon’s marketplace, the Buy Box is the prominent seller selection mechanism shown to shoppers when multiple sellers offer the same product. Although Amazon does not publicly disclose the exact decision rule, it is widely understood that the selected seller is influenced by a combination of pricing, fulfilment performance, seller reputation, and listing visibility. This project investigates that decision process using data from the marketplace and models the Buy Box outcome as a probabilistic system.

## Data and Scope

The dataset contains seller offers for multiple products over time. Each row corresponds to a seller listing for a product at a given timestamp. The data include seller-level attributes, offer-level attributes, and the Buy Box outcome for each offer. The analysis focuses on the variables that are observable before the Buy Box decision and excludes variables directly tied to the Buy Box outcome itself from the predictive model.

## Methodological Approach

The workflow combines two main stages:

1. Descriptive analysis to identify the strongest empirical patterns in the data.
2. Bayesian network modeling to represent the dependencies between explanatory variables and the Buy Box outcome.

The Bayesian network is learned with a discrete representation of the main predictors. This choice is appropriate because several predictors are categorical or threshold-like, and the resulting network offers an interpretable representation of the underlying structure.

## Descriptive Findings

### Marketplace structure

The training data consist of a large number of seller offers across multiple products and time snapshots. The Buy Box is won only rarely relative to the number of offers present in each snapshot, which is consistent with the fact that only one seller is selected among many competing listings.

### Seller identity

Seller identity is the most dominant signal in the data. Amazon itself wins the Buy Box at a much higher rate than other sellers, indicating that seller type is a major driver of the outcome.

### Price competitiveness

Because prices vary across products, the analysis uses a relative price measure defined within each product snapshot. The resulting price-premium feature shows that offers with the lowest price in the snapshot are much more likely to win. This pattern is especially strong among non-Amazon sellers and supports the interpretation that the Buy Box is partly a price-competition problem.

### Fulfilment and Prime

The analysis shows that fulfillment status matters primarily through Prime eligibility. Offers that are both fulfilled by Amazon and Prime-eligible show substantially higher Buy Box success than other offers. This suggests that Prime status acts as a practical threshold for eligibility rather than just a separate attribute.

### Seller credibility

Seller reputation measures, including seller rating, positive feedback, and rating count, are associated with Buy Box success. In practice, credibility acts as a filter: sellers with weak ratings or low feedback rarely win, whereas credible sellers have a much better chance of qualifying for the Buy Box competition.

### Listing position

Location in the marketplace listing also strongly relates to the outcome. Offers placed at the top of the first page are much more likely to win than offers appearing later or on subsequent pages. This motivates the use of a combined ranking feature that captures overall positioning.

## Modeling Framework

A Bayesian network is used to represent the dependence structure among the explanatory variables and the Buy Box variable. The network is learned with structural learning techniques and constrained by domain knowledge. In particular, the model enforces that:

- the Buy Box outcome cannot cause upstream variables,
- seller type is treated as an exogenous attribute,
- Prime status is structurally related to FBA fulfilment.

These restrictions ensure that the learned network remains interpretable and aligned with the observed business logic.

## Model Comparison and Selection

Three structure-learning approaches were compared:

- hill-climbing,
- IAMB,
- MMHC.

The models were evaluated using information criteria, cross-validation, and bootstrap stability. The hill-climbing model was selected because it achieved the best overall balance between fit and predictive performance, while also showing stable relationships to the Buy Box outcome across resamples.

## Inference and Prediction

After fitting the selected model, inference was performed to estimate the probability of Buy Box success given relevant evidence. The fitted network reproduced the strong Amazon effect observed in the training data, confirming that the learned structure captured the dominant patterns in the marketplace.

The model was then applied to the test data using a probabilistic prediction procedure. The prediction task used only variables that are observable before the Buy Box decision, consistent with the problem setting. The resulting predictions showed high accuracy overall, though the model was more reliable in identifying losing offers than in recovering all actual winners. This reflects a distribution shift between the training and test periods.

## Interpretation

The findings support a consistent narrative. Amazon itself is the strongest predictor of Buy Box success. For third-party sellers, the process appears to operate as a gated competition in which sellers must first satisfy minimum credibility and fulfilment requirements, and then compete primarily on price and visibility. The evidence suggests that the Buy Box is not driven by price alone, but by a combination of seller quality, offer competitiveness, and placement.

## Conclusion

This project shows that Bayesian networks are a useful tool for studying the Buy Box decision process because they make the dependency structure explicit and allow for direct probabilistic reasoning. The model captures the major mechanisms present in the marketplace and provides a defensible explanation for the Buy Box outcome. At the same time, the analysis highlights that real marketplace data can shift over time, which affects the stability of predictive performance.

## Acknowledgment

The project uses the assigned course dataset and applies a Bayesian network framework to analyze the Buy Box decision problem in a structured and interpretable manner.
