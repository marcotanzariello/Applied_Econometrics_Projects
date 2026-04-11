# Script:  data_analysis.R
# Purpose: OVB decomposition, AI neighbourhood scores regression, t-test, confidence interval, F-test
# Input:   datasets/airbnb/processed/listings_{region}_week2.rds
#          datasets/airbnb/neigh_scores/puglia_scores_{agent}.csv
# Output:  datasets/airbnb/processed/listings_{region}_final.rds
#          week_2/analysis/output/tables/, week_2/analysis/output/figures/

library(tidyverse)
source(here::here("datasets", "airbnb", "_config_airbnb.R"))

# guard-rail: AI score CSVs must exist for the configured region before proceeding
required_scores <- file.path(
  AIRBNB_SCORES,
  paste0(tolower(REGION), "_scores_", c("chatgpt", "gemini", "perplexity"), ".csv")
)
missing_scores <- required_scores[!file.exists(required_scores)]
if (length(missing_scores)) {
  stop(
    "Missing AI score files for REGION='", REGION, "':\n  ",
    paste(missing_scores, collapse = "\n  "),
    "\nGenerate score CSVs under ", AIRBNB_SCORES, " before running this script."
  )
}

# Task 1

listings_week2 <- readRDS(
  file.path(AIRBNB_PROC, paste0("listings_", tolower(REGION), "_week2.rds"))
)
listings_week2 <- listings_week2 %>%
  mutate(neighbourhood_cleansed = stringi::stri_trans_general(neighbourhood_cleansed, "Latin-ASCII"))

# estimate models log(price) ~ rating and log(price) ~ rating + accommodates
logprice_rating <- lm(log(price) ~ rating,
  data = listings_week2
)
logprice_rating_accommodates <- lm(log(price) ~ rating + accommodates,
  data = listings_week2
)

# omitted variable decomposition
beta_rating <- logprice_rating$coefficients["rating"]
beta_rating_accommodates <- logprice_rating_accommodates$coefficients["rating"]
beta_accommodates <- logprice_rating_accommodates$coefficients["accommodates"]
OVB <- (beta_rating - beta_rating_accommodates) / beta_accommodates
OVB

# end of Task 1

# Task 2

# neighborhoods analysis
neigh_agent <- listings_week2 %>%
  group_by(neighbourhood_cleansed) %>%
  summarise(n = n()) %>%
  filter(n > 100)

# AI agent construction of: Coolness, Centrality (reinterpreted), Quietness and Fanciness
# I used three different agents: ChatGPT, Gemini (thinking) and Perplexity (Deep Research). I will use a weighted average of the three agents' scores to create the final score for each neighborhood.
# The weights are as follows: ChatGPT (0.25), Gemini (0.25) and Perplexity (0.5).
# I gave more weight to Perplexity because I used the Deep Research function. I also asked all the agents to "explain" their process.
# Score CSVs are stored in datasets/airbnb/neigh_scores/ (loaded via AIRBNB_SCORES). Prompt and process notes remain in week_2/analysis/input/agents/.
# Perplexity's process was also the most detailed and comprehensive, which is another reason why I gave it more weight.

scores_chatgpt <- read_csv(file.path(AIRBNB_SCORES, paste0(tolower(REGION), "_scores_chatgpt.csv")))
scores_gemini <- read_csv(file.path(AIRBNB_SCORES, paste0(tolower(REGION), "_scores_gemini.csv")))
scores_perplexity <- read_csv(file.path(AIRBNB_SCORES, paste0(tolower(REGION), "_scores_perplexity.csv")))

scores_wavg <- scores_chatgpt %>%
  left_join(scores_gemini, by = "Location", suffix = c("_chatgpt", "_gemini")) %>%
  left_join(scores_perplexity, by = "Location") %>%
  mutate(
    Coolness_wavg = 0.25 * Coolness_chatgpt + 0.25 * Coolness_gemini + 0.5 * Coolness,
    Centrality_wavg = 0.25 * Centrality_chatgpt + 0.25 * Centrality_gemini + 0.5 * Centrality,
    Quietness_wavg = 0.25 * Quietness_chatgpt + 0.25 * Quietness_gemini + 0.5 * Quietness,
    Fanciness_wavg = 0.25 * Fanciness_chatgpt + 0.25 * Fanciness_gemini + 0.5 * Fanciness
  ) %>%
  select(Location, Coolness_wavg, Centrality_wavg, Quietness_wavg, Fanciness_wavg)

listings_final <- listings_week2 %>%
  filter(neighbourhood_cleansed %in% neigh_agent$neighbourhood_cleansed) %>%
  left_join(scores_wavg, by = c("neighbourhood_cleansed" = "Location"))

saveRDS(
  listings_final,
  file.path(AIRBNB_PROC, paste0("listings_", tolower(REGION), "_final.rds"))
)

# summary-stat table for neighborhoods variables
summ_var <- psych::describe(listings_final %>%
  select(Coolness_wavg, Centrality_wavg, Quietness_wavg, Fanciness_wavg))
tabella_tex <- knitr::kable(summ_var,
  format = "pipe",
  booktabs = TRUE,
  digits = 2
)
writeLines(tabella_tex, here::here("week_2", "analysis", "output", "tables", "summ_var.md"))

# build a regression model with the new variables, then a regression table with the three models
model_final <- lm(log(price) ~ rating + accommodates + Coolness_wavg + Centrality_wavg + Quietness_wavg + Fanciness_wavg,
  data = listings_final
)

three_models <- list(
  "Log(price)-rating" = logprice_rating,
  "Log(price)-rating-acc" = logprice_rating_accommodates,
  "Log(price)-final" = model_final
)
modelsummary::modelsummary(three_models,
  stars = TRUE,
  statistic = "std.error",
  output = here::here("week_2", "analysis", "output", "tables", "three_models.md")
)

# interpretation of the table: We see that centrality and fanciness are the most significant variables, with
# a positive coefficient (+1 fanciness = +12.6% price, +1 centrality = +4% price). Quietness sign is negative, suggesting that quieter
# neighborhoods are less expensive. Coolness is the strangest. It has a negative coefficient (+1 coolness = -11.1% price)
# We can interpret this as the fact that cooler neighborhoods are more crowded, and therefore Airbnb hosts
# will have to lower their prices to attract customers. We can check if there is a relationship between coolness and the number of listings in a neighborhood to confirm this hypothesis.
coolness_nlistings <- listings_final %>%
  group_by(neighbourhood_cleansed) %>%
  summarise(
    n_listings = n(),
    coolness = mean(Coolness_wavg)
  ) %>%
  ggplot(aes(x = coolness, y = n_listings)) +
  geom_point() +
  geom_smooth(method = "lm") +
  labs(
    title = "Relationship between Coolness and Number of Listings",
    x = "Coolness (weighted average)",
    y = "Number of Listings"
  )
coolness_nlistings
ggsave(here::here("week_2", "analysis", "output", "figures", "coolness_nlistings.png"), coolness_nlistings, width = 8, height = 6)

# The plot shows a positive relationship between coolness and the number of listings, supporting our thesis
# Rating coefficient went down, we can suggest that rating itself represents the positive and negative
# aspects of the house, and if you add the single characteristics the value of the rating loses his role
# The accommodates coefficient rose from 0.109 to 0.126. Guest capacity becomes more important when we control for the characteristics of the neighborhood.
# R2 went up to 0.187, the model explain more of the variation in price. RMSE diminished, so we can affirm this is the best of the three models

# end of Task 2

# Task 3

summary(model_final)

# Obtain residuals and assess normality
residuals_final <- residuals(model_final)

# residual density plot with an overlaid normal density
residuals_density <- ggplot(data.frame(residuals_final), aes(x = residuals_final)) +
  geom_density(fill = "steelblue", alpha = 0.5) +
  stat_function(
    fun = dnorm,
    args = list(mean = mean(residuals_final), sd = sd(residuals_final)),
    color = "red",
    size = 1
  ) +
  labs(
    title = "Density of Residuals with Normal Overlay",
    x = "Residuals",
    y = "Density"
  )
residuals_density
ggsave(here::here("week_2", "analysis", "output", "figures", "residuals_density.png"), residuals_density, width = 8, height = 6)

# Jarque-Bera test
jq_test <- tseries::jarque.bera.test(residuals_final)
jq_test

# p value is less than 0.05, we reject the null hypothesis of normality.

# For centrality, manually compute the following values for a two-sided t-test of H0 :
# H0 : βcentrality = 0 vs. H1 : βcentrality ≠ 0:
# (a) t-statistic,
# (b) p-value,
# (c) 5% critical value.
beta_centrality <- model_final$coefficients["Centrality_wavg"]
sd_centrality <- summary(model_final)$coefficients["Centrality_wavg", "Std. Error"]
t_stat <- beta_centrality / sd_centrality

p <- 2 * (1 - pt(abs(t_stat), df = model_final$df.residual))
critical_value <- qt(0.975, df = model_final$df.residual)

# t_stat is 6.6654, p-value is 2.83e-11, critical value is 1.96. We reject the null hypothesis and conclude that centrality is a significant predictor of price.

# Create a t-distribution figure showing rejection regions, critical values, and your test
# statistic with vertical lines.
t_dist_plot <- ggplot(data.frame(x = seq(-10, 10, length.out = 1000)), aes(x = x)) +
  stat_function(fun = dt, args = list(df = model_final$df.residual), color = "blue") +
  geom_vline(xintercept = c(-critical_value, critical_value), color = "red", linetype = "dashed") +
  geom_vline(xintercept = t_stat, color = "green", linetype = "dashed") +
  labs(
    title = "t-Distribution with Rejection Regions and Test Statistic",
    x = "t-value",
    y = "Density"
  )
t_dist_plot
ggsave(here::here("week_2", "analysis", "output", "figures", "t_dist_plot.png"), t_dist_plot, width = 8, height = 6)

# end of Task 3

# Task 4

# manually compute the 95% confidence interval for the centrality coefficient
lower_bound <- beta_centrality - critical_value * sd_centrality
upper_bound <- beta_centrality + critical_value * sd_centrality
conf_interval <- c(lower_bound, upper_bound)
conf_interval

# figure with lower and upper bounds of the confidence interval, and the point estimate with vertical lines
conf_interval_plot <- ggplot() +
  geom_vline(xintercept = beta_centrality, color = "green", linetype = "dashed") +
  geom_vline(xintercept = conf_interval, color = "red", linetype = "dashed") +
  xlim(beta_centrality - 3 * sd_centrality, beta_centrality + 3 * sd_centrality) +
  labs(
    title = "95% Confidence Interval for Centrality Coefficient",
    x = "Coefficient Value",
    y = ""
  )
conf_interval_plot
ggsave(here::here("week_2", "analysis", "output", "figures", "conf_interval_plot.png"), conf_interval_plot, width = 8, height = 6)

# the t-test and the C.I both suggest that centrality is a significant predictor of price. C.I does not include zero, and the t-test rejects the null hypothesis of no effect. We can be confident that centrality has a positive effect on price.

# recalculate model 2 with the cleaned dataset to run F-test
logprice_rating_accommodates_cleaned <- lm(log(price) ~ rating + accommodates,
  data = listings_final
)

# joint F-test for the null hypothesis that the coefficients of the four neighborhood characteristics are all zero
ssr_final <- sum(residuals(model_final)^2)
ssr_logprice_rating_accommodates_cleaned <- sum(residuals(logprice_rating_accommodates_cleaned)^2)

f_stat <- ((ssr_logprice_rating_accommodates_cleaned - ssr_final) / 4) / (ssr_final / (model_final$df.residual - 7))
f_stat

# p-value
p_f <- pf(f_stat, df1 = 4, df2 = model_final$df.residual - 7, lower.tail = FALSE)
p_f

# anova test
anova_result <- anova(logprice_rating_accommodates_cleaned, model_final)
anova_result

# Conclusion: neighborhood characteristics are jointly significant.
