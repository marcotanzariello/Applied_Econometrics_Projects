install.packages("tidyverse")
install.packages("dplyr")
library(tidyverse)
library(dplyr)

#cleaning the dataset and creating a standardized variable
listings_Puglia_week2 = readRDS("../../../week_1/build/output/listings_Puglia_cleaned.rds")
listings_Puglia_week2_r = listings_Puglia_week2 %>%
  filter(accommodates <= 6) %>%
  mutate(rating = as.numeric(scale(review_scores_rating)))

mean(listings_Puglia_week2_r$rating)
sd(listings_Puglia_week2_r$rating)

#estimate models log(price) ~ rating and log(price) ~ rating + accommodates
logprice_rating = lm(log(price) ~ rating,
                     data = listings_Puglia_week2_r)
logprice_rating_accommodates = lm(log(price) ~ rating + accommodates,
                                data = listings_Puglia_week2_r)