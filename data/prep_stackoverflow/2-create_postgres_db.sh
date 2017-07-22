#!/bin/bash
## run on an Ubuntu Linux machine with postgres installed and admin privileges
sudo su - postgres
psql
CREATE TABLESPACE dbspace LOCATION '/var/tmp/pg';
CREATE DATABASE stackoverflow TABLESPACE dbspace;
CREATE USER paciorek WITH PASSWORD 'test';
GRANT ALL PRIVILEGES ON DATABASE "stackoverflow" to paciorek;


