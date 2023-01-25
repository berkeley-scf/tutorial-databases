#!/bin/bash
cd /scratch/users/paciorek/stackoverflow
wget https://archive.org/download/stackexchange/Stackoverflow.com-Posts.7z ## 11 GB
wget https://archive.org/download/stackexchange/stackoverflow.com-Users.7z ## 300 MB  
7z e Stackoverflow.com-Posts.7z  # unzips to Posts.xml, 100 GB
7z e stackoverflow.com-Users.7z  # unzips to Users.xml, 7 GB
