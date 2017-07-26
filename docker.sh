#!/bin/bash

## UNIX bash shell script illustrating use of postgres within a Docker container, for use if you do not have access to a Postgres database.

## A docker container is basically a Linux (virtual) machine running within your computer.

## Docker containers often come with only a minimal amount of software installed and you need to install the software you want. But you can start up containers that have some software pre-installed. In this particular example it was easiest to run a container with R already installed and then to add PostgreSQL to the container.

## If you follow the steps below you will be in a a Docker container in which you can create a PostgreSQL database, add data to the database and then access it from R, we do in the tutorial. 


## Run a container with R already installed, starting a bash shell terminal session in the container.
docker run --rm -ti  rocker/r-base /bin/bash

## install Postgres and SSH/SCP (the latter for copying files into the container)
apt-get install postgresql postgresql-contrib libpq-dev
apt-get install openssh-client

## start the postgres server process
/etc/init.d/postgresql start

## get the data into the container
mkdir /data
scp paciorek@smeagol.berkeley.edu:~/share/tutorial-databases-data.zip /data/.

## switch to be the postgres user and create the database and add data
su - postgres
psql

## now run commands shown in databases.html to create a database and tables and put data in the tables

exit

## now one can setup R to use Postgres
Rscript -e "install.packages('RPostgreSQL')"

## Now switch to a non-root user (to mimic how you would usually be operating) and then run R
sudo su - docker
R
## now connect to database via R (or Python if you have a container with Python installed) as seen in databases.html

