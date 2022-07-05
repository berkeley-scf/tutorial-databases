---
layout: default
title: Working with big data in R and Python
---

# Working with big data in R and Python

This section aims to provide an overview of working with large datasets
in R and (to a lesser extent) Python. Given the scope of topics, this is
not meant to be a detailed treatment of each topic.

We’ll start with a refresher on data frames in R and Python and some
discussion of the *dplyr* package, whose standard operations are similar
to using SQL syntax. Note that what is referred to as
split-apply-combine functionality in dplyr in R and in pandas in Python
is the same concept as the use of SQL’s GROUP BY combined with
aggregation operations such as MIN, MAX, AVG, COUNT.

The CSV files for the 2016 Stack Overflow data and the space-delimited
files for the Wikipedia traffic data used in the examples below can be
obtained
[here](http://www.stat.berkeley.edu/share/paciorek/tutorial-databases-data.zip).

## 1 Data frames in R and Python

### 1.1 Data frames in R

A data frame in R is essentially the same as a table in SQL. The notion
of a data frame has been essential to the success of R, and its existence
inspired Python’s Pandas package.

R’s data frames are stored in memory, but there are now packages (such
as dplyr with an SQL backend, `arrow`, `SparkR` and `h2o`) that allow
you to treat an external data source as if it were an actual R data
frame, using familiar syntax to operate on the data frame.

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

### 1.2 Using SQL syntax with R data frames: `sqldf`

The *sqldf* package provides the ability to use SQL queries on R data
frames (via `sqldf`) and on-the-fly when reading from CSV files (via
`read.csv.sql`). The latter can help you avoid reading in the entire
dataset into memory in R if you just need a subset of it.

The basic sequence of operations that happens is that the data frame (if
using `sqldf`) or the file (if using `read.csv.sql`) is read temporarily
into a database and then the requested query is performed on the
database, returning the result as a regular R data frame. So you might
find things to be a bit slow because of the time involved in creating
the database.

The following illustrates usage but the `read.csv.sql` part of the code
won’t work in practice on this particular example input file, because
sqldf regards quotes as part of the text and not as delineating fields.
The CSVs for the Stack Overflow data all have quotes distinguishing
fields because there are commas within some fields.

``` r
library(sqldf)
## sqldf
users <- read.csv(file.path('data','users-2016.csv'))
oldUsers <- sqldf("select * from users where age > 75")

## read.csv.sql with data read into an in-memory database
oldUsers <- read.csv.sql(file.path('data', 'users-2016.csv'),  
      sql = "select * from file where age > 75",
      dbname = NULL, header = TRUE)
## read.csv.sql with data read into temporary database on disk
oldUsers <- read.csv.sql(file.path('data', 'users-2016.csv'),  
      sql = "select * from file where age > 75",
      dbname = tempfile(), header = TRUE)
```

### 1.3 Data frames in Python

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
# group by (i.e., aggregation)
users.groupby('age')['upvotes'].agg({'med': 'median', 'avg': 'mean'}) 
joined = pd.merge(users, questions, how= 'inner', left_on= 'userid',
        right_on = 'ownerid')
```

### 1.4 Distributed data frames in Dask in Python

The Dask package provides the ability to divide data frames across
multiple workers (and across nodes), allowing one to handle very large
datasets, as discussed in [this
tutorial](https://berkeley-scf.github.io/tutorial-dask-future/python-dask#4-dask-distributed-datastructures-and-automatic-parallel-operations-on-them).

## 2 dplyr in R

### 2.1 Overview

dplyr is part of the [tidyverse](http://tidyverse.org/), a set of R
packages spearheaded by Hadley Wickham. You can think of dplyr as
providing the functionality of SQL (selecting columns, filtering rows,
transforming columns, aggregation, and joins) on R data frames using a
clean syntax that is easier to use than base R operations.

There’s lots to dplyr, but here we’ll just illustrate the basic
operations by analogy with SQL.

Here we’ll read the data in and do some basic subsetting. In reading the
data in we’ll use another part of the tidyverse: the `readr` package,
which provides `read_csv` as a faster version of `read.csv`.

``` r
library(dplyr)
users <- readr::read_csv(file.path('data', 'users-2016.csv'))
result <- select(users, userid, displayname)  # select columns
dim(result)
```

    ## [1] 1104795       2

``` r
result <- filter(users, age > 75)             # filter by row (i.e., SQL WHERE)
dim(result)
```

    ## [1] 481  10

### 2.2 Piping

dplyr is often combined with piping, which allows you to build up a
sequence of operations (from left to right), as if you were using UNIX
pipes or reading a series of instructions. Here’s a very simple example
where we combine column selection and filtering in a readable way:

``` r
result <- users %>% select(displayname, userid, age) %>% filter(age > 75)
## Or using the new pipe operator from base R:
result <- users |> select(displayname, userid, age) |> filter(age > 75)
```

What happens here is that the operations are run from left to right
(except for the assignment into `result`) and the result of the
left-hand side of a `%>%` is passed into the right-hand side function as
the first argument. So this one liner is equivalent to:

``` r
tmp <- select(users, displayname, userid, age)
result2 <- filter(tmp, age > 75)
identical(result, result2)
```

    ## [1] TRUE

and also equivalent to:

``` r
result3 <- filter(select(users, displayname, userid, age), age > 75)
identical(result, result3)
```

    ## [1] TRUE

We’ll use pipes in the remainder of the dplyr examples.

### 2.3 Functionality

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
questionsOfAge <- users %>% filter(age > 75) %>%
               inner_join(questions, by = c("userid" = "ownerid"))
head(questionsOfAge)
```

    ## # A tibble: 6 × 15
    ##   userid creationdate.x      lastaccessdate      location    
    ##    <dbl> <dttm>              <dttm>              <chr>       
    ## 1   4668 2008-09-05 04:08:05 2017-03-13 21:19:14 Portland, OR
    ## 2   4668 2008-09-05 04:08:05 2017-03-13 21:19:14 Portland, OR
    ## 3   4668 2008-09-05 04:08:05 2017-03-13 21:19:14 Portland, OR
    ## 4   4668 2008-09-05 04:08:05 2017-03-13 21:19:14 Portland, OR
    ## 5   4668 2008-09-05 04:08:05 2017-03-13 21:19:14 Portland, OR
    ## 6   4668 2008-09-05 04:08:05 2017-03-13 21:19:14 Portland, OR
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

### 2.4 Cautionary notes

Note that dplyr and other packages in the tidyverse use a modified form
of data frames. In some cases you may want to convert back to a standard
data frame using `as.data.frame`. For example:

``` r
as.data.frame(head(questionsOfAge, 3))
```

    ##   userid      creationdate.x      lastaccessdate     location
    ## 1   4668 2008-09-05 04:08:05 2017-03-13 21:19:14 Portland, OR
    ## 2   4668 2008-09-05 04:08:05 2017-03-13 21:19:14 Portland, OR
    ## 3   4668 2008-09-05 04:08:05 2017-03-13 21:19:14 Portland, OR
    ##   reputation displayname upvotes downvotes age accountid
    ## 1     116900  Alan Storm    2143       278  97      3253
    ## 2     116900  Alan Storm    2143       278  97      3253
    ## 3     116900  Alan Storm    2143       278  97      3253
    ##   questionid      creationdate.y score viewcount
    ## 1   34552563 2016-01-01 00:02:22     2       484
    ## 2   34597749 2016-01-04 18:46:36     5       250
    ## 3   34689333 2016-01-09 03:15:07     2       119
    ##                                                           title
    ## 1                           PHP: Phing, Phar, and phar.readonly
    ## 2 Determine if PHP files is Running as Part of a `phar` archive
    ## 3     List of PHP Keywords that are Invalid as Class Name Parts

Note that dplyr and other tidyverse packages use a lot of “non-standard
evaluation”. In this context of non-standard evaluation, the thing to
pay attention to is that the column names are not quoted. This means
that one cannot use a variable to stand in for a column. So the
following woudn’t work because dplyr would literally look for a variable
named “colname” in the data frame. There is a [system for addressing
this](https://dplyr.tidyverse.org/articles/programming.html) but I won’t
go into it further here.

``` r
## this won't work because of non-standard evaluation! 
myfun <- function(df, colname) 
  select(df, colname)
myfun(questions, 'age')
```

### 2.5 dplyr with SQL and databases

We can connect to an SQLite or Postgres database and then query it using
dplyr syntax:

``` r
library(RSQLite)
drv <- dbDriver("SQLite")
db <- dbConnect(drv, dbname = file.path('data', 'stackoverflow-2016.db'))
users <- tbl(db, 'users')
oldFolks <- users %>% filter(age > 75)
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

> **Note**: dplyr uses lazy evaluation when interfacing with databases –
> it only does the query and return results when the results are needed
> (in this case when we call `head`).

## 3 Manipulating datasets quickly in memory

### 3.1 `data.table` in R

The *data.table* package provides a lot of functionality for fast
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
 col.names = colNames, colClasses = colClasses, header = FALSE,
 quote = ""))
## 30 sec. for 300 MB zipped
```

Now let’s do some basic subsetting. We’ll see that setting a key
(equivalent to setting an index in SQL) can improve lookup speed
dramatically.

``` r
## without a key (i.e., index)
system.time(sub <- subset(wikiDT, count == 512)) # .27 sec.
system.time(setkey(wikiDT, count , size)) # 3 sec.

## with a key (i.e., index)
system.time(sub2 <- wikiDT[.(512), ]) # essentially instantaneous
```

data.table has a lot of functionality and can be used to do a variety of
sophisticated queries and manipulations (including aggregation
operations), but it has its own somewhat involved syntax and concepts.
The above just scratches the surface of what you can do with it.

### 3.2 Using dplyr syntax with data.table in R

Rather than learning the data.table syntax, one can also use dplyr
syntax with data.table objects.

We can use dplyr syntax directly with data table objects, illustrated
here with our existing `wikiDT` data table.

``` r
system.time(sub <- wikiDT %>% filter(count == 512)) 
```

One can also use `dtplyr` to set use a data table as a back end for
dplyr manipulations. Using `lazy_dt` allows dtplyr to do some
optimization as it generates the translation from dplyr syntax to data
table syntax, though this simple example doesn’t illustrate the
usefulness of that.

``` r
wikiDT2 <- lazy_dt(wikiDT)
system.time(sub <- wikiDT2 %>% filter(count == 512)) # 0.1 sec.
```

Finally the `tidytable` package also allows you to use dplyr syntax as
well as other tidyverse syntax, such as `tidyr` functions.

### 3.3 Arrow

Apache Arrow provides efficient data structures for working with data in
memory, usable in R via the `arrow` package and the `PyArrow` package in
Python. Data are stored by column, with values in a column stored
sequentially and in such a way that one can access a specific value
without reading the other values in the column (O(1) lookup).

Arrow is designed to read data from various file formats, including
Parquet, native Arrow format, and text files. In general Arrow will only
read data from disk as needed, avoiding keeping the entire dataset in
memory. We’ll discuss this concept more in the next section.

One can use [dplyr syntax to work with data in the Arrow data
structures](https://cran.r-project.org/web/packages/arrow/vignettes/dataset.html).

### 3.4 Polars dataframes in Python

I haven’t investigated it, but
[Polars](https://pola-rs.github.io/polars-book/user-guide/index.html) is
advertized as a very fast in-memory package for working with dataframes
that provides a Python interface. It uses the Arrow columnar format. It
also provides a lazy execution model like Spark or Dask that allows for
automatic optimization of queries.

## 4 Working with large datasets on disk

There are a variety of packages in R that allow you to work with very
large datasets on disk without loading them fully into memory. Some of
these are also very good at compressing files to reduce disk storage.

I recommend first considering Arrow or fst as they work well with the
usual data frame manipulations, but the other packages mentioned here
may also be useful.

And note that one can use `sqldf::read.csv.sql` to avoid reading all the
data in from disk.

To illustrate use of these packages, we’ll first create a data frame of
some of the Wikipedia traffic data, 2.3 GB of data:

``` r
## read in Wikistats data
wikiDF <- readr::read_table(file = pipe("gzip -cd data/part-0000?.gz"),
        col_names = c('day','hour','language','site','hits','size'),
        col_types = c('nnccnn'))
```

### 4.1 Arrow

The *arrow* package allows you to read and write from datasets stored as
one or (often) more files in various formats, including:

-   parquet: a space-efficient, standard format;
-   arrow format: data are stored in the same format on disk as in
    memory, improving I/O speed; and
-   text/csv files.

After loading the data in (which doesn’t initially involve actually
reading the data from disk), you can then operate on the resulting
object using dplyr syntax. Arrow will only read the data it needs for
your computations (how much has to be read depends on the file format,
with the native arrow format best in this regard), which can reduce I/O
and memory usage.

> **Note**: If you’re going to be reading the data frequently off disk,
> storing the files in text/CSV is not a good idea as it will be much
> faster to read from the Parquet or Arrow formats.

There’s a [nice
vignette](https://cran.r-project.org/web/packages/arrow/vignettes/dataset.html)
covering basic usage, as well as [this
discussion](https://stackoverflow.com/questions/56472727/difference-between-apache-parquet-and-arrow)
of file formats.

The *PyArrow* package is available for Python, but I haven’t explored
it.

### 4.2 fst

The *fst* package for R provides the ability to quickly read and write
data frames in parallel from data stored on disk in the efficient fst
format. A key feature in terms of reducing memory use is that data can
be quickly accessed by column or by row (O(1) lookup), allowing one to
easily subset the data when reading, rather than reading the entire
dataset into memory, which is what would otherwise happen.

Here’s an example, starting with an original data frame in R (which
might defeat the purpose if the dataset size is too big to fit in
memory).

``` r
system.time(write_fst(wikiDF, file.path('/tmp', 'data.fst')))  ## 8.9 seconds
```

The size of the compressed file is 790 MB based on the default
compression, but one can choose different compression levels.

``` r
system.time(wikiDF <- read_fst(file.path('/tmp','data.fst')))  ## 8.4 seconds
```

The 8 seconds to read the data compares to 55 seconds to read the data
from the gzipped files via a connection using `readr::read_table` and 29
seconds via `data.table::fread`.

### 4.3 Additional packages in R (ff, LaF, bigmemory)

#### 4.3.1 ff

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
## read in Wikistats data; this will take a while.
wikiff <- read.table.ffdf(file = pipe("gzip -cd data/part-0000?.gz"),
        colClasses = colClasses, sep = ' ')
```

Now, one can save the ff dataset into permanent storage on disk that can
be much more quickly loaded than the original reading of the data above.

``` r
system.time(ffsave(wikiff, file = 'wikistats'))   ## 80 sec.
rm(wikiff)
```

Here’s how one loads the dataset back in.

``` r
system.time(ffload('wikistats'))  ## 20 sec.
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

#### Miscellanea

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

#### 4.3.2 LaF package

The LaF package is designed to quickly read in data from CSV and FWF
(fixed-width format) input files, efficiently handling cases where you
only want some of the rows or columns. It requires unzipped text files
as input, so one can’t unzip input files on the fly via piping.

``` r
colClasses <- c('numeric','numeric','character', 'character','numeric','numeric')
colNames <- c('date', 'hour', 'site', 'page', 'count', 'size')
## read in Wikistats data
datLaF <- laf_open_csv(file.path('data', 'part-00000.txt'), sep = ' ',
       column_types = colClasses, column_names = colNames)  ## returns immediately
sub <- datLaf[dat$count[] == 635,]
```

If you run this you’ll see that the `laf_open_csv` took no time,
indicating LaF is using lazy evaluation.

#### 4.3.3 bigmemory for matrices

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

### 4.4 Strategies in Python

Python provides a variety of packages and approaches you can use to
avoid reading large datasets fully into memory. Here is a brief overview
of a few approaches:

-   Use the [Dask
    package](https://berkeley-scf.github.io/tutorial-dask-future/python-dask#4-dask-distributed-datastructures-and-automatic-parallel-operations-on-them)
    to break up datasets into chunks. Dask processes the data in chunks,
    so one often doesn’t need a lot of memory, even just on one machine.
-   Use `numpy.load` with the `mmap_mode` argument to access a numpy
    array (stored in a .npy file) on disk via memory mapping, reading
    only the pieces of the array that you need into memory, as discussed
    [here](https://numpy.org/doc/stable/reference/generated/numpy.load.html).

See [here](https://pythonspeed.com/articles/mmap-vs-zarr-hdf5) for more
discussion of accessing data on disk from Python.

### 4.5 Online (batch) processing of data in R and Python

Another approach is to manually process the data in batches, only
reading in chunks of data that can fit in memory before doing some
computation or writing back out to disk and then reading in the next
chunk. When taking this approach, you want to ensure that the code you
are using will be able to skip directly to the point in the file where
it should read the next chunk of data from (randomly accessing memory)
rather than reading all the data up to the point of interest and simply
discarding the initial data.

Not surprisingly there is a ton more functionality than shown below (in
both Python and R) for reading chunks from files as well as skipping
ahead in a file via a file connection or stream.

#### 4.5.1 Online processing in R

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
system.time(dat1 <- read.csv(fn, nrows = 100000, header = TRUE))  # 0.3 sec.
system.time(dat2 <- read.csv(fn, nrows = 100000, skip = 100001, header = FALSE)) # 0.5 sec.
system.time(dat3 <- read.csv(fn, nrows = 1, skip = 100001, header = FALSE)) # 0.15 sec.
system.time(dat4 <- read.csv(fn, nrows = 100000, skip = 1000001, header = FALSE)) # 3.7 sec.
```

If we use a connection, this cost is avoided (although there is still a
cost to skipping ahead compared to reading in chunks, picking up where
the last chunk left off):

``` r
fn <- file.path('data', 'questions-2016.csv')
con <- file(fn, open = 'r')
system.time(dat1c <- read.csv(con, nrows = 100000, header = TRUE)) # 0.3 sec.
system.time(dat2c <- read.csv(con, nrows = 100000, header = FALSE)) # 0.3 sec.
system.time(dat3c <- read.csv(con, nrows = 1, header = FALSE)) # .001 sec.
system.time(dat5c <- read.csv(con, nrows = 1, skip = 100000, header = FALSE)) # .15 sec
```

You can use `gzfile`, `bzfile`, `url`, and `pipe` to open connections to
zipped files, files on the internet, and inputs processed through
UNIX-style piping.

`read_csv` is generally somewhat faster and seems to be able to skip
ahead efficiently even though it is not using a connection (which
surprises me given that with a CSV file you don’t know how big each line
is so one would think one needs to process through each line in some
fashion).

``` r
library(readr)
fn <- file.path('data', 'questions-2016.csv')
system.time(dat1r <- read_csv(fn, n_max = 100000, col_names = TRUE))   # 0.4 sec.
system.time(dat2r <- read_csv(fn, n_max = 100000, skip = 100001, col_names = FALSE)) # 0.13 sec
system.time(dat3r <- read_csv(fn, n_max = 1, skip = 200001, col_names = FALSE)) # 0.07 sec
system.time(dat4r <- read_csv(fn, n_max = 100000, skip = 1000001, col_names = FALSE)) # 0.18 sec
```

Note that `read_csv` can handle zipped inputs, but does not handle a
standard text file connection.

#### 4.5.2 Online processing in Python

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
