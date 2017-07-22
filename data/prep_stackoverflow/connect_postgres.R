library(xml2)
library(dplyr)
library(stringr)
library(RPostgreSQL)

drv <- dbDriver("PostgreSQL")
db <- dbConnect(drv, 
                 dbname = "stackoverflow", 
                 user = 'paciorek', 
                 password = 'test')
