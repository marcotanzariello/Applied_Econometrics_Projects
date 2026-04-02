library(tidyverse)

listings_Puglia_week2_r = readRDS(here::here("week_2", "analysis", "input", "listings_Puglia_week2_cleaned.rds"))

#estimate models log(price) ~ rating and log(price) ~ rating + accommodates
logprice_rating = lm(log(price) ~ rating,
                     data = listings_Puglia_week2_r)
logprice_rating_accommodates = lm(log(price) ~ rating + accommodates,
                                  data = listings_Puglia_week2_r)

#omitted variable decomposition
beta_rating = logprice_rating$coefficients["rating"]
beta_rating_accommodates = logprice_rating_accommodates$coefficients["rating"]
beta_accommodates = logprice_rating_accommodates$coefficients["accommodates"]
OVB = (beta_rating - beta_rating_accommodates) / beta_accommodates
OVB

#end of Task 1

#neighborhoods analysis
neigh_agent = listings_Puglia_week2_r %>%
  group_by(neighbourhood_cleansed) %>%
  summarise(n = n()) %>%
  filter(n > 100)

#AI agent construction of: Coolness, Centrality (reinterpreted), Quietness and Fanciness
#I used three different agents: ChatGPT, Gemini (thinking) and Perplexity (Deep Research). I will use a weighted average of the three agents' scores to create the final score for each neighborhood.
#The weights are as follows: ChatGPT (0.25), Gemini (0.25) and Perplexity (0.5).
#I gave more weight to Perplexity because I used the Deep Research function. I also asked all the agents to "explain" their process.
#All the results are in analysis/input/agents. Scores as .csv and processes as .txt. The prompt was the same for all the agents. You can find it there as prompt.txt.
#Perplexity's process was also the most detailed and comprehensive, which is another reason why I gave it more weight.

scores_chatgpt = read_csv(here::here("week_2", "analysis", "input", "agents", "puglia_airbnb_scores_chatgpt.csv"))
scores_gemini = read_csv(here::here("week_2", "analysis", "input", "agents", "puglia_airbnb_scores_geminith.csv"))
scores_perplexity = read_csv(here::here("week_2", "analysis", "input", "agents", "puglia_airbnb_scores_perplexity_deepresearch.csv"))

scores_wavg = scores_chatgpt %>%
  left_join(scores_gemini, by = "Location", suffix = c("_chatgpt", "_gemini")) %>%
  left_join(scores_perplexity, by = "Location") %>%
  mutate(Coolness_wavg = 0.25 * Coolness_chatgpt + 0.25 * Coolness_gemini + 0.5 * Coolness,
         Centrality_wavg = 0.25 * Centrality_chatgpt + 0.25 * Centrality_gemini + 0.5 * Centrality,
         Quietness_wavg = 0.25 * Quietness_chatgpt + 0.25 * Quietness_gemini + 0.5 * Quietness,
         Fanciness_wavg = 0.25 * Fanciness_chatgpt + 0.25 * Fanciness_gemini + 0.5 * Fanciness) %>%
  select(Location, Coolness_wavg, Centrality_wavg, Quietness_wavg, Fanciness_wavg)

listings_Puglia_final = listings_Puglia_week2_r %>%
  filter(neighbourhood_cleansed %in% neigh_agent$neighbourhood_cleansed) %>%
  left_join(scores_wavg, by = c("neighbourhood_cleansed" = "Location"))

saveRDS(listings_Puglia_final, here::here("week_2", "analysis", "output", "datasets", "listings_Puglia_final.rds"))

#summary-stat table for neighborhoods variables
summ_var = psych::describe(listings_Puglia_final %>% 
                             select(Coolness_wavg, Centrality_wavg, Quietness_wavg, Fanciness_wavg))
tabella_tex = knitr::kable(summ_var, 
                     format = "latex", 
                     booktabs = TRUE, 
                     digits = 2)
writeLines(tabella_tex, here::here("week_2", "analysis", "output", "tables", "summ_var.tex"))

#build a regression model with the new variables, then a regression table with the three models
model_final = lm(log(price) ~ rating + accommodates + Coolness_wavg + Centrality_wavg + Quietness_wavg + Fanciness_wavg,
                 data = listings_Puglia_final)

three_models = list("Log(price)-rating" = logprice_rating,
                    "Log(price)-rating-acc" = logprice_rating_accommodates,
                    "Log(price)-final" = model_final)
modelsummary::modelsummary(three_models,
                           stars = TRUE,
                           statistic = "std.error",
                           output = here::here("week_2", "analysis", "output", "tables", "three_models.tex"))

#interpretation of the table: 