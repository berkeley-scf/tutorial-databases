---
layout: default
title: Database management
---

# Database management

We’ll illustrate some basic database management using a different
example dataset that contains some data on webtraffic to Wikipedia
pages. Note that the input file used here involved some pre-processing
relative to the data you get the directly from the Wikistats dataset
available through Amazon Web Services (AWS) because in the data posted
on AWS, the datetime information is part of the filename, rather tha
field(s) in the table.

You can get the raw input files of Wikistats data
[here](http://www.stat.berkeley.edu/share/paciorek/tutorial-databases-data.zip)

## 1 SQLite

### 1.1 Setting up a database and using the SQLite command line

With SQLite you don’t need to deal with all the permissions and
administrative overhead of a client-server style of DBMS because an
SQLite database is simply a file that you can access without a password
or connecting to a database server process.

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

### 1.2 Populating a table

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

### 1.3 Data cleaning

A problem in this example with importing from the data files into SQLite
as above is the presence of double quote (") characters that are not
meant to delineate strings but are actually part of a field. In this
case probably the easiest thing is simply to strip out those quotes from
UNIX. Here we use `sed` to search and replace to create versions of the
input files that don’t have the quotes.

``` bash
for file in $(ls *gz); do
    gzip -cd ${file} | sed  "s/\"//g" | gzip -c > wikistats-cleaned/${file}
done
```

> **Warning**: If you want to read the data into SQLite yourself, you
> *will* need to do something about the quotes; I haven’t stripped them
> out of the files.

## 2 PostgreSQL

### 2.1 Setting up a database and using the Postgres command line

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

> **Note**: Notice the use of `\` to do administrative tasks (as opposed
> to executing SQL syntax), and the use of `;` to end each statement.
> Without the semicolon, Postgres will return without doing anything.

If you want control over where the database is stored (you probably only
need to worry about this if you are creating a large database), you can
do things like this:

    show data_directory;
    create tablespace dbspace location '/var/tmp/pg';
    create database wikistats tablespace dbspace;
    create user paciorek with password 'test';
    grant all privileges on database wikistats to paciorek;

### 2.2 Populating a table

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
syntax does that by specifying that the quote character is a character
(`\b`) that never actually appears in the file. The ‘e’ part is so that
Postgres treats `\b` as a single character, i.e., ‘escaping’ the
backslash, and the ‘csv’ is because the quote keyword only works with
the csv format, but note that by setting the delimiter to a space, it’s
not really a CSV file!

    copy webtraffic from 'part-00000' delimiter ' ' quote e'\b' csv;

Often you’ll need to load data from a large number of possibly zipped
text files. As an example of how you would load data in a case like
that, here’s some shell scripting that will iterate through multiple
(gzipped) input files of Wikistats data, running as the regular user:

``` bash
export PGPASSWORD=test  # set password via UNIX environment variable
for file in $(ls part*gz); do  # loop thru files whose names start with 'part' and end with 'gz'
  echo "copying $file"
  ## unzip and then pass by UNIX pipe to psql run in non-interactive mode
  gzip -cd $file |
    psql -d wikistats -h localhost -U paciorek -p 5432 -c "\copy webtraffic from stdin delimiter ' ' quote e'\b' csv"
done
```

> **Note**: Using `\copy` as above invokes the psql `copy` command
> (`copy` would invoke the standard SQL `copy` command), which allows
> one to operate as a regular user and to use relative paths. In turn
> `\copy` invokes `copy` in a specific way.

### 2.3 Data cleaning

One complication is that often the input files will have anomalies in
them. Examples include missing columns for some rows, individual
elements in a column that are not of the correct type (e.g., a string in
a numeric column), and characters that can’t be handled. In the
Wikistats data case, one issue was lines without the full set of columns
and another was the presence of a backslash character at the end of the
text for a column.

With large amounts of data or many files, this can be a hassle to deal
with. UNIX shell commands can sometimes be quite helpful, including use
of sed and awk. Or one might preprocess files in chunks using Python.

For example the following shell scripting loop over Wikistats files
ensures each row has 6 fields/columns by pulling out only rows with the
full set of columns. I used this to process the input files before
copying into Postgres as done above. Actually there was even more
preprocessing because in the form of the data available from Amazon’s
storage service, the date/time information was part of the filename and
not part of the data files.

``` bash
for file in $(ls *gz); do
    gzip -cd $file | grep "^.* .* .* .* .* .*$" | gzip -c > ../wikistats-fulllines/$file
done
```

Note that this restriction to rows with a full set of fields has already
been done in the data files I provide to you.

## 3 Database administration and configuration miscellanea

You can often get configuration information by making a query. For
example, here’s how one can get information on the cache size in SQLite
or on various settings in Postgres.

``` r
# SQLite
dbGetQuery(db, "pragma cache_size")
dbGetQuery(db, "pragma cache_size=90000")
# sets cache size to ~90 GB, 1 KB/page, but not really relevant as
# operating system should do disk caching automatically

# Postgres
dbGetQuery(db, "select * from pg_settings")
dbGetQuery(db, "select * from pg_settings where name='dynamic_shared_memory_type'") 
```

## 4 Remote access to PostgreSQL databases

If you want to connect to a Postgres database running on a different
machine, here’s one approach that involves SSH port forwarding. For
example, you could connect to a Postgres database running on some server
while working as usual in R or Python on your laptop.

First, on your machine, set up the port forwarding where 63333 should be
an unused port on your local machine and PostgresHostMachine is the
machine on which the database is running.

For Linux/Mac, from the terminal:

``` bash
ssh -L 63333:localhost:5432 yourUserName@PostgresHostMachine
```

Using Putty on Windows, go to ‘Connection -&gt; SSH -&gt; Tunnels’ and
put ‘63333’ as the ‘Source port’ and ‘127.0.0.1:5432’ as the
‘Destination’. Click ‘Add’ and then connect to the machine via Putty.

In either case, the result is that port 63333 on your local machine is
being forwarded to port 5432 (the standard port used by Postgres) on the
server. The use of ‘localhost’ is a bit confusing - it means that you
are forwarding port 63333 to port 5432 on ‘localhost’ on the server.

Then (on your local machine) you can connect by specifying the port on
your local machine, with the example here being from R:

``` r
db <- dbConnect(drv, dbname = 'wikistats', user = 'yourUserName', 
   password = 'yourPassword', host = 'localhost', port = 63333)
```

## 5 UNIX tools for examining disk access (I/O) and memory use

### 5.1 I/O

`iotop` shows disk input/output in real time on a per-process basis,
while iostat shows overall disk use.

``` bash
iotop    # shows usage in real time
iostat 1 # shows usage every second
```

### 5.2 Memory

To see how much memory is available, one needs to have a clear
understanding of disk caching. As discussed above, the operating system
will generally cache files/data in memory when it reads from disk. Then
if that information is still in memory the next time it is needed, it
will be much faster to access it the second time around. While the
cached information is using memory, that same physical memory is
immediately available to other processes, so the memory is available
even though it is in use.

We can see this via `free -h` (the -h is for ‘human-readable’, i.e. show
in GB (G)).

                  total        used        free      shared  buff/cache   available
    Mem:           251G        998M        221G        2.6G         29G        247G
    Swap:          7.6G        210M        7.4G

You’ll generally be interested in the `Memory` row. (See below for some
comments on `Swap`.) The `shared` column is complicated and probably
won’t be of use to you. The `buff/cache` column shows how much space is
used for disk caching and related purposes but is actually available.
Hence the `available` column is the sum of the `free` and `buff/cache`
columns (more or less). In this case only about 1 GB is in use
(indicated in the `used` column).

`top` and `vmstat` both show overall memory use, but remember that the
amount available is the amount free plus any buffer/cache usage. Here is
some example output from vmstat:

    procs -----------memory---------- ---swap-- -----io---- -system-- ------cpu-----
     r  b   swpd   free   buff  cache   si   so    bi    bo   in   cs us sy id wa st
     1  0 215140 231655120 677944 30660296    0    0     1     2    0    0 18  0 82  0  0

It shows 232 GB free and 31 GB used for cache and therefore available,
for a total of 263 GB available.

Here are some example lines from top:

    KiB Mem : 26413715+total, 23180236+free,   999704 used, 31335072 buff/cache
    KiB Swap:  7999484 total,  7784336 free,   215148 used. 25953483+avail Mem 

We see that this machine has 264 GB RAM (the total column in the Mem
row), with 259.5 GB available (232 GB free plus 31 GB buff/cache as seen
in the Mem row). (I realize the numbers don’t quite add up for reasons I
don’t fully understand, but we probably don’t need to worry about that
degree of exactness.) Only 1 GB is in use.

`swap` is essentially the reverse of disk caching. It is disk space that
is used for memory when the machine runs out of physical memory. You
never want your machine to be using swap for memory, because your jobs
will slow to a crawl. Here the swap line in both free and top shows 8 GB
swap space, with very little in use, as desired.
