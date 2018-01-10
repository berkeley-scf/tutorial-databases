#!/bin/bash

## UNIX bash shell script illustrating use of postgres within a Docker container, for use if you do not have access to a Postgres database.

## A docker container is basically a Linux (virtual) machine running within your computer.

## Docker containers often come with only a minimal amount of software installed and you need to install the software you want. But you can start up containers that have some software pre-installed. In this particular example it was easiest to run a container with R already installed and then to add PostgreSQL to the container.

## If you follow the steps below you will be in a a Docker container in which you can create a PostgreSQL database, add data to the database and then access it from R, we do in the tutorial. 


## Run a container with R already installed, starting a bash shell terminal session in the container. Also forward port 5432 on the container to local port 63333 for later use.
docker run --rm -p 63333:5432 -ti  rocker/r-base /bin/bash

## install Postgres and SSH/SCP (the latter for copying files into the container)
apt-get install postgresql postgresql-contrib libpq-dev
apt-get install openssh-client

## If you want to be able to connect to postgres from outside the container, do these steps:
PG_VER=10  # modify as needed
echo -e "host\tall\t\tall\t\t0.0.0.0/0\t\tmd5" >> /etc/postgresql/PG_VER/main/pg_hba.conf
sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" /etc/postgresql/PG_VER/main/postgresql.conf

## start the postgres server process
/etc/init.d/postgresql start

## get the data into the container
mkdir /data
scp paciorek@smeagol.berkeley.edu:~/share/tutorial-databases-data.zip /data/.

## switch to be the postgres user and create the database and add data
su - postgres
psql

## now run commands shown in databases.html to create a database and tables and put data in the tables, but as we'll be acting as the 'docker' user below, make sure to create a 'docker' postgres user.

exit

## Connecting to the database from within the container:
Rscript -e "install.packages('RPostgreSQL')"

## Now switch to a non-root user (to mimic how you would usually be operating) and then run R
sudo su - docker
R
## now connect to database via R (or Python if you have a container with Python installed) as seen in databases.html


## Connecting to the database from outside the container:
## from within R, connect as:
drv <- dbDriver("PostgreSQL")
db <- dbConnect(drv, dbname = 'wikistats', user = 'docker',
                password = 'test', port = 63333, host = 'localhost')
