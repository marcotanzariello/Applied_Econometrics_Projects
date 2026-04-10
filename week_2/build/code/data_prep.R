# Script:  data_prep.R
# Purpose: Filters listings to accommodates <= 6, standardises review_scores_rating
# Input:   datasets/airbnb/processed/listings_{region}_cleaned.rds
# Output:  datasets/airbnb/processed/listings_{region}_week2.rds

library(tidyverse)
source(here::here("datasets", "airbnb", "_config_airbnb.R"))

# read cleaned dataset produced by week_1 build
listings_base <- readRDS(
  file.path(DATA_PROC, paste0("listings_", tolower(REGION), "_cleaned.rds"))
)

# filter accommodates <= 6 and standardise rating
listings_week2 <- listings_base %>%
  filter(accommodates <= 6) %>%
  mutate(rating = as.numeric(scale(review_scores_rating)))

mean(listings_week2$rating)
sd(listings_week2$rating)

saveRDS(listings_week2,
        file.path(DATA_PROC, paste0("listings_", tolower(REGION), "_week2.rds")))
