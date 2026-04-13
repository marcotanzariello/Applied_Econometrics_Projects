# 1.1 - Load data
# Use bcuse 85-95. In R the equivalent is AER package with "CigarettesSW" dataset
library(tidyverse)
library(AER)
data("CigarettesSW")

# 1.2 - Create new variables
CigarettesSW$lpackpc = log(CigarettesSW$packs)
CigarettesSW$ravgprs = (CigarettesSW$price / CigarettesSW$cpi)
CigarettesSW$lravgprs = log(CigarettesSW$ravgprs)
CigarettesSW$rincome = (CigarettesSW$income / CigarettesSW$population / CigarettesSW$cpi)
CigarettesSW$lrincome = log(CigarettesSW$rincome)
CigarettesSW$rtax = (CigarettesSW$tax / CigarettesSW$cpi)
CigarettesSW$rtaxs = (CigarettesSW$taxs / CigarettesSW$cpi)
CigarettesSW$rtaxso = (CigarettesSW$rtaxs - CigarettesSW$rtax)

# 1.3 - Variables explanation:
# lpackpc: log of packs per capita
# ravgprs: avg prices divided by cpi, real price of cigs.
# lravgprs: log of real price of cigs.
# rincome: cigs income divided by population and cpi, real income per capita.
# lrincome: log of real income per capita.
# rtax: tax divided by cpi, real tax.
# rtaxs: total tax (tax + sales tax) divided by cpi, real total tax.
# rtaxso: difference between real total tax and real tax, real sales tax.


# 1.4 - 