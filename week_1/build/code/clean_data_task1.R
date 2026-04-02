library(tidyverse)

listings_Puglia = read.csv(here::here("week_1", "build", "input", "listings_Puglia.csv"))
#check classes
class(listings_Puglia$price)
class(listings_Puglia$review_scores_rating)
class(listings_Puglia$accommodates)
class(listings_Puglia$number_of_reviews)

#clean price column
listings_Puglia$price = parse_number(listings_Puglia$price)

class(listings_Puglia$price)
#create filtered dataset
listings_Puglia_cleaned = 
  listings_Puglia %>%
  filter(!is.na(price) & price < 500 &
           !is.na(review_scores_rating) &
           number_of_reviews >= 10)
nrow(listings_Puglia_cleaned)
#There are 11788 observations after we cleaned, less than 1/4 of the original

saveRDS(listings_Puglia_cleaned, here::here("week_1", "build", "output", "listings_Puglia_cleaned.rds"))
