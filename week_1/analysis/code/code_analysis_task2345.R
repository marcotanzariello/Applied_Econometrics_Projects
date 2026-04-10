library(tidyverse)
library(psych)
listings_Puglia_cleaned = read_rds(here::here("week_1", "build", "output", "listings_Puglia_cleaned.rds"))

#TASK 2
#create a subset with just the columns we need and then create the summary statistics table
Var_stats = listings_Puglia_cleaned %>%
  select(price, review_scores_rating, accommodates)
summ_stats = describe(Var_stats)[c("mean", "median", "sd", "min", "max", "n")]
#Prices are right-skewed (median<mean), and they also have an high standard deviation. They cover a wide range (from 13 to 499)
#Reviews distribution is much more stable. We can affirm they're informative, with data concentrated around 4.8 with low standard deviation
#Accomodates have relatively big positive outliers, but mean and median are both around 4

library(knitr)
tabella_tex <- kable(summ_stats, 
                     format = "pipe", 
                     booktabs = TRUE, 
                     digits = 2)
writeLines(tabella_tex, here::here("week_1", "analysis", "output", "tables", "summary_stats.md"))




#TASK 3
#select accomodates = 2
listings_acc2 = listings_Puglia_cleaned %>%
  filter(accommodates == 2)

#create price histogram
price_histogram = ggplot(listings_acc2, aes(x = price)) +
  geom_histogram(binwidth = 10,
                 colour = "white",
                 fill = "steelblue") +
  labs(x = "Price (€)",
       y = "Frequency",
       title = "Price Histogram") +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5, face = "bold", size = 16))
price_histogram
ggsave(here::here("week_1", "analysis", "output", "figures", "price_histogram.png"), width = 7, height = 5)

#create scatter plot of price against review scores
scatter_price_rev = ggplot(listings_acc2, aes(x = review_scores_rating, y = price)) +
  geom_point(colour = "steelblue",
             alpha = 0.3) +
  geom_smooth(method = "lm",
              colour = "red",
              se = TRUE) +
  labs(x = "Review Scores",
       y = "Price (€)",
       title = "Price Against Reviews Scatter Plot") +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5, face = "bold", size = 16))
scatter_price_rev
ggsave(here::here("week_1", "analysis", "output", "figures", "scatter_price_rev.png"), width = 7, height = 5)

#correlation between prices and review scores
corr_pr = cor(listings_acc2$price, listings_acc2$review_scores_rating)
corr_pr
#This confirms what we see in the graph, there is a sligthly positive correlation

#TASK 4
#collapse on neighbourhood_cleansed
neigh_clean = listings_acc2 %>%
  group_by(neighbourhood_cleansed) %>%
  summarise(mean_price = mean(price),
            listings = n())

#graph for neighborhood averages, I excluded neighbourhood with less than 5 listings to avoid overcrowding
neigh_plot = neigh_clean %>%
  filter(listings > 5) %>%
  ggplot(aes(x = mean_price, y = (reorder(neighbourhood_cleansed, mean_price)))) +
  geom_point(colour = "steelblue",
             aes(size = listings),
             alpha = 0.6) +
  scale_size_continuous(name = "N. Listings",
                        breaks = c(5, 50, 100, 200, 500),
                        limits = c(5, 550),
                        range = c(2,10)) +
  labs(x = "Average Price (€)",
       y = "Neighbourhood",
       title = "Average price per neighbourhood") +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5, face = "bold", size = 16),
        axis.text.y = element_text(size = 8, face = "bold"),
        panel.grid.major.y = element_line(colour = "grey", linewidth = 0.2),
        panel.grid.major.x = element_blank(),
        panel.grid.minor = element_blank())
neigh_plot
ggsave(here::here("week_1", "analysis", "output", "figures", "neigh_plot.png"), width = 11, height = 8)
#The cheapest neighbourhood is Foggia. This could be explained with the city's reputation. Foggia's known for high crime and low care of the city levels
#The most expensive is Alberobello, a well known tourist destination.

#TASK 5
#filter for accomodates <= 6
listings_acc6 = listings_Puglia_cleaned %>%
  filter(accommodates <= 6)
#first regression, price on review scores
reg_price_rev = lm(price ~ review_scores_rating,
                   data = listings_acc6)
#slope = 57,43. Keeping other factors constant, a 1 review score increase it's associated with a 57.43€ increase in price.

#second regression, price on accomodates
reg_price_acc = lm(price ~ accommodates,
                   data = listings_acc6)
#slope = 12.53. Accomodating 1 guest more it's associated with an increase of 12.53€ in price

#check sample moment conditions
#first condition mean(u)=0
mean(reg_price_acc$residuals)

#second condition
cov(reg_price_acc$residuals, listings_acc6$accommodates)

#third condition
y_pred = reg_price_acc$coefficients[1] + reg_price_acc$coefficients[2]*mean(listings_acc6$accommodates)
mean(listings_acc6$price) == y_pred
#the difference between the two values is very small, imputable to coefficients arrotondation

#scatter plot price vs accommodates
mean_acc6 = mean(listings_acc6$accommodates)
scatter_price_acc = listings_acc6 %>%
  ggplot(aes(x = accommodates, y = price)) +
  geom_point(colour = "steelblue",
             alpha = 0.3) +
  geom_smooth(method = "lm",
              colour = "red") +
  geom_vline(xintercept = mean_acc6,
             linetype = "dashed",
             linewidth = 0.8) +
  geom_hline(yintercept = y_pred,
             linetype = "dashed",
             linewidth = 0.8) +
  labs(x = "Accommodates",
       y = "Price (€)",
       title = "Scatter Plot Price vs Accommodates") +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5, face = "bold", size = 16))
scatter_price_acc
ggsave(here::here("week_1", "analysis", "output", "figures", "scatter_price_acc.png"), width = 7, height = 5)
#computing TSS, RSS, ESS
TSS = sum((listings_acc6$price - mean(listings_acc6$price))^2)
RSS = sum(reg_price_acc$residuals^2)
ESS = sum((reg_price_acc$fitted.values - mean(listings_acc6$price))^2)

#verify TSS = ESS + RSS
TSS - (ESS + RSS)

#compute R^2
R2 = ESS / TSS

#estimating three relationship
level_level = reg_price_acc
log_level = lm(log(price) ~ accommodates,
               data = listings_acc6)
log_log = lm(log(price) ~ log(accommodates),
             data = listings_acc6)

#regression table
library(modelsummary)
models_3 = list("Level-Level" = level_level,
                "Log-Level" = log_level,
                "Log-Log" = log_log)
modelsummary(models_3,
             stars = TRUE,
             statistic = "std.error",
             output = here::here("week_1", "analysis", "output", "tables", "models_3.md"))

#In the Level-Level, for each 1 unit guest capacity increase, price increases by 12.533 euros
#In the Log-Level, for each 1 unit guest capacity increase, price increases by 11.2%
#In the Log-Log, for each 1% increase in guest capacity, price increases by o.368%
#I would choose the Log-Level model. It has the highest R^2 and economically is more likely that more guest capacity means a percentage increase in price rather than an absolute value

#create the new figure
#mean prices for each number of accommodates
means_foracc = listings_acc6 %>%
  group_by(accommodates) %>%
  summarize(mean_price = mean(price))

fitted_lines = data.frame(accommodates = sort(unique(listings_acc6$accommodates)))
fitted_lines$level_level = predict(level_level,
                                   newdata = fitted_lines)
fitted_lines$log_level = exp(predict(log_level,
                                     newdata = fitted_lines))
fitted_lines$log_log = exp(predict(log_log,
                                   newdata = fitted_lines))

#create the scatterplot

scatter_models = listings_acc6 %>%
  ggplot(aes(x = accommodates, y = price)) +
  geom_point(colour = "steelblue",
             alpha = 0.3) +
  geom_point(data = means_foracc,
             aes(y = mean_price),
             colour = "black",
             size = 5,
             shape = 4,
             stroke = 2.5) +
  geom_line(data = fitted_lines,
            aes(x = accommodates, y = level_level,
                colour = "Level-Level"),
            linewidth = 1.2) +
  geom_line(data = fitted_lines,
            aes(x = accommodates, y = log_level,
                colour = "Log-Level"),
            linewidth = 1.2) +
  geom_line(data = fitted_lines,
            aes(x = accommodates, y = log_log,
                colour = "Log-Log"),
            linewidth = 1.2) +
  scale_color_manual(name = "Three Models",
                     values = c("Level-Level" = "red",
                                "Log-Level" = "green",
                                "Log-Log" = "purple")) +
  labs(x = "Accommodates",
       y = "Price (€)",
       title = "Scatter Plot Three Models") +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5, face = "bold", size = 16))
scatter_models
ggsave(here::here("week_1", "analysis", "output", "figures", "scatter_models.png"), width = 7, height = 5)
#We are now treating the effect of an additional guest as constant. We could use a model with a dummy variable for each number of accommodates (from 1 to 6), to capture specific effects for each step.
