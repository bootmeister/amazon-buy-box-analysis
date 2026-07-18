#  Amazon Buy Box
#  Exploratory Data Analysis

# ----------- QUESTION 1 ----------------------
library(corrplot)

options(scipen = 999)


train <- readRDS("amz_train.rds")

# We are inspecting a quick look at our data at hand, what the variables are and what their data types are.
str(train)
summary(train)

# We create two variables as day and week.
train$day  <- as.Date(train$epoc)
train$week <- as.integer(format(train$epoc, "%V"))
train$day

# We are inspecting how many unique products and sellers, and how many total rows there are.

length(unique(train$pid))
length(unique(train$sid))     # number of sellers
nrow(train)
length(unique(train$epoc))

# We are now presenting the same counts, broken down by day. We use tapply for each one and put
# the results in a data frame.

n_sellers_per_day  <- tapply(train$sid, train$day, function(x) length(unique(x)))
n_products_per_day <- tapply(train$pid, train$day, function(x) length(unique(x)))
n_offers_per_day   <- tapply(train$pid, train$day, length)


by_day <- data.frame(
  day         = as.Date(names(n_sellers_per_day)),
  n_sellers   = as.integer(n_sellers_per_day),
  n_products  = as.integer(n_products_per_day),
  n_offers    = as.integer(n_offers_per_day)
)
by_day

# We are plotting these to get a better sense of how many products sold by who, on which day.
plot(by_day$day, by_day$n_sellers, type = "b",
     xlab = "", ylab = "distinct sellers",
     main = "Distinct sellers per day")


# Price, Buy-Box price and shipping  by product
# The data dictionary says to IGNORE rows with price == 0
# We make a filtered copy and compute on it.

train_pos <- train[train$price > 0, ]

price_by_pid <- data.frame(
  price_min       = tapply(train_pos$price,      train_pos$pid, min),
  price_mean      = tapply(train_pos$price,      train_pos$pid, mean),
  price_max       = tapply(train_pos$price,      train_pos$pid, max),
  bbox_price_mean = tapply(train_pos$bbox_price, train_pos$pid, mean, na.rm = TRUE),
  shipping_mean   = tapply(train_pos$shipping,   train_pos$pid, mean, na.rm = TRUE),
  n_offers        = tapply(train_pos$price,      train_pos$pid, length)
)
price_by_pid


# Ratings and feedback by product
ratings_by_pid <- data.frame(
  sid_rating_mean     = tapply(train$sid_rating,     train$pid, mean, na.rm = TRUE),
  sid_pos_fb_mean     = tapply(train$sid_pos_fb,     train$pid, mean, na.rm = TRUE),
  sid_rating_cnt_mean = tapply(train$sid_rating_cnt, train$pid, mean, na.rm = TRUE),
  pid_rating          = tapply(train$pid_rating,     train$pid, function(x) x[1]),
  pid_rating_cnt_mean = tapply(train$pid_rating_cnt, train$pid, mean, na.rm = TRUE)
)
ratings_by_pid

# We get almost no information from the pid_rating. It may be a candidate to drop later.


# We do a similar analysis by comparing the performance of Amazon sellers vs other sellers

train$seller_type <- ifelse(train$sid == "amazon", "Amazon", "Other")


tapply(train$bbox == "success", train$seller_type, mean) # We see that most of the Buy Box winners are amazon sellers.
table(train$seller_type, train$bbox)


win_rate_pid_seller <- tapply(train$bbox == "success",
                              list(train$pid, train$seller_type),
                              mean)


win_rate_pid_seller    


win_rate_week_seller <- tapply(train$bbox == "success",
                               list(train$week, train$seller_type),
                               mean)
win_rate_week_seller

# We also inspected at what percentage of the total buy boxes came from amazon sellers or other sellers

winners_only <- train[train$bbox == "success", ]

# 2. Count the wins: Create a matrix of who won how many times per product
win_counts <- table(winners_only$pid, winners_only$seller_type)

# 3. Calculate the ratios: Convert the raw counts into row percentages
win_share_pid <- prop.table(win_counts, margin = 1)

win_share_pid


# We are plotting these two together
weeks <- as.integer(rownames(win_rate_week_seller))
plot(weeks, win_rate_week_seller[, "Amazon"], type = "b",
     col = "blue", pch = 16, ylim = c(0, 1),
     xlab = "ISO week", ylab = "win rate",
     main = "Buy-Box win rate by week: Amazon vs Others")
lines(weeks, win_rate_week_seller[, "Other"], type = "b",
      col = "red", pch = 17)
legend("right", legend = c("Amazon", "Other"),
       col = c("blue", "red"), pch = c(16, 17), lty = 1)


# Prime, FBA, Page, Rank vs winning
# For each feature, what is the win rate at each value of the feature?



# Also, What if we give  rankings to all products relative to all products, instead of exposing their relative ranking on their page?
# For instance, if there are, say 30 products in the first range, the first product in the second page is rank 31. And then, after ranking all products in accordance with
# this new ranking function, we can check absolute ranking's role in the probability of being chosen as buy box product.
# Convert page and rank to integers, then build a single global rank.
# Page 1 holds up to 12 positions (rank 0-11), so:
train$page_int   <- as.integer(as.character(train$page))
train$rank_int   <- as.integer(as.character(train$rank))
train$global_rank <- (train$page_int - 1) * 12 + train$rank_int

tapply(train$bbox == "success", train$is_fba,   mean)
tapply(train$bbox == "success", train$is_prime, mean)
tapply(train$bbox == "success", train$page,     mean)
tapply(train$bbox == "success", train$global_rank,     mean)


# We also created a new column called "credibility_norm". We wanted to construct it look at the interactive effects of
# sid_rating columns. It was constructed as follows:

norm_rating <- train$sid_rating / 5
norm_pos_fb <- train$sid_pos_fb / 10
norm_cnt    <- train$sid_rating_cnt / 100

# 1. Rescale the 0-5 rating to -1 to 1
train$rating_centered <- (train$sid_rating - 2.5) / 2.5

# 2. Multiply by the normed volume and positive feedback percentage


# Combine them (You can multiply these by weights if you think one is more important!)
train$credibility_norm <- (norm_rating + norm_pos_fb + norm_cnt) / 3


#  relative price within a snapshot
# We want the minimum price in this product's
# epoc attached to every row in that epoc. We use ave() to accomplish  this. We used Generative AI tools to
# use ave() function.

# We restrict our analysis to price > 0 first
train <- train[train$price > 0, ]

train$min_price     <- ave(train$price, train$pid, train$day, FUN = min)
train$price_premium <- train$price / train$min_price
train$is_cheapest   <- train$price == train$min_price
train$price_rank    <- ave(train$price, train$pid, train$epoc,
                           FUN = function(x) rank(x, ties.method = "min"))


train$min_price
# Win rate by price-premium bin.
# This must be created here, BEFORE any line below that references premium_bin
# (including the non-Amazon descriptive check).
train$premium_bin <- cut(train$price_premium,
                         breaks = c(0, 1.0001, 1.05, 1.15, Inf),
                         labels = c("cheapest", "<5% over",
                                    "5-15% over", ">15% over"))
tapply(train$bbox == "success", train$premium_bin, mean)
# ^ The shape of THIS table is your evidence for how to bin price in Part 3.

# total_price = price + shipping
shipping_filled <- train$shipping
shipping_filled[is.na(shipping_filled)] <- 0
train$total_price <- train$price + shipping_filled

# Does being the cheapest relate to winning?
tapply(train$bbox == "success", train$is_cheapest, mean)
#Apparently so. But it may be the case that amazon sellers usually make the most competitive price so it may actually
#be the effect of being an amazon seller.

#Let's check it descriptively:

# Restrict to non-Amazon offers, then look at win rate by price position
non_amz <- train[train$seller_type == "Other", ]

# By the binary "is_cheapest" flag
tapply(non_amz$bbox == "success", non_amz$is_cheapest, mean)

# By the 4-level premium bin (more informative)
tapply(non_amz$bbox == "success", non_amz$premium_bin, mean)

# And the counts behind those rates, so you can judge sample size
table(non_amz$is_cheapest)
table(non_amz$premium_bin)


# Detecting some outliers
# Boxplot of price per product
boxplot(price ~ pid, data = train, las = 2,
        xlab = "product", ylab = "price",
        main = "Price distribution by product")

# List extreme prices: more than 5x or less than 1/5 the product median.
train$pid_median_price <- ave(train$price, train$pid, FUN = median)

is_extreme <- train$price > 5 * train$pid_median_price |
  train$price < train$pid_median_price / 5

outliers <- train[is_extreme,
                  c("pid", "sid", "price", "pid_median_price",
                    "shipping", "bbox")]
outliers <- outliers[order(outliers$pid, -outliers$price), ]
head(outliers, 20)
nrow(outliers)
# Guidance: a real $900 listing that never wins is INFORMATION, not error.
# Only discard values that are clearly scraping artifacts (e.g. price == 0).

# We also checked if any outlier was selected as Buy Box.

nrow(outliers$bbox == "success")

# Although there are no buy box selected from the 741 outliers, we decided to keep the outliers;
# since they still contain valuable information regarding a product by a seller not being chosen as a buy box product.








# ----------- QUESTION 2 ----------------------

library(bnlearn)

# We constructed a correlation matrix to see the overall correlations as a whole.

numeric_train <- train[sapply(train, is.numeric)]
numeric_train <- subset(numeric_train, select = -shipping)

numeric_train$bbox <- ifelse(train$bbox == "success", 1, 0)
numeric_train$is_fba <- ifelse(train$is_fba == "yes", 1, 0)
numeric_train$is_prime <- ifelse(train$is_prime == "yes", 1, 0)
numeric_train$is_amazon <- ifelse(train$sid == "amazon", 1, 0)







M <- cor(numeric_train)
corrplot(M, method = "number")



# 1. Amazon vs Other:  Amazon wins ~93% of its offers, Others ~4%.
tapply(train$bbox == "success", train$seller_type, mean)

# 2. Prime is the operative flag (FBA matters only via Prime).
#    is_fba=yes & is_prime=no wins essentially 0%.
tapply(train$bbox == "success",
       list(train$is_fba, train$is_prime), mean)

# 3. Price (relative): cheapest offers win much more.
tapply(train$bbox == "success", train$premium_bin, mean)

# 4. Seller rating: below 4 stars => ~0% win rate (filter-like).
#    Named sid_rating_bin to match the column expected by bn_data below.
train$sid_rating_bin <- cut(train$sid_rating,
                            breaks = c(-0.01, 3.99, 4.49, 4.99, 5.01),
                            labels = c("<4", "4-4.5", "4.5-5", "5"))
tapply(train$bbox == "success", train$sid_rating_bin, mean)

# 5. Global Rank: position 0 wins ~61%, others ~3%. Strong but not
#    deterministic 
train$top_global_rank <- train$global_rank == "0"
tapply(train$bbox == "success", train$top_global_rank, mean)


# Amazon is ALWAYS FBA and ALWAYS Prime in this data.
# => seller_type forces the values of is_fba and is_prime.
table(train$seller_type, train$is_fba)
table(train$seller_type, train$is_prime)

# Prime requires FBA structurally (no Prime offer is non-FBA).
# => is_fba -> is_prime is a STRUCTURAL arc we should whitelist.
table(train$is_fba, train$is_prime)



# Our hypothesized dag would be like this:

#    seller_type     Amazon vs Other            (exogenous)
#    is_fba          Fulfilled by Amazon?        (depends on seller_type)
#    is_prime        Prime offer?                (depends on seller_type, is_fba)
#    premium_bin     price relative to snapshot  (exogenous to this snapshot)
#    sid_rating_cnt      seller star rating count         (exogenous; binned in Question 3)
#    global_rank            position in seller list    
#    credibility_norm
#    bbox            WON THE BUY BOX (outcome)
#    

#  Variables we deliberately LEAVE OUT for simplicity:
#    pid_rating      only 2 values across 9 products — no information
#    sid_rating  
#    sid_pos_fb      highly correlated with sid_rating
#    shipping        has NAs; subsumed into the price story
#    page            almost redundant with rank
#    bbox_sid, bbox_price  ARE the outcome (forbidden by Part 4)

#    rank and bbox may BOTH be consequences of the same hidden Amazon
#    ranking algorithm. We model rank -> bbox because rank is observable
#    before the box assignment, but causally this arrow is debatable.
# ------------------------------------------------------------

hypo_dag <- model2network(
  paste0("[seller_type]",
         "[is_fba|seller_type]",
         "[is_prime|seller_type:is_fba]",
         "[premium_bin]",
         "[sid_rating_cnt]",
         "[global_rank]",
         "[credibility_norm|sid_rating_cnt]",
         "[bbox|seller_type:is_prime:premium_bin:sid_rating_cnt:global_rank]")
)

# We are inspecting the structure
print(hypo_dag)        
arcs(hypo_dag)       


plot(hypo_dag)



# -----------Whitelist and blacklist for questtion 3-------------------
#     We constrain the structure-learning algorithms so we
#     do not waste time to explore arcs we already know are
#     either required or impossible.
#     Names below use the column names that will live in bn_data,
#     so Part 3 can load and apply them with no further renaming.


whitelist <- data.frame(
  from = c("is_fba"),
  to   = c("is_prime")
  
)

# Three families of forbidden arrows:
# no arrow OUT of bbox
# no arrow INTO seller_type
# is_prime cannot cause is_fba (wrong direction)
predictors <- c("seller_type", "is_fba", "is_prime",
                "premium_bin", "sid_rating_bin", "pos_bin")

blacklist <- rbind(

  data.frame(from = "bbox", to = predictors),

  data.frame(from = setdiff(predictors, "seller_type"), to = "seller_type"),

  data.frame(from = "is_prime", to = "is_fba")
)




train$pos_bin <- cut(train$global_rank,
                     breaks = c(-0.01, 0.5, 9.5, Inf),
                     labels = c("top", "page1_rest", "below_fold"))

# Quick sanity check — should reproduce the staircase you've seen above
tapply(train$bbox == "success", train$pos_bin, mean)
table(train$pos_bin)

# bnlearn requires every column in bn_data to be a factor.
# seller_type was created as a character vector (ifelse), so we convert.
train$seller_type <- factor(train$seller_type)

# Now every column referenced below is guaranteed to exist and be a factor.
bn_data <- train[, c("seller_type", "is_fba", "is_prime",
                     "premium_bin", "sid_rating_bin",
                     "pos_bin", "credibility_norm","bbox")]

# We are saving the constraints so Part 3 can load them without re-running
saveRDS(list(whitelist = whitelist, blacklist = blacklist,
             hypo_dag  = hypo_dag),
        "part2_constraints.rds")


# ------------ Question 3 ---------------


library(bnlearn)


# -------- building the discretized data frame ------------


train$sid_rating_cnt_bin <- cut(train$sid_rating_cnt,
                            breaks = c(-0.01, 0.001335, 0.025249, 0.275731, 100.01),
                            labels = c("1st quant", "2th quant", "3rd quant", "4th quant"))

# Bin rank. Twelve levels would explode the CPT and add no signal
# beyond "are you at position 0 / near top / further down".
train$global_rank_int <- as.integer(as.character(train$global_rank))
train$global_rank_bin <- cut(train$global_rank_int,
                      breaks = c(-0.01, 0.5, 4.5, 22.5),
                      labels = c("0", "1-4", "5+"))
summary(train$global_rank)
# Make seller_type an explicit factor
train$seller_type <- factor(train$seller_type)

train$credibility_norm_bin <- cut(train$credibility_norm,
                                  breaks = c(-0.01, 0.6067, 0.6570, 0.6654, 1.01),
                                  labels = c("1st quant", "2th quant", "3rd quant", "4th quant"))

# We are selecting only the 7 modelling columns. We deliberately leave out:
#   epoc , pid , pid_rating (because there are only 2 values), shipping (there are NAs,
#   subsumed by price story), page (redundant with rank), and the
#   bbox-related columns.

bn_data_full <- train[, c("seller_type", "is_fba", "is_prime",
                     "premium_bin", "sid_rating_cnt_bin", "credibility_norm_bin",
                     "global_rank_bin", "bbox")]

# Dropping any rows with NA in any of these columns.
bn_data <- bn_data_full[complete.cases(bn_data_full), ]

# Making sure every column is a factor 
for (col in names(bn_data)) bn_data[[col]] <- factor(bn_data[[col]])


str(bn_data)
cat("\nRows used for learning:", nrow(bn_data), "\n\n")
lapply(bn_data, table)


# We are loading whitelist and blacklist from Part 2, we had created before. 

ctrx <- readRDS("part2_constraints.rds")
wl   <- ctrx$whitelist
bl   <- ctrx$blacklist

# The Part 2 constraints used names "premium_bin", "sid_rating",
# "rank" etc. Two of those are renamed in our discretised data
# (sid_rating -> sid_rating_bin, rank -> rank_bin).
rename_col <- function(x) {
  x[x == "sid_rating_cnt"] <- "sid_rating_cnt_bin"
  x[x == "global_rank"]       <- "global_rank_bin"
  x[x == "credibility_norm"]       <- "credibility_norm_bin"
  x
}
wl$from <- rename_col(wl$from);  wl$to <- rename_col(wl$to)
bl$from <- rename_col(bl$from);  bl$to <- rename_col(bl$to)

cat("Whitelist:\n"); print(wl)
cat("\nBlacklist:\n"); print(bl)


#  The learning algorithms


set.seed(42)  

wl <- data.frame(from = "is_fba", to = "is_prime")

predictors <- setdiff(names(bn_data), "bbox")   

bl <- rbind(
  data.frame(from = "bbox",                            to = predictors),
  data.frame(from = setdiff(predictors, "seller_type"), to = "seller_type"),
  data.frame(from = "is_prime",                        to = "is_fba")
)


# Score-based: hill-climbing with BIC.
hc_dag   <-  hc(bn_data,   whitelist = wl, blacklist = bl, score = "bic")

# Constraint-based: IAMB with mutual-information independence tests
iamb_dag <- iamb(bn_data, whitelist = wl, blacklist = bl)

# Hybrid Algorithm: MMHC
mmhc_dag <- mmhc(bn_data, whitelist = wl, blacklist = bl)

# Constraint-based methods can return undirected arcs. We are converting to a directed DAG.
if (!directed(iamb_dag)) iamb_dag <- cextend(iamb_dag)
if (!directed(mmhc_dag)) mmhc_dag <- cextend(mmhc_dag)

graphviz.plot(hc_dag)
graphviz.plot(iamb_dag)
graphviz.plot(mmhc_dag)

# Now we are comparing the three models.

cat("\n--- Arcs found by each algorithm ---\n")
cat("\nHC  (", nrow(arcs(hc_dag)),   "arcs ):\n"); print(arcs(hc_dag))
cat("\nIAMB(", nrow(arcs(iamb_dag)), "arcs ):\n"); print(arcs(iamb_dag))
cat("\nMMHC(", nrow(arcs(mmhc_dag)), "arcs ):\n"); print(arcs(mmhc_dag))

# Pairwise structural Hamming distance 

cat("\n--- Structural Hamming Distance (lower = more agreement) ---\n")
cat("hc vs iamb:", shd(hc_dag,   iamb_dag), "\n")
cat("hc vs mmhc:", shd(hc_dag,   mmhc_dag), "\n")
cat("iamb vs mmhc:", shd(iamb_dag, mmhc_dag), "\n")

# Scoring each model on the same data

cat("\n--- BIC scores (higher is better) ---\n")
cat("hc:  ", score(hc_dag,   bn_data, type = "bic"), "\n")
cat("iamb:", score(iamb_dag, bn_data, type = "bic"), "\n")
cat("mmhc:", score(mmhc_dag, bn_data, type = "bic"), "\n")


# bootstrapping for the arc strength
# Which arrows survive across many resamples of the data?

set.seed(42)
arc_strength <- boot.strength(
  data       = bn_data,
  R          = 100,           
  algorithm  = "hc",
  algorithm.args = list(whitelist = wl, blacklist = bl, score = "bic")
)

cat("\n--- Bootstrap arc strength (showing strength > 0.5) ---\n")
print(arc_strength[arc_strength$strength > 0.5, ])

# averaged.network() builds a consensus DAG keeping only arcs whose
# strength exceeds a data-driven threshold that bnlearn picks for us.
avg_dag <- averaged.network(arc_strength)
cat("\n--- Consensus (averaged) DAG ---\n")
print(arcs(avg_dag))



packageVersion("bnlearn")

#  6. CROSS-VALIDATION OF PREDICTIVE PERFORMANCE ON bbox


# 10-fold CV: We are splitting the data into 10 folds; on each fold,
# re-learn structure + parameters on the other 9 folds, then
# predict bbox on the held-out fold. 
#
# We use "pred" 

set.seed(42)
cv_hc   <- bn.cv(bn_data, bn = "hc",   k = 10,
                 algorithm.args = list(whitelist = wl, blacklist = bl,
                                       score = "bic"),
                 loss = "pred", loss.args = list(target = "bbox"))

cv_iamb <- bn.cv(bn_data, bn = "iamb", k = 10,
                 algorithm.args = list(whitelist = wl, blacklist = bl),
                 loss = "pred", loss.args = list(target = "bbox"))

cv_mmhc <- bn.cv(bn_data, bn = "mmhc", k = 10,
                 algorithm.args = list(whitelist = wl, blacklist = bl),
                 loss = "pred", loss.args = list(target = "bbox"))

cat("\n--- 10-fold CV prediction error on bbox (lower = better) ---\n")
cat("hc:  ", mean(loss(cv_hc)),   "\n")
cat("iamb:", mean(loss(cv_iamb)), "\n")
cat("mmhc:", mean(loss(cv_mmhc)), "\n")



#
chosen_dag <- hc_dag

# Plot the chosen model for the report.
graphviz.plot(chosen_dag)

# Save everything Part 4 will need.
saveRDS(list(chosen_dag   = chosen_dag,
             bn_data      = bn_data,
             all_dags     = list(hc = hc_dag, iamb = iamb_dag, mmhc = mmhc_dag),
             arc_strength = arc_strength,
             avg_dag      = avg_dag),
        "part3_chosen_model.rds")

cat("\nSaved part3_chosen_model.rds — ready for Part 4.\n")

# --- Question 4 ----

#

library(bnlearn)

# Load what Question 3 saved (works on a fresh session).
p3         <- readRDS("part3_chosen_model.rds")
chosen_dag <- p3$chosen_dag      # = hc_dag
bn_data    <- p3$bn_data         # the 8-column training frame
all_dags   <- p3$all_dags        # list(hc=, iamb=, mmhc=)




fitted_bn <- bn.fit(chosen_dag, data = bn_data, method = "bayes", iss = 1)

print(fitted_bn)
# The CPT for the outcome is the heart of the model:
fitted_bn$bbox



set.seed(42)
prob_amz_BN <- cpquery(
  fitted_bn,
  event    = (bbox == "success"),
  evidence = list(seller_type = "Amazon"),
  method   = "lw",
  n        = 100000
)

# The empirical answer to the same question from the training data
prob_amz_data <- mean(
  bn_data$bbox[bn_data$seller_type == "Amazon"] == "success"
)

cat("\nP(bbox = success | seller_type = Amazon)\n")
cat("  BN inference     :", round(prob_amz_BN,   4), "\n")
cat("  Empirical (train):", round(prob_amz_data, 4), "\n")
cat("  Gap              :", round(abs(prob_amz_BN - prob_amz_data), 4), "\n")
# If these match closely, the network has correctly absorbed the
# dominant Amazon -> bbox relationship.




test <- readRDS("amz_test_full.rds")
test <- test[test$price > 0, ]               # ignore unusable rows

# seller_type
test$seller_type <- ifelse(test$sid == "amazon", "Amazon", "Other")

# Relative price — note: training used (pid, DAY) as the grain.
test$day        <- as.Date(test$epoc)
test$min_price  <- ave(test$price, test$pid, test$day, FUN = min)
test$price_premium <- test$price / test$min_price
test$premium_bin   <- cut(test$price_premium,
                          breaks = c(0, 1.0001, 1.05, 1.15, Inf),
                          labels = c("cheapest", "<5% over",
                                     "5-15% over", ">15% over"))

# sid_rating_cnt_bin — SAME breaks as training (training quantiles).
test$sid_rating_cnt_bin <- cut(test$sid_rating_cnt,
                               breaks = c(-0.01, 0.001335, 0.025249,
                                          0.275731, 100.01),
                               labels = c("1st quant", "2th quant",
                                          "3rd quant", "4th quant"))

# credibility_norm + bin — SAME formula and breaks as training.
norm_rating <- test$sid_rating     / 5
norm_pos_fb <- test$sid_pos_fb     / 10
norm_cnt    <- test$sid_rating_cnt / 100
test$credibility_norm <- (norm_rating + norm_pos_fb + norm_cnt) / 3
test$credibility_norm_bin <- cut(test$credibility_norm,
                                 breaks = c(-0.01, 0.6067, 0.6570,
                                            0.6654, 1.01),
                                 labels = c("1st quant", "2th quant",
                                            "3rd quant", "4th quant"))

# global_rank + bin — SAME as training (this is what drops page 2).
test$page_int   <- as.integer(as.character(test$page))
test$rank_int   <- as.integer(as.character(test$rank))
test$global_rank <- (test$page_int - 1) * 12 + test$rank_int
test$global_rank_int <- as.integer(as.character(test$global_rank))
test$global_rank_bin <- cut(test$global_rank_int,
                            breaks = c(-0.01, 0.5, 4.5, 22.5),
                            labels = c("0", "1-4", "5+"))

# Force every modelling column in test to use the SAME factor levels
# as the training data. This is the critical defensive step:
# predict() fails if a test factor has different/extra/missing levels.
model_cols <- names(bn_data)                 # the 8 columns the BN knows
for (col in model_cols) {
  test[[col]] <- factor(test[[col]], levels = levels(bn_data[[col]]))
}

# Keep the 8 columns, then drop rows with NA in any PREDICTOR.
test_bn <- test[, model_cols]
predictor_cols <- setdiff(model_cols, "bbox")
test_bn <- test_bn[complete.cases(test_bn[, predictor_cols]), ]
cat("\nTest rows used for prediction:", nrow(test_bn),
    "(page-1 offers only)\n")


set.seed(42)
pred_chosen <- predict(fitted_bn, node = "bbox", data = test_bn,
                       method = "bayes-lw", n = 500)




pred_chosen <- factor(pred_chosen,   levels = c("failure", "success"))
actual      <- factor(test_bn$bbox,  levels = c("failure", "success"))

cm <- table(Predicted = pred_chosen, Actual = actual)
cat("\n--- Confusion matrix (chosen model: HC) ---\n")
print(cm)

TP <- cm["success", "success"]   # predicted win, really won
FP <- cm["success", "failure"]   # predicted win, actually lost (false positive)
FN <- cm["failure", "success"]   # predicted loss, actually won (false negative)
TN <- cm["failure", "failure"]   # predicted loss, really lost

accuracy    <- (TP + TN) / sum(cm)
sensitivity <- TP / (TP + FN)              # recall on "success"
specificity <- TN / (TN + FP)              # recall on "failure"
precision   <- if ((TP + FP) > 0) TP / (TP + FP) else NA
balanced    <- (sensitivity + specificity) / 2

cat("\nTrue Positives :", TP, " (predicted win & won)\n")
cat("False Positives:", FP, " (predicted win & lost)\n")
cat("False Negatives:", FN, " (predicted loss & won)\n")
cat("True Negatives :", TN, " (predicted loss & lost)\n")
cat("\nOverall accuracy :", round(accuracy,    4), "\n")
cat("Balanced accuracy:", round(balanced,    4), "\n")
cat("Sensitivity      :", round(sensitivity, 4), "\n")
cat("Specificity      :", round(specificity, 4), "\n")
cat("Precision        :", round(precision,   4), "\n")

# Visual of the confusion matrix
fourfoldplot(cm, color = c("tomato", "steelblue"),
             main = "Confusion matrix — chosen model (HC)")



evaluate_dag <- function(dag, train_df, test_df) {
  fit <- bn.fit(dag, train_df, method = "bayes", iss = 1)
  set.seed(42)
  pr  <- predict(fit, node = "bbox", data = test_df,
                 method = "bayes-lw", n = 500)
  pr  <- factor(pr,            levels = c("failure", "success"))
  ac  <- factor(test_df$bbox,  levels = c("failure", "success"))
  cm  <- table(pr, ac)
  TP <- cm["success", "success"]; FP <- cm["success", "failure"]
  FN <- cm["failure", "success"]; TN <- cm["failure", "failure"]
  sens <- TP / (TP + FN)
  spec <- TN / (TN + FP)
  c(accuracy = (TP + TN) / sum(cm),
    balanced = (sens + spec) / 2)
}

results <- sapply(all_dags, evaluate_dag,
                  train_df = bn_data, test_df = test_bn)
cat("\n--- Test-set performance by algorithm ---\n")
print(round(results, 4))

# Grouped bar chart
barplot(results,
        beside       = TRUE,
        col          = c("steelblue","tomato"),
        ylim         = c(0, 1),
        ylab         = "score on test set",
        main         = "Model comparison on test data",
        legend.text  = c("Accuracy", "Balanced accuracy"),
        args.legend  = list(x = "topright", bty = "n"))



