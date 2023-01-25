library(xml2)
library(dplyr)
library(stringr)
library(RPostgreSQL)

drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, 
                 dbname = "stackoverflow2", 
                 user = 'paciorek', 
                 password = 'test')
