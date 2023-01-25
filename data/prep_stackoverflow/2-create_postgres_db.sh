#!/bin/bash
## run on an Ubuntu Linux machine with postgres installed and admin privileges
sudo -u postgres -i
mkdir /var/lib/postgresql/tmpdb  ## can't find /var/tmp/foo (namespacing?)
psql
CREATE TABLESPACE dbspace LOCATION '/var/lib/postgresql/tmpdb';
CREATE DATABASE stackoverflow2 TABLESPACE dbspace;  ## stackoverflow already exists (huh?)
CREATE USER paciorek WITH PASSWORD 'test';
GRANT ALL PRIVILEGES ON DATABASE "stackoverflow2" to paciorek;


