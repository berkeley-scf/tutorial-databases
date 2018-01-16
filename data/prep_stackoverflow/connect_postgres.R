library(xml2)
library(dplyr)
library(stringr)
library(RPostgreSQL)

drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, 
                 dbname = "stackoverflow", 
                 user = 'paciorek', 
                 password = 'test')
