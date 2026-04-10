# Script:  clean_data_task1.R
# Purpose: Reads raw Airbnb listings, cleans price column, filters on price/reviews
# Input:   datasets/airbnb/listings/listings_{REGION}.csv
# Output:  datasets/airbnb/processed/listings_{region}_cleaned.rds

library(tidyverse)
source(here::here("datasets", "airbnb", "_config_airbnb.R"))

listings_raw <- read.csv(DATA_RAW)

# check classes
class(listings_raw$price)
class(listings_raw$review_scores_rating)
class(listings_raw$accommodates)
class(listings_raw$number_of_reviews)

# clean price column
listings_raw$price <- parse_number(listings_raw$price)

class(listings_raw$price)

# create filtered dataset
listings_cleaned <-
  listings_raw %>%
  filter(!is.na(price) & price < 500 &
           !is.na(review_scores_rating) &
           number_of_reviews >= 10)
nrow(listings_cleaned)
# There are 11788 observations after we cleaned, less than 1/4 of the original

saveRDS(listings_cleaned,
        file.path(DATA_PROC, paste0("listings_", tolower(REGION), "_cleaned.rds")))
