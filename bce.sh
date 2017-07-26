#!/bin/bash

## UNIX bash shell script illustrating use of postgres within a BCE-based virtual machine, for use if you do not have access to a Postgres database.

## download the Wikistats data
wget http://www.stat.berkeley.edu/share/paciorek/tutorial-databases-data.zip 
unzip tutorial-databases-data.zip
gunzip part-00000.gz

## install Postgres
sudo apt-get install -y postgresql postgresql-contrib libpq-dev

## switch to be the postgres user and create the database and add data
sudo su - postgres
psql 

## now run commands shown in databases.html to create a database and tables and put data in the tables 

exit

sudo Rscript -e "install.packages('RPostgreSQL')"

R
## remaining commands in R:
library(RPostgreSQL)
drv = dbDriver('PostgreSQL')
db = dbConnect(drv, dbname = 'wikistats', user = 'paciorek', password = 'test',
               host = 'localhost', port = 5432)

