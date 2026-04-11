# _config_airbnb.R — parameters for the Airbnb dataset
REGION        <- "Puglia"
AIRBNB_RAW    <- here::here("datasets", "airbnb", "listings",
                             paste0("listings_", REGION, ".csv"))
AIRBNB_PROC   <- here::here("datasets", "airbnb", "processed")
AIRBNB_SCORES <- here::here("datasets", "airbnb", "neigh_scores")
