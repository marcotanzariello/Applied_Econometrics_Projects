# Script:  data_setup.R
# Purpose: Loads fatality panel data, performs initial setup and writes processed output
# Input:   datasets/US_state_year/fatality.dta  (DATA_FATAL from config)
# Output:  datasets/US_state_year/processed/    (DATA_PROC from config)
library(tidyverse)
library(haven)
source(here::here("datasets", "US_state_year", "_config_fatality.R"))

# load raw fatality panel data
fatality_raw <- read_dta(DATA_FATAL)

# filter to configured year range
fatality <- fatality_raw %>%
  dplyr::filter(year >= YEAR_RANGE[1], year <= YEAR_RANGE[2])

saveRDS(fatality, file.path(DATA_PROC, "fatality_panel.rds"))
