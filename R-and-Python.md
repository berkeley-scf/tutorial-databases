---
layout: default
title: Working with large data in R and Python
---

> **Warning**: I haven’t updated the material here in a few years.

# 1 Manipulating datasets in memory in R and Python

This section aims to provide an overview of data handling in R and
Python. Given the scope of topics, this is not meant to be a detailed
treatment of each topic.

Note that what is referred to as split-apply-combine functionality in
dplyr in R and in pandas in Python is the same concept as the use of
SQL’s GROUP BY combined with aggregation operations such as MIN, MAX,
AVG, COUNT.

The CSV files for the 2016 Stack Overflow data used in the examples
below can be obtained
[here](http://www.stat.berkeley.edu/share/paciorek/tutorial-databases-data.zip).

## 1.1 Data frames in R

A data frame in R is essentially the same as a table in SQL. The notion
of a data frame has been essential to the success of R and its existence
inspired Python’s Pandas package.

R’s data frames are stored in memory, but there are now packages (such
as dplyr with an SQL backend, `SparkR` and `h2o`) that allow you to
treat an external data source as if it were an actual R data frame,
using familiar syntax to operate on the data frame.

This tutorial assumes you’re familiar with basic data frame
functionality in R or Python, so I won’t go into more details here.

dplyr, which will be discussed later, allows you to operate on data
frames using functionality that is similar to SQL, in particular
selecting columns, filtering rows, aggregation operations on subsets,
and joining multiple data frames.

But base R syntax can be used for all of these operations too. Here’s
the base R syntax corresponding to SQL’s SELECT, WHERE, GROUP BY, and
JOIN functionality.

``` r
users <- read.csv(file.path('data', 'users-2016.csv'))
questions <- read.csv(file.path('data', 'questions-2016.csv'))
users[ , c('userid', 'upvotes')] # select columns
users[users$upvotes > 10000, ]   # filter by row (i.e., SQL WHERE)
aggregate(upvotes ~ age, data = users, FUN = median) # group by (i.e., aggregation)
joined <- merge(users, questions, by.x = 'userid', by.y = 'ownerid',
    all.x = FALSE, all.y = FALSE)  # inner join
```

## 1.2 Data frames in Python

The Pandas package has nice functionality for doing dataset
manipulations akin to SQL queries including group by/aggregation
operations, using a data structure called a DataFrame inspired by R’s
data frames. Furthermore, Pandas was designed from the start for
computational efficiency, in contrast to standard data frames in R (but
see below for newer R functionality that is much more efficient).

Here are some examples:

``` python
import pandas as pd
import os
users = pd.read_csv(os.path.join('data', 'users-2016.csv'))
questions = pd.read_csv(os.path.join('data', 'questions-2016.csv'))
type(users)
users[['userid', 'upvotes']]   # select columns         
users[users.upvotes > 10000]   # filter by row (i.e., sql WHERE)
users.groupby('age')['upvotes'].agg({'med': 'median', 'avg': 'mean'}) # group by (i.e., aggregation)
joined = pd.merge(users, questions, how= 'inner', left_on= 'userid',
        right_on = 'ownerid')
```

## 1.3 `data.table` in R

The `data.table` package provides a lot of functionality for fast
manipulation of datasets in memory. data.table can do the standard SQL
operations such as indexing, merges/joins, assignment, grouping, etc.
Plus data.table objects are data frames (i.e., they inherit from data
frames) so they are compatible with R code that uses data frames.

If you’ve got enough memory, data.table can be effective with pretty
large datasets (e.g., 10s of gigabytes).

To illustrate without the example taking too long, we’ll only read in a
subset of the Wikipedia webtraffic data.

Let’s read in the dataset, specifying the column classes so that fread()
doesn’t have to detect what they are (which will take additional time
and might cause errors). Note that we can read directly from a UNIX
operation piped into R.

``` r
library(data.table)
colClasses <- c('numeric', 'numeric', 'character', 
           'character', 'numeric', 'numeric')
colNames <- c('date', 'hour', 'site', 'page', 'count', 'size')
system.time(wikiDT <- fread('gzip -cd data/part-0000?.gz', 
 col.names = colNames, colClasses = colClasses, header = FALSE))
## 30 sec. for 300 MB zipped
```

Now let’s do some basic subsetting. We’ll see that setting a key
(equivalent to setting an index in SQL) can improve lookup speed
dramatically.

``` r
## without a key (i.e., index)
system.time(sub <- subset(wikiDT, count == 635)) # .37 sec.
system.time(setkey(wikiDT, count , size)) # 4 sec.

## with a key (i.e., index)
system.time(sub2 <- wikiDT[.(635), ]) # essentially instantaneous
```

data.table has a lot of functionality and can be used to do a variety of
sophisticated queries and manipulations (including aggregation
operations), but it has its own somewhat involved syntax and concepts.
The above just scratches the surface of what you can do with it. A
different option for exploiting data.table is to use dplyr to interface
with data.table tables.

## 1.4 dplyr

### 1.4.1 dplyr overview

#### Introduction

dplyr is part of the [tidyverse](http://tidyverse.org/), a set of R
packages spearheaded by Hadley Wickham. You can think of dplyr as
providing the functionality of SQL (selecting columns, filtering rows,
transforming columns, aggregation, and joins) on R data frames using a
clean syntax that is easier to use than base R operations.

There’s lots to dplyr, but here we’ll just illustrate the basic
operations by analogy with SQL.

Here we’ll read the data in and do some basic subsetting. In reading the
data in we’ll use another part of the tidyverse: the `readr` package,
which provides `read_csv` as a faster version of `read.csv`. Sidenote:
`read_csv` defaults to not using factors – those of you familiar with
this issue will understand why I’m mentioning it, but others can ignore
this comment.

``` r
library(dplyr)
users <- readr::read_csv(file.path('data', 'users-2016.csv'))
result <- select(users, userid, displayname)  # select columns
dim(result)
```

    ## [1] 1104795       2

``` r
result <- filter(users, age < 15)             # filter by row (i.e., SQL WHERE)
dim(result)
```

    ## [1] 126  10

#### Piping

dplyr is often combined with piping from the `magrittr` package, which
allows you to build up a sequence of operations (from left to right), as
if you were using UNIX pipes or reading a series of instructions. Here’s
a very simple example where we combine column selection and filtering in
a readable way:

``` r
result <- users %>% select(displayname, userid, age) %>% filter(age > 15)
```

What happens here is that the operations are run from left to right
(except for the assignment into `result`) and the result of the
left-hand side of a `%>%` is passed into the right-hand side function as
the first argument. So this one liner is equivalent to:

``` r
tmp <- select(users, displayname, userid, age)
result2 <- filter(tmp, age > 15)
identical(result, result2)
```

    ## [1] TRUE

and also equivalent to:

``` r
result3 <- filter(select(users, displayname, userid, age), age > 15)
identical(result, result3)
```

    ## [1] TRUE

We’ll use pipes in the remainder of the dplyr examples.

#### Functionality

Here’s how one can do stratified analysis with aggregation operations.
In the dplyr world, this is known as split-apply-combine but in the SQL
world this is just a GROUP BY with some aggregation operation.

``` r
medianVotes <- users %>% group_by(age) %>% summarize(
                          median_upvotes = median(upvotes),
                          median_downvotes = median(downvotes))
head(medianVotes)
```

    ## # A tibble: 6 × 3
    ##     age median_upvotes median_downvotes
    ##   <dbl>          <dbl>            <dbl>
    ## 1    13           11                  0
    ## 2    14            0.5                0
    ## 3    15            0                  0
    ## 4    16            3                  0
    ## 5    17            3                  0
    ## 6    18            3                  0

You can also create new columns, sort, and do joins, as illustrated
here:

``` r
## create new columns
users2 <- users %>% mutate(year = substring(creationdate, 1, 4),
                           month = substring(creationdate, 6, 7))
## sorting (here in descending (not the default) order by upvotes)
users2 <- users %>% arrange(age, desc(upvotes))
## joins
questions <- readr::read_csv(file.path('data', 'questions-2016.csv'))
questionsOfYouth <- users %>% filter(age < 15) %>%
               inner_join(questions, by = c("userid" = "ownerid"))
head(questionsOfYouth)
```

    ## # A tibble: 6 × 15
    ##    userid creationdate.x      lastaccessdate      location   
    ##     <dbl> <dttm>              <dttm>              <chr>      
    ## 1 3809164 2014-07-06 08:20:52 2017-03-11 17:49:25 Serbia     
    ## 2 3809164 2014-07-06 08:20:52 2017-03-11 17:49:25 Serbia     
    ## 3 3809164 2014-07-06 08:20:52 2017-03-11 17:49:25 Serbia     
    ## 4 3932721 2014-08-12 09:21:21 2016-12-02 12:09:06 Bob's house
    ## 5 3932721 2014-08-12 09:21:21 2016-12-02 12:09:06 Bob's house
    ## 6 3932721 2014-08-12 09:21:21 2016-12-02 12:09:06 Bob's house
    ## # … with 11 more variables: reputation <dbl>, displayname <chr>,
    ## #   upvotes <dbl>, downvotes <dbl>, age <dbl>, accountid <dbl>,
    ## #   questionid <dbl>, creationdate.y <dttm>, score <dbl>,
    ## #   viewcount <dbl>, title <chr>

> **Challenge**: Why did I first filter and then do the join, rather
> than the reverse?

The join functions include `inner_join`, `left_join`, `right_join`,
`full_join`. I don’t see any cross join functionality.

In addition to operating directly on data frames, dplyr can also operate
on databases and data.table objects as the back-end storage, as we’ll
see next.

#### Miscellanea

Note that dplyr and other packages in the tidyverse use a modified form
of data frames. In some cases you may want to convert back to a standard
data frame using `as.data.frame`. For example:

``` r
as.data.frame(head(questionsOfYouth, 3))
```

    ##    userid      creationdate.x      lastaccessdate location
    ## 1 3809164 2014-07-06 08:20:52 2017-03-11 17:49:25   Serbia
    ## 2 3809164 2014-07-06 08:20:52 2017-03-11 17:49:25   Serbia
    ## 3 3809164 2014-07-06 08:20:52 2017-03-11 17:49:25   Serbia
    ##   reputation displayname upvotes downvotes age accountid
    ## 1        129  ArsenArsen      33         2  14   4707583
    ## 2        129  ArsenArsen      33         2  14   4707583
    ## 3        129  ArsenArsen      33         2  14   4707583
    ##   questionid      creationdate.y score viewcount
    ## 1   38096075 2016-06-29 09:50:36     0        23
    ## 2   38899284 2016-08-11 14:32:39     0        33
    ## 3   40051364 2016-10-14 20:18:18     1        37
    ##                                                                                      title
    ## 1 Iterate over an enum, which saves classes, then init the classes and put them into a map
    ## 2                                             Spark Framework puts HTML around my response
    ## 3                                       OpenShift Maven does not use the correct JAVA_HOME

Note that dplyr and other tidyverse packages use a lot of “non-standard
evaluation”. In this context of non-standard evaluation, the thing to
pay attention to is that the column names are not quoted. This means
that one cannot use a variable to stand in for a column. So the
following woudn’t work because dplyr would literally look for a variable
named “colname” in the data frame. As of recent versions of dplyr, there
is a system called tidyeval for addressing this but I won’t go into it
further here.

``` r
## this won't work because of non-standard evaluation! 
myfun <- function(df, colname) 
  select(df, colname)
myfun(questions, 'age')
```

## 1.4.2 dplyr with SQL and databases

To connect to an SQLite or Postgres database we can use `src_sqlite` and
`src_postgres`:

``` r
stackoverflow <- src_sqlite(file.path('data', 'stackoverflow-2016.db'))
```

    ## Warning: `src_sqlite()` was deprecated in dplyr 1.0.0.
    ## Please use `tbl()` directly with a database connection
    ## This warning is displayed once every 8 hours.
    ## Call `lifecycle::last_lifecycle_warnings()` to see where this warning was generated.

``` r
users <- tbl(stackoverflow, 'users')
oldFolks <- users %>% filter(age > 75)
collect(oldFolks)
```

    ## # A tibble: 481 × 10
    ##     userid creationdate        lastaccessdate location reputation
    ##      <int> <chr>               <chr>          <chr>         <int>
    ##  1  210754 2009-11-13 21:31:17 2017-03-11 23… Washing…       3519
    ##  2 1461979 2012-06-17 15:14:02 2016-05-07 03… <NA>             21
    ##  3 1523314 2012-07-13 10:38:30 2016-05-27 14… Deil, N…         34
    ##  4 2063329 2013-02-12 02:41:28 2017-03-13 20… Honolul…        136
    ##  5 3770909 2014-06-24 11:08:34 2017-02-23 09… Amsterd…          6
    ##  6 6007961 2016-03-02 13:16:52 2016-03-30 11… Netherl…          1
    ##  7   11339 2008-09-16 07:15:48 2017-03-13 18… Greece        11936
    ##  8  130964 2009-06-30 09:53:17 2017-03-13 16… Cambrid…      18420
    ##  9 1616742 2012-08-22 11:07:31 2017-02-27 15… Deil, N…        113
    ## 10 1762193 2012-10-20 21:16:31 2017-03-05 15… United …       1977
    ## # … with 471 more rows, and 5 more variables: displayname <chr>,
    ## #   upvotes <int>, downvotes <int>, age <int>, accountid <int>

``` r
head(oldFolks)
```

    ## # Source:   lazy query [?? x 10]
    ## # Database: sqlite 3.36.0
    ## #   [/accounts/gen/vis/paciorek/teaching/243fall21/stat243-fall-2021/data/stackoverflow-2016.db]
    ##    userid creationdate        lastaccessdate  location reputation
    ##     <int> <chr>               <chr>           <chr>         <int>
    ## 1  210754 2009-11-13 21:31:17 2017-03-11 23:… Washing…       3519
    ## 2 1461979 2012-06-17 15:14:02 2016-05-07 03:… <NA>             21
    ## 3 1523314 2012-07-13 10:38:30 2016-05-27 14:… Deil, N…         34
    ## 4 2063329 2013-02-12 02:41:28 2017-03-13 20:… Honolul…        136
    ## 5 3770909 2014-06-24 11:08:34 2017-02-23 09:… Amsterd…          6
    ## 6 6007961 2016-03-02 13:16:52 2016-03-30 11:… Netherl…          1
    ## # … with 5 more variables: displayname <chr>, upvotes <int>,
    ## #   downvotes <int>, age <int>, accountid <int>

The `collect` statement after the filtering is needed because dplyr uses
lazy evaluation when interfacing with databases – it only does the query
and return results when the results are needed.

### 1.4 dplyr with data.table

Similarly you can use dplyr with data tables (i.e., from data.table).
We’ll take our existing `wikiDT` data table that we read in using
`fread` and manipulate it using dplyr syntax.

``` r
system.time(sub <- wikiDT %>% filter(count==635)) # 0.1 sec.
```

## 1.5 Using SQL with R data frames: `sqldf`

Finally the sqldf package provides the ability to use SQL queries on R
data frames (via `sqldf`) and on-the-fly when reading from CSV files
(via `read.csv.sql`). The latter can help you avoid reading in the
entire dataset into memory in R if you just need a subset of it.

The basic sequence of operations that happens is that the data frame (if
using `sqldf`) or the file (if using `read.csv.sql`) is read temporarily
into a database and then the requested query is performed on the
database, returning the result as a regular R data frame.

The following illustrates usage but the `read.csv.sql` part of the code
won’t work in practice on this particular example input file, because
sqldf regards quotes as part of the text and not as delineating fields.
The CSVs for the Stack Overflow data all have quotes distinguishing
fields because there are commas within some fields.

``` r
library(sqldf)
## sqldf
users <- read.csv(file.path('data','users-2016.csv'))
youngUsers <- sqldf("select * from users where age < 15")

## read.csv.sql with data read into an in-memory database
youngUsers <- read.csv.sql(file.path('data', 'users-2016.csv'),  
      sql = "select * from file where age < 15",
      dbname = NULL, header = TRUE)
## read.csv.sql with data read into temporary database on disk
youngUsers <- read.csv.sql(file.path('data', 'users-2016.csv'),  
      sql = "select * from file where age < 15",
      dbname = tempfile(), header = TRUE)
```

## 1.6 Speed comparisons

There is some benchmarking of some of the R and Python tools discussed
in this section
[here](https://github.com/Rdatatable/data.table/wiki/Benchmarks-%3A-Grouping).

# 2 Manipulating datasets not in memory in R

## 2.1 ff package

ff stores datasets in columnar format, with one file per column, on
disk, so is not limited by memory (with the caveat below). It then
provides fast access to the dataset from R.

To create the disk-based ff dataset, you’ll need to first read in the
data from its original home. Note the arguments are similar to those for
`read.table` and `read.csv`. `read.table.ffdf` reads the data in chunks.

``` r
library(ff)
colClasses <- c('numeric','numeric','character', 'character','numeric','numeric')
colClasses[colClasses == 'character'] <- 'factor'  # 'character' not allowed in ff
## read in Wikistats data
wikiff <- read.table.ffdf(file = pipe("gzip -cd data/0000?gz"),
        colClasses = colClasses, sep = ' ')
```

Now, one can save the ff dataset into permanent storage on disk that can
be much more quickly loaded than the original reading of the data above.

``` r
ffsave(wikiff, file = 'wikistats')
rm(wikiff)
```

Here’s how one loads the dataset back in.

``` r
ffload('wikistats')
```

In the above operations, we wrote a copy of the file in the ff binary
format that can be read more quickly back into R than the original
reading of the CSV using `ffsave` and `ffload`. Also note the reduced
size of the binary format file compared to the original CSV. It’s good
to be aware of where the binary ff file is stored given that for large
datasets, it will be large. With ff (I think bigmemory is different in
how it handles this) it appears to be stored in `/tmp` in an R temporary
directory. Note that as we work with large files we need to be more
aware of the filesystem, making sure in this case that /tmp has enough
space.

To use ff effectively, you want to use functions designed to manipulate
ff objects; otherwise R will convert the ff dataset into a standard data
frame and defeat the purpose as this will put the entire dataset in
memory. You can look at the ff and ffbase packages to see what functions
are available using `library(help = ff)` and `library(help = ffbase)`.
Notice that there is an `merge.ff` function for joins. Here we use the
ff-specific table function:

``` r
table.ff(wikiff$hour)
```

### Miscellanea

Note that a copy of an ff object appears to be a shallow copy: if you
modify the copy it will change the data in the original object.

Note that `ff` stores factor levels *in memory*, so if one has many
factor levels, that can be a limitation. Furthermore, character columns
are not allowed, so one is forced to use factors. Thus with textual data
or the like, one can easily run into this limitation. With the Wikistats
data, this is a big problem.

Also, I’ve encountered problems when there are more than about 1000
columns because each column is a separate file and there can be
limitations in R on how many files it has open at once.

## 2.2 LaF package

The LaF package is designed to quickly read in data from CSV and FWF
(fixed-width format) input files, efficiently handling cases where you
only want some of the rows or columns. It requires unzipped text files
as input, so one can’t unzip input files on the fly via piping.

    colClasses <- c('numeric','numeric','character', 'character','numeric','numeric')
    colNames <- c('date', 'hour', 'site', 'page', 'count', 'size')
    ## read in Wikistats data
    datLaF <- laf_open_csv(file.path('data', 'part-0000.txt'), sep = ' ',
           column_types = colClasses, column_names = colNames)  ## returns immediately
    sub <- datLaf[dat$count[] == 635,]

If you run this you’ll see that the `laf_open_csv` took no time,
indicating LaF is using lazy evaluation.

## 2.3 bigmemory for matrices

`bigmemory` is similar to ff in providing the ability to load datasets
into R without having them in memory, but rather stored in clever ways
on disk that allow for fast access. bigmemory provides a `big.matrix`
class, so it appears to be limited to datasets with a single type for
all the variables. However, one nice feature is that one can use
`big.matrix` objects with foreach (one of R’s parallelization tools)
without passing a copy of the matrix to each worker. Rather the workers
can access the matrix stored on disk.

The `biglm` package provides the ability to fit linear models and GLMs
to big datasets, with integration with ff and bigmemory.

## 2.4 pbdR for manipulating matrices across multiple machines (distributed computing)

[pbdR](https://rbigdata.github.io/) provides a suite of packages for
doing computations (particularly linear algebra) where the data and the
computations are both distributed across multiple machines. More details
are available in my [distributed computing
tutorial](http://statistics.berkeley.edu/computing/training/tutorials)

# 3 Online (batch) processing of data in R and Python

When data are too big to fit in memory, one may want to preprocess data
in batches, only reading in chunks of data that can fit in memory before
doing some computation or writing back out to disk and then reading in
the next chunk. When taking this approach, you want to ensure that the
code you are using will be able to skip directly to the point in the
file where it should read the next chunk of data from (randomly
accessing memory) rather than reading all the data up to the point of
interest and simply discarding the initial data.

Not surprisingly there is a ton more functionality than shown below (in
both Python and R) for reading chunks from files as well as skipping
ahead in a file via a file connection or stream.

## 3.1 Online processing in R

In R, various input functions can read in a subset of a file or can skip
ahead. In general the critical step is to use a *connection* rather than
directly opening the file, as this will allow one to efficiently read
the data in in chunks.

I’ve put these in separate chunks as a reminder that for more accurate
time comparisons they should be run in separate R sessions as there are
some caching effects (though it’s surprising that closing R has an
effect as I would think the file would be cached by the OS regardless).

First we’ll see that skipping ahead when not using a connection is
costly – R needs to read all the earlier rows before getting to the data
of interest:

``` r
fn <- file.path('data', 'questions-2016.csv')
system.time(dat1 <- read.csv(fn, nrows = 100000, header = TRUE))  # 2.0 sec.
system.time(dat2 <- read.csv(fn, nrows = 100000, skip = 100001, header = FALSE)) # 2.5 sec.
system.time(dat3 <- read.csv(fn, nrows = 1, skip = 100001, header = FALSE)) # 0.5 sec.
system.time(dat4 <- read.csv(fn, nrows = 100000, skip = 1000001, header = FALSE)) # 9.3 sec.
```

If we use a connection, this cost is avoided (although there is still a
cost to skipping ahead compared to reading in chunks, picking up where
the last chunk left off):

``` r
fn <- file.path('data', 'questions-2016.csv')
con <- file(fn, open = 'r')
system.time(dat1c <- read.csv(con, nrows = 100000, header = TRUE)) # 1.4 sec.
system.time(dat2c <- read.csv(con, nrows = 100000, header = FALSE)) # 1.4 sec.
system.time(dat3c <- read.csv(con, nrows = 1, header = FALSE)) # .001 sec.
system.time(dat5c <- read.csv(con, skip = 100000, nrows = 1, header = FALSE)) # .5 sec
```

You can use `gzfile`, `bzfile`, `url`, and `pipe` to open connections to
zipped files, files on the internet, and inputs processed through
UNIX-style piping.

`read_csv` is much faster and seems to be able to skip ahead efficiently
even though it is not using a connection (which surprises me given that
with a CSV file you don’t know how big each line is so one would think
one needs to process through each line in some fashion).

``` r
library(readr)
fn <- file.path('data', 'questions-2016.csv')
system.time(dat1r <- read_csv(fn, n_max = 100000, col_names = TRUE))   # 0.2 sec.
system.time(dat2r <- read_csv(fn, n_max = 100000, skip = 100001, col_names = FALSE)) # 0.3 sec
system.time(dat3r <- read_csv(fn, n_max = 1, skip = 200001, col_names = FALSE)) # 0.1 sec
system.time(dat4r <- read_csv(fn, n_max = 100000, skip = 1000001, col_names = FALSE)) # 0.6 sec
```

Note that `read_csv` can handle zipped inputs, but does not handle a
standard text file connection.

## 3.2 Online processing in Python

Pandas’ `read_csv` has similar functionality in terms of reading a fixed
number of rows and skipping rows, and it can decompress zipped files on
the fly.

``` python
import pandas as pd
import timeit
fn = os.path.join('data', 'users-2016.csv')

## here's the approach I'd recommend, as it's what 'chunksize' is intended for
start_time = timeit.default_timer()
chunks = pd.read_csv(fn, chunksize = 100000, header = 0) # 0.003 sec.
elapsed = timeit.default_timer() - start_time
elapsed
type(chunks)

## read first chunk
start_time = timeit.default_timer()
dat1c = chunks.get_chunk()  
elapsed = timeit.default_timer() - start_time
elapsed  # 0.2 sec.

## read next chunk
start_time = timeit.default_timer()
dat2c = chunks.get_chunk()  # 0.25 sec.
elapsed = timeit.default_timer() - start_time
elapsed  # 0.2 sec.

## this also works but is less elegant
start_time = timeit.default_timer()
dat1 = pd.read_csv(fn, header = 0, nrows = 100000)  
elapsed = timeit.default_timer() - start_time
elapsed  # 0.3 sec.

start_time = timeit.default_timer()
dat2 = pd.read_csv(fn, nrows = 100000, header = None, skiprows=100001)  
elapsed = timeit.default_timer() - start_time
elapsed  # 0.3 sec.
```