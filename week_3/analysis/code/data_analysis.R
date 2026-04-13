library(tidyverse)
library(fixest)
source(here::here("datasets", "US_state_year", "_config_fatality.R"))

fatality_panel <- read_rds(file.path(FATAL_PROC, "fatality_panel.rds"))

# 1.4 - descriptive table
descriptive_table <- fatality_panel %>%
  select(mrall, beertax, mlda, jaild, comserd, vmiles, unrate, perinc) %>%
  knitr::kable(col.names = c("Traffic Fatality Rate", "Real Beer Tax", "Minimum Legal Drinking Age", "Jail Sentence for Drunk Driving", "Community Service for Drunk Driving", "Vehicle Miles Traveled", "Unemployment Rate", "Per Capita Income"),
    format = "pipe",
    digits = 2
  )
writeLines(descriptive_table, here::here("week_3", "analysis", "output", "tables", "descriptive_table.md"))

#2.1 - Pooled OLS regression
fatality_panel$mlda_fact <- as.factor(round(fatality_panel$mlda, 2))
fatality_panel$dummy_jailcom <- ifelse(fatality_panel$jaild == 1 | fatality_panel$comserd == 1, 1, 0)
fatality_panel$mrall_scaled <- fatality_panel$mrall * 10000

pooled_ols <- lm(mrall_scaled ~ beertax + mlda_fact + dummy_jailcom + vmiles + unrate + perinc, data = fatality_panel)
model_pooled <- modelsummary::modelsummary(pooled_ols, 
  stars = TRUE, 
  statistic = "std.error",
  output = here::here("week_3", "analysis", "output", "tables", "pooled_ols.md") 
)
# 2.2 - Comment
# First reg: dummy_jailcom is significant (***) and strangely positive. We may see an inverse causality issue here, states with higher fatality have more strict rules.
# Second reg: vmiles is significant (***), with a positive sign. We see the coefficient is 0.000, probably for scale problems.

# 2.3 - OVB
# OVB for dummy_jailcom: Reverse causality problem we just observed
# OVB for vmiles: possible omitted variable could be street quality, which could be correlated surely with fatality and with mileage (states with better streets could have more miles traveled and less fatality, or viceversa)


# 3.1 - FE regression (state only + state and year)
pooled_fe_state <- feols(mrall_scaled ~ beertax + mlda_fact + dummy_jailcom + vmiles + unrate + perinc | state, data = fatality_panel)
pooled_fe_state_year <- feols(mrall_scaled ~ beertax + mlda_fact + dummy_jailcom + vmiles + unrate + perinc | state + year, data = fatality_panel)

# 3.2 - Regression table with all 3 models
models_fe <- list(
  "Pooled OLS" = pooled_ols,
  "FE State" = pooled_fe_state,
  "FE State and Year" = pooled_fe_state_year
)
model_fe_table <- modelsummary::modelsummary(models_fe,
  stars = TRUE,
  statistic = "std.error",
  output = here::here("week_3", "analysis", "output", "tables", "models_fe.md")
)

# 3.3 - Comment
# The dummy_jailcom coefficient is not significant anymore and his sign is incostant, magnitude significantly reduced and zero not escluded by the range. 
# Probably higher fatality states had harder rules (which showed positive correlation), but FE cleared this issue.
# We clearly see a time-invariant State heterogeneity


# 4.1 - FE with State - clustered sd
pooled_fe_state_clust <- feols(mrall_scaled ~ beertax + mlda_fact + dummy_jailcom + vmiles + unrate + perinc | state + year, data = fatality_panel, 
  cluster = "state")
two_way_list <- list(
  "FE State and Year" = pooled_fe_state_year,
  "FE State and Year (Clustered SE)" = pooled_fe_state_clust
)
model_fe_clustered <- modelsummary::modelsummary(two_way_list,
  stars = TRUE,
  statistic = "std.error",
  output = here::here("week_3", "analysis", "output", "tables", "two_way_clustered.md")
)

# 4.2 - Comment
# beertax became non-significant, unemployment rate resisted, income effect lost some relevance but is still significant.
# mlda 18.5 became ** significant, need to chek why

# 4.3 - Test for year FE significance
test_FE_year <- wald(pooled_fe_state_clust)

# Reject H0, Fstat = 7.89, p-value = 1.36^-8, DoF = 16 (num), DoF = 47 (denom)