# run_all.R — run in order to reproduce all results end-to-end
library(here)

source(here("week_1", "build",    "code", "clean_data_task1.R"))
source(here("week_1", "analysis", "code", "price_analysis.R"))
source(here("week_2", "build",    "code", "data_prep.R"))
source(here("week_2", "analysis", "code", "data_analysis.R"))
source(here("week_3", "build",    "code", "data_setup.R"))
