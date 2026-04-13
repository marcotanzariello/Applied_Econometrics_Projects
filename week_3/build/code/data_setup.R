# Script:  data_setup.R
# Purpose: Loads fatality panel data, performs initial setup and writes processed output
# Input:   datasets/US_state_year/fatality.dta  (FATAL_RAW from config)
# Output:  datasets/US_state_year/processed/    (FATAL_PROC from config)
library(tidyverse)
library(haven)
library(plm)
source(here::here("datasets", "US_state_year", "fatality", "_config_fatality.R"))

# fail fast if the raw Stata file is missing
if (!file.exists(FATAL_RAW)) {
  stop("Missing fatality panel file: ", FATAL_RAW)
}

# 1.1 - load raw fatality panel data
fatality_raw = read_dta(FATAL_RAW)

# filter to configured year range
fatality = fatality_raw %>%
  dplyr::filter(year >= YEAR_RANGE[1], year <= YEAR_RANGE[2]) 

# interpret stata labeled variables as factors
fatality = as_factor(fatality)

# 1.2 - panel dimensions
n_states = length(unique(fatality$state))
n_years = length(unique(fatality$year))

# 1.3 - declare panel data structure
fatality_panel = pdata.frame(fatality, index = c("state", "year"))

saveRDS(fatality_panel, file.path(FATAL_PROC, "fatality_panel.rds"))