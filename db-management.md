---
layout: default
title: Database management
---

We’ll illustrate some basic database management using a different
example dataset. This is some data on webtraffic to Wikipedia pages.
Note that the input file used here involved some pre-processing relative
to the data you get the directly from the Wikistats dataset available
through Amazon Web Services (AWS) because in the data posted on AWS, the
datetime information is part of the filename, rather tha field(s) in the
table.

# 1 SQLite

## 1.1 Setting up a database and using the SQLite command line

With SQLite you don’t need to deal with all the permissions and
administrative overhead because an SQLite database is simply a file that
you can access without a password or connecting to a database server
process.

To start the SQLite interpreter in Linux, either operating on or
creating a database named `wikistats.db`:

``` bash
sqlite3 wikistats.db
```

Here’s the syntax to create an (empty) table:

``` bash
create table webtraffic
(date char(8), hour char(6), site varchar, page varchar, count integer, size double precision);
.quit
```

## 1.2 Populating a table

Here’s an example of reading from multiple files into SQLite using the
command line. We create a file `import.sql` that has the configuration
for the import:

    .separator " "
    .import /dev/stdin webtraffic

Then we can iterate through our files from the UNIX shell, piping the
output of gzip to the `sqlite3` interpreter:

``` bash
for file in $(ls part*gz); do
    echo "copying $file"
    gzip -cd $file | sqlite3 wikistats.db '.read import.sql'
done
```

## 1.3 Data cleaning

The problem in this example with importing into SQLite is the presence
of double quote (") characters that are not meant to delineate strings
but are actually part of a field. In this case probably the easiest
thing is simply to strip out those quotes from UNIX. Here we use `sed`
to search and replace to create versions of the input files that don’t
have the quotes.

``` bash
for file in $(ls *gz); do
    gzip -cd ${file} | sed  "s/\"//g" | gzip -c > wikistats-cleaned/${file}
done
```

If you want to read the data into SQLite yourself, you *will* need to do
something about the quotes; I haven’t stripped them out of the files.

# 2 PostgreSQL

## 2.1 Setting up a database and using the Postgres command line

First make sure Postgres is installed on your machine.

On Ubuntu, you can install Postgres easily via `apt-get`:

``` bash
sudo apt-get install postgresql postgresql-contrib
```

Next we’ll see how to set up a database. You’ll generally need to
operate as the `postgres` user for these sorts of manipulations. Of
course if you’re just a user accessing an existing database and existing
tables, you don’t need to worry about this.

``` bash
sudo -u postgres -i  # become the postgres user
psql  # start postgres interpreter
```

Now from within the Postgres interpreter, you can create a database,
tables within the database, and authenticate users to do things with
those tables.

    create database wikistats;
    create user paciorek with password 'test';
    grant all privileges on database wikistats to paciorek;

PostgreSQL and other DBMS (not SQLite) allow various kinds of control
over permissions to access and modify databases and tables as well. It
can get a bit involved because the administrator has fine-grained
control over what each user can do/access.

Now let’s create a table in the database, after first connecting to the
specific database so as to operate on it.

    \connect wikistats
    create table webtraffic (date char(8), hour char(6), site varchar, page varchar,
           count integer, size double precision);
    grant all privileges on table webtraffic to paciorek;
    \quit

Note the use of `\` to do administrative tasks (as opposed to executing
SQL syntax), and the use of `;` to end each statement. Without the
semicolon, Postgres will return without doing anything.

If you want control over where the database is stored (you probably only
need to worry about this if you are creating a large database), you can
do things like this:

    show data_directory;
    create tablespace dbspace location '/var/tmp/pg';
    create database wikistats tablespace dbspace;
    create user paciorek with password 'test';
    grant all privileges on database wikistats to paciorek;

## 2.2 Populating a table

Here’s an example of importing a single file into Postgres from within
the psql interpreter running as the special postgres user. In this case
we have space-delimited text files. You can obtain the file `part-00000`
as discussed in the introduction (you’ll need to run
`gunzip part-00000.gz` first).

    \connect wikistats
    copy webtraffic from 'part-00000' delimiter ' ';

If one had CSV files, one could do the following

    copy webtraffic from 'part-00000' csv;

To actually handle the Wikistats input files, we need to deal with
backslash characters occurring at the end of text for a given column in
some rows. Ordinarily in standard Postgres ‘text’ format (different from
Postgres ‘csv’ format), a backslash is used to ‘quote’ characters that
would usually be treated as row or column delimiters (i.e., preceding
such a character by a backslash means it is treated as a character that
is part of the field). But we just want the backslash treated as a
character itself. So we need to tell Postgres not to treat a backslash
as the quoting character. To do that we specify the `quote` character.
However, the quote keyword is only provided when importing ‘csv’ format.
In ‘csv’ format the double-quote character is by default treated as
delineating the beginning and end of text in a field, but the Wikistats
files have double-quotes as part of the fields. So we need to set the
quote character as neither a double-quote nor a backslash. The following
syntax does that by specifying that the quote character is a character (
that never actually appears in the file. The ‘e’ part is so that
Postgres treats
