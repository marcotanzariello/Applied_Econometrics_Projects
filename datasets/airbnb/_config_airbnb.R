# _config_airbnb.R — parametri dataset Airbnb
REGION     <- "Puglia"
DATA_RAW   <- here::here("datasets", "airbnb", "listings",
                          paste0("listings_", REGION, ".csv"))
DATA_PROC  <- here::here("datasets", "airbnb", "processed")
SCORES_DIR <- here::here("datasets", "airbnb", "neigh_scores")
