library(tidyverse)

#cleaning the dataset and creating a standardized variable
listings_Puglia_week2 = readRDS(here::here("week_1", "build", "output", "listings_Puglia_cleaned.rds"))
listings_Puglia_week2_r = listings_Puglia_week2 %>%
  filter(accommodates <= 6) %>%
  mutate(rating = as.numeric(scale(review_scores_rating)))

mean(listings_Puglia_week2_r$rating)
sd(listings_Puglia_week2_r$rating)

saveRDS(listings_Puglia_week2_r, here::here("week_2", "build", "output", "listings_Puglia_week2_cleaned.rds"))
