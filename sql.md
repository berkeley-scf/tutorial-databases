---
layout: default
title: SQL
---

# 1 Introduction to SQL

## 1.1 Getting started

Here is a simple query that selects the first five rows (and all
columns, based on the `*` wildcard) from the questions table.

    select * from questions limit 5

To run this from R:

``` r
library(RSQLite)
drv <- dbDriver("SQLite")
dir <- 'data' # relative or absolute path to where the .db file is
dbFilename <- 'stackoverflow-2016.db'
db <- dbConnect(drv, dbname = file.path(dir, dbFilename))
dbGetQuery(db, "select * from questions limit 5")  # simple query to get 5 rows from a table
```

    ##   questionid        creationdate score viewcount
    ## 1   34552550 2016-01-01 00:00:03     0       108
    ## 2   34552551 2016-01-01 00:00:07     1       151
    ## 3   34552552 2016-01-01 00:00:39     2      1942
    ## 4   34552554 2016-01-01 00:00:50     0       153
    ## 5   34552555 2016-01-01 00:00:51    -1        54
    ##                                                                                   title
    ## 1                                                                 Scope between methods
    ## 2      Rails - Unknown Attribute - Unable to add a new field to a form on create/update
    ## 3 Selenium Firefox webdriver won't load a blank page after changing Firefox preferences
    ## 4                                                       Android Studio styles.xml Error
    ## 5                         Java: reference to non-finial local variables inside a thread
    ##   ownerid
    ## 1 5684416
    ## 2 2457617
    ## 3 5732525
    ## 4 5735112
    ## 5 4646288

Now let’s see some more interesting usage of other SQL syntax.

    ## get the questions that are viewed the most
    select * from questions where viewcount > 100000
    ## find the largest numbers of question views in the questions table
    select distinct viewcount from questions order by viewcount desc limit 20

Let’s lay out the various verbs in SQL. Here’s the form of a standard
query (though the ORDER BY is often not used and sorting is
computationally expensive):

    SELECT <column(s)> FROM <table> WHERE <condition(s) on column(s)> ORDER BY <column(s)>

SQL keywords are often written in ALL CAPITALS though I won’t
necessarily do that in this tutorial.

And here is a table of some important keywords:

| Keyword                       | What it does                                       |
|-------------------------------|----------------------------------------------------|
| SELECT                        | select columns                                     |
| FROM                          | which table to operate on                          |
| WHERE                         | filter (choose) rows satisfying certain conditions |
| LIKE, IN, &lt;, &gt;, =, etc. | used as part of conditions                         |
| ORDER BY                      | sort based on columns                              |

For comparisons in a WHERE clause, some common syntax for setting
conditions includes LIKE (for patterns), =, &gt;, &lt;, &gt;=, &lt;=,
!=.

Some other keywords are: DISTINCT, ON, JOIN, GROUP BY, AS, USING, UNION,
INTERSECT, HAVING, SIMILAR TO, SUBSTR in SQLite and SUBSTRING in
PostgreSQL.

> **Challenge**: Return a few rows from the users, questions, answers,
> and tags tables so you can get a sense for what the entries in the
> tables are like.

> **Challenge**: Find the youngest users in the database.

## 1.2 Getting unique results (DISTINCT)

A useful SQL keyword is DISTINCT, which allows you to eliminate
duplicate rows from any table (or remove duplicate values when one only
has a single column or set of values).

``` r
tagNames <- dbGetQuery(db, "select distinct tag from questions_tags")
dbGetQuery(db, "select count(distinct tag) from questions_tags")
```

    ##   count(distinct tag)
    ## 1               41006

## 1.3 Grouping / stratifying (GROUP BY)

A common pattern of operation is to stratify the dataset, i.e., collect
it into mutually exclusive and exhaustive subsets. One would then
generally do some aggregation operation on each subset. In SQL this is
done with the GROUP BY keyword.

Here’s a basic example where we count the occurrences of different tags.

``` r
dbGetQuery(db, "select tag, count(*) as n from questions_tags
                group by tag order by n desc limit 100")
```

> **Challenge**: What specifically does that query do? Describe the
> table that would be returned.

In general `GROUP BY` statements will involve some aggregation operation
on the subsets. Options include: COUNT, MIN, MAX, AVG, SUM.

The result of a query that uses `group by` is a table with as many rows
as groups.

> **Warning**: To filter the result of a grouping operation, we need to
> use `having` rather than `where`.

Also note the use of `as` to define a name for the new column.

``` r
dbGetQuery(db, "select tag, count(*) as n from questions_tags
                group by tag having n > 100000 limit 10")
```

> **Challenge**: Write a query that will count the number of answers for
> each question, returning the most answered questions.

## 1.4 Joins

### 1.4.1 Introduction to joins

Suppose in the example of students in classes, we want a result that has
the grades of all students in 9th grade. For this we need information
from the Student table (to determine grade level) and information from
the ClassAssignment table (to determine the class grade). Getting
information from multiple tables, where a row in one table is matched
with one or more rows in another table is called a *join*.

The syntax generally looks like this (again the WHERE and ORDER BY are
optional):

    SELECT <column(s)> FROM <table1> JOIN <table2> ON <columns to match on>
       WHERE <condition(s) on column(s)> ORDER BY <column(s)>

Let’s see some joins using the different syntax on the Stack Overflow
database. In particular let’s select only the questions with the tag
“python”.

``` r
## a join with JOIN
result1 <- dbGetQuery(db, "select * from questions join questions_tags 
           on questions.questionid = questions_tags.questionid where tag = 'python'")

## a join without JOIN
result2 <- dbGetQuery(db, "select * from questions, questions_tags
        where questions.questionid = questions_tags.questionid and tag = 'python'")
head(result2)
```

    ##   questionid        creationdate score viewcount
    ## 1   34553559 2016-01-01 04:34:34     3        96
    ## 2   34556493 2016-01-01 13:22:06     2        30
    ## 3   34557898 2016-01-01 16:36:04     3       143
    ## 4   34560088 2016-01-01 21:10:32     1       126
    ## 5   34560213 2016-01-01 21:25:26     1       127
    ## 6   34560740 2016-01-01 22:37:36     0       455
    ##                                                                                           title
    ## 1                                            Python nested loops only working on the first pass
    ## 2                                        bool operator in for Timestamp in Series does not work
    ## 3                                                       Pairwise haversine distance calculation
    ## 4                                                          Stopwatch (chronometre) doesn't work
    ## 5 How to set the type of a pyqtSignal (variable of class X) that takes a X instance as argument
    ## 6                                                Flask: Peewee model_to_dict helper not working
    ##   ownerid questionid    tag
    ## 1  845642   34553559 python
    ## 2 4458602   34556493 python
    ## 3 2927983   34557898 python
    ## 4 5736692   34560088 python
    ## 5 5636400   34560213 python
    ## 6 3262998   34560740 python

``` r
identical(result1, result2)
```

    ## [1] TRUE

As seen above, you can do the join with using the *join* keyword, but if
you do, you need to use *where*. More on this in a bit.

Here’s a three-way join with some additional use of aliases to
abbreviate table names. What does this query ask for?

``` r
result1 <- dbGetQuery(db, "select * from questions Q
        join questions_tags T on Q.questionid = T.questionid
        join users U on Q.ownerid = U.userid
        where tag = 'python' and age < 18")

result2 <- dbGetQuery(db, "select * from questions Q, questions_tags T, users U
        where Q.questionid = T.questionid 
          and Q.ownerid = U.userid
          and tag = 'python' 
          and age < 18")

identical(result1, result2)
```

    ## [1] TRUE

> **Challenge**: Write a query that would return all the questions with
> the Python tag.

> **Challenge**: Write a query that would return all the answers to
> questions with the Python tag.

> **Challenge**: Write a query that would return the users who have
> answered a question with the Python tag.

### 1.4.2 Types of joins

We’ve seen a bunch of joins but haven’t discussed the full taxonomy of
types of joins. There are various possibilities for how to do a join
depending on whether there are rows in one table that do not match any
rows in another table.

*Inner joins*: In database terminology an inner join is when the result
has a row for each match of a row in one table with the rows in the
second table, where the matching is done on the columns you indicate. If
a row in one table corresponds to more than one row in another table,
you get all of the matching rows in the second table, with the
information from the first table duplicated for each of the resulting
rows. For example in the Stack Overflow data, an inner join of questions
and answers would pair each question with each of the answers to that
question. However, questions without any answers or (if this were
possible) answers without a corresponding question would not be part of
the result.

*Outer joins*: Outer joins add additional rows from one table that do
not match any rows from the other table as follows. A *left outer join*
gives all the rows from the first table but only those from the second
table that match a row in the first table. A *right outer join* is the
converse, while a *full outer join* includes at least one copy of all
rows from both tables. So a left outer join of the Stack Overflow
questions and answers tables would, in addition to the matched questions
and their answers, include a row for each question without any answers,
as would a full outer join. In this case there should be no answers that
do not correspond to question, so a right outer join should be the same
as an inner join.

*Cross joins*: A cross join gives the Cartesian product of the two
tables, namely the pairwise combination of every row from each table,
analogous to `expand.grid` in R. I.e., take a row from the first table
and pair it with each row from the second table, then repeat that for
all rows from the first table. Since cross joins pair each row in one
table with all the rows in another table, the resulting table can be
quite large (the product of the number of rows in the two tables). In
the Stack Overflow database, a cross join would pair each question with
every answer in the database, regardless of whether the answer is an
answer to that question.

Here’s a table of the different kinds of joins:

<table>
<colgroup>
<col style="width: 25%" />
<col style="width: 27%" />
<col style="width: 47%" />
</colgroup>
<thead>
<tr class="header">
<th>Type of join</th>
<th>Rows from first table</th>
<th>Rows from second table</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td>inner (default)</td>
<td>all that match on specified condition</td>
<td>all that match on specified condition</td>
</tr>
<tr class="even">
<td>left outer</td>
<td>all</td>
<td>all that match first</td>
</tr>
<tr class="odd">
<td>right outer</td>
<td>all that match second</td>
<td>all</td>
</tr>
<tr class="even">
<td>full outer</td>
<td>all</td>
<td>all</td>
</tr>
<tr class="odd">
<td>cross</td>
<td>all combined pairwise with second</td>
<td>all combined pairwise with first</td>
</tr>
</tbody>
</table>

A ‘natural’ join is an inner join that doesn’t require you to specify
the common columns between tables on which to enforce equality, but it’s
often good practice to not use a natural join and to explicitly indicate
which columns are being matched on.

Simply listing two or more tables separated by commas as we saw earlier
is the same as a *cross join*. Alternatively, listing two or more tables
separated by commas, followed by conditions that equate rows in one
table to rows in another is the same as an *inner join*.

In general, inner joins can be seen as a form of cross join followed by
a condition that enforces matching between the rows of the table. More
broadly, here are five equivalent joins that all perform the equivalent
of an inner join:

    select * from table1 join table2 on table1.id = table2.id ## explicit inner join
    select * from table1, table2 where table1.id = table2.id  ## without explicit JOIN
    select * from table1 cross join table2 where table1.id = table2.id 
    select * from table1 join table2 using(id)
    select * from table1 natural join table2

Note that in the last query the join would be based on all common
columns, which could be a bit dangerous if you don’t look carefully at
the schema of both tables. Assuming `id` is the common column, then the
last of these queries is the same as the others.

> **Challenge**: Create a view with one row for every question-tag pair,
> including questions without any tags.

> **Challenge**: Write a query that would return the displaynames of all
> of the users who have *never* posted a question. The NULL keyword will
> come in handy – it’s like `NA` in R. Hint: NULLs should be produced if
> you do an outer join.

> **Challenge**: How many questions tagged with ‘random-forest’ were
> unanswered? (You should need two different kinds of joins to answer
> this.)

### 1.4.3 Joining a table with itself (self joins)

Sometimes we want to query information across rows of the same table.
For example supposed we want to analyze the time lags between when the
same person posts a question. Do people tend to post in bursts or do
they tend to post uniformly over the year? To do this we need contrasts
between the times of the different posts. (One can also address this
using window functions, discussed later.)

So we need to join two copies of the same table, which means dealing
with resolving the multiple copies of each column.

This would look like this:

``` r
dbGetQuery(db, "create view question_contrasts as
               select * from questions Q1 join questions Q2
               on Q1.ownerid = Q2.ownerid")
```

That should create a new table (actually a view) with all pairs of
questions asked by a single person.

Actually, there’s a problem here.

> **Challenge**: What kinds of rows will we get that we don’t want?

A solution to that problem of having the same question paired with
itself is:

``` r
dbGetQuery(db, "create view question_contrasts as
               select * from questions Q1 join questions Q2
               on Q1.ownerid = Q2.ownerid
               where Q1.creationdate != Q2.creationdate")
```

> **Challenge**: There’s actually a further similar problem. What is the
> problem and how can we fix it by changing two characters in the query
> above? Hint, even as character strings, the creationdate column has an
> ordering.

## 1.5 Temporary tables and views

You can think of a view as a temporary table that is the result of a
query and can be used in subsequent queries. In any given query you can
use both views and tables. The advantage is that they provide modularity
in our querying. For example, if a given operation (portion of a query)
is needed repeatedly, one could abstract that as a view and then make
use of that view.

Suppose we always want the age and displayname of question owners
available. Once we have the view we can query it like a regular table.

``` r
## note there is a creationdate in users too, hence disambiguation
dbExecute(db, "create view questionsAugment as
               select questionid, questions.creationdate, score, viewcount, title, ownerid, age, displayname
               from questions join users on questions.ownerid = users.userid")
## don't be confused by the "0" response --
## it just means that nothing is returned to R; the view _has_ been created
               
dbGetQuery(db, "select * from questionsAugment where age < 15 limit 5")
```

One use of a view would be to create a mega table that stores all the
information from multiple tables in the (unnormalized) form you might
have if you simply had one data frame in R or Python.

``` r
dbExecute(db, "drop view questionsAugment") # drop so can create again when rerun the code above
```

# 2 Additional SQL topics

## 2.1 Creating database tables

One can create tables from within the `sqlite` and `psql` command line
interfaces (discussed later), but often one would do this from R or
Python. Here’s the syntax from R.

``` r
## Option 1: pass directly from CSV to database
dbWriteTable(conn = db, name = "student", value = "student.csv", row.names = FALSE, header = TRUE)

## Option 2: pass from data in an R data frame
## First create your data frame:
# student <- data.frame(...)
## or
# student <- read.csv(...)
dbWriteTable(conn = db, name = "student", value = student, row.names = FALSE, append = FALSE)
```

## 2.2 String processing and creating new fields

We can do some basic matching with LIKE, using % as a wildcard and \_ to
stand in for any single character:

``` r
dbGetQuery(db, "select * from questions_tags where tag like 'r-%' limit 10")
```

    ##    questionid            tag
    ## 1    35095638        r-caret
    ## 2    35243702       r-raster
    ## 3    35729179        r-caret
    ## 4    36342481 r-googlesheets
    ## 5    36374741 r-googlesheets
    ## 6    36520591       r-raster
    ## 7    36774095     r-corrplot
    ## 8    36813566       r-raster
    ## 9    36844460       r-raster
    ## 10   36913170       r-lavaan

In Postgres, in addition to the basic use of LIKE to match character
strings, one can use regular expression syntax with SIMILAR TO and one
can extract substrings with SUBSTRING.

These keywords are not available in SQLite so the following can only be
done in the Postgres instance of our example database. Here we’ll look
for all tags that are of the form “r-”, “-r”, “r” or “-r-”. SQL uses %
as a wildcard (this is not standard regular expression syntax).

``` r
## Try in postgreSQL, not SQLite
result <- dbGetQuery(db, "select * from questions_tags where tag SIMILAR TO 'r-%|%-r|r|%-r-%' limit 10")
## Standard regex for 'any character' doesn't seem to work:
## result <- dbGetQuery(db, "select * from questions_tags where tag SIMILAR TO 'r-.*|.*-r|r|.*-r-.*' limit 10")
```

Note that the matching does not find subsets, unless one uses wildcards
at beginning and end of the pattern, so “r” will only find “r” and not,
for example, “dyplr”.

To extract substrings we use SUBSTRING. Postgres requires that the
pattern to be extracted be surrounded by `#"` (one could use another
character in place of `#`), but for use from R we need to escape the
double-quote with a backslash so it is treated as a part of the string
passed to Postgres and not treated by R as indicating where the
character string stops/starts.

``` r
dbGetQuery(db, "select substring(creationdate from '#\"[[:digit:]]{4}#\"%' for '#') as year
               from questions limit 3")
```

Note that SQLite provides SUBSTR for substrings, but the flexibility of
SUBSTR seems to be much less than use of SUBSTRING in PostgreSQL.

Here is some [documentation on string functions in
PostgreSQL](https://www.postgresql.org/docs/current/functions-string.html).

> **Challenge**: Select the questions that have “java” but not
> “javascript” in their titles using regular expression syntax.

> **Challenge**: Figure out how to calculate the length (in characters)
> of the title of each question.

> **Challenge**:Process the creationdate field to create year, day, and
> month fields in a new view. Note that this would be good practice for
> string manipulation but you would want to handle dates and times using
> the material in the next section and not use string processing.

## 2.3 Dates and times

Here we’ll see how you can work with dates and times in SQLite, but the
functionality should be similar in other DBMS.

SQLite doesn’t have specific date-time types, but it’s standard to store
date-times as strings in the text field in the ISO-8601 format:
YYYY-MM-DD HH:MM:SS.SSS. That’s the format of the dates in the
StackOverflow database:

``` r
dbGetQuery(db, "select distinct creationdate from questions limit 5")
```

    ##          creationdate
    ## 1 2016-01-01 00:00:03
    ## 2 2016-01-01 00:00:07
    ## 3 2016-01-01 00:00:39
    ## 4 2016-01-01 00:00:50
    ## 5 2016-01-01 00:00:51

Then SQLite provides some powerful functions for manipulating and
extracting information in such fields. Here are just a few examples,
noting that `strftime` is particularly powerful. Other DBMS should have
similar functionality, but I haven’t investigated further.

``` r
## Julian days (decimal days since noon UTC/Greenwich time November 24, 4714 BC (Yikes!)). 
output <- dbGetQuery(db, "select creationdate, julianday(creationdate)
                from questions limit 5")
output
```

    ##          creationdate julianday(creationdate)
    ## 1 2016-01-01 00:00:03                 2457389
    ## 2 2016-01-01 00:00:07                 2457389
    ## 3 2016-01-01 00:00:39                 2457389
    ## 4 2016-01-01 00:00:50                 2457389
    ## 5 2016-01-01 00:00:51                 2457389

``` r
## Julian day is decimal-valued:
formatC(output[ , 2], 6, format = 'f')
```

    ## [1] "2457388.500035" "2457388.500081" "2457388.500451"
    ## [4] "2457388.500579" "2457388.500590"

``` r
## Convert to local time
dbGetQuery(db, "select distinct creationdate, datetime(creationdate, 'localtime')
                from questions limit 5")
```

    ##          creationdate datetime(creationdate, 'localtime')
    ## 1 2016-01-01 00:00:03                 2015-12-31 16:00:03
    ## 2 2016-01-01 00:00:07                 2015-12-31 16:00:07
    ## 3 2016-01-01 00:00:39                 2015-12-31 16:00:39
    ## 4 2016-01-01 00:00:50                 2015-12-31 16:00:50
    ## 5 2016-01-01 00:00:51                 2015-12-31 16:00:51

``` r
## Eastern time, manually, ignoring daylight savings
dbGetQuery(db, "select distinct creationdate, datetime(creationdate, '-05:00')
                from questions limit 5")
```

    ##          creationdate datetime(creationdate, '-05:00')
    ## 1 2016-01-01 00:00:03              2015-12-31 19:00:03
    ## 2 2016-01-01 00:00:07              2015-12-31 19:00:07
    ## 3 2016-01-01 00:00:39              2015-12-31 19:00:39
    ## 4 2016-01-01 00:00:50              2015-12-31 19:00:50
    ## 5 2016-01-01 00:00:51              2015-12-31 19:00:51

``` r
## day of week: Jan 1 2016 was a Friday (0=Sunday, 6=Saturday)
dbGetQuery(db, "select creationdate, strftime('%w', creationdate)
                from questions limit 5")
```

    ##          creationdate strftime('%w', creationdate)
    ## 1 2016-01-01 00:00:03                            5
    ## 2 2016-01-01 00:00:07                            5
    ## 3 2016-01-01 00:00:39                            5
    ## 4 2016-01-01 00:00:50                            5
    ## 5 2016-01-01 00:00:51                            5

Unfortunately I’m not sure if the actual dates in the database are
Greenwich time or some US time zone, but we’ll ignore that complication
here.

Let’s put it all together to do something meaningful.

``` r
result <- dbGetQuery(db, "select strftime('%H', creationdate) as hour,
                          count() as n from questions group by hour")
head(result)
```

    ##   hour     n
    ## 1   00 56119
    ## 2   01 53468
    ## 3   02 55190
    ## 4   03 57450
    ## 5   04 61855
    ## 6   05 75520

``` r
plot(as.numeric(result$hour), result$n, xlab = 'hour of day (UTC/Greenwich???)',
                                        ylab = 'number of questions')
```

![](sql_files/figure-markdown_github/unnamed-chunk-16-1.png)

Here’s some [documentation of the syntax for the functions, including
`stftime`](https://www.sqlite.org/lang_datefunc.html).

# 3 More advanced SQL

## 3.1 Set operations: UNION, INTERSECT, EXCEPT

You can do set operations like union, intersection, and set difference
using the UNION, INTERSECT, and EXCEPT keywords on tables that have the
same schema (same column names and types), though most often these would
be used on single columns (i.e., single-column tables).

Note that one can often set up an equivalent query without using
INTERSECT or UNION.

Here’s an example of a query that can be done with or without an
intersection. Suppose we want to know the names of all individuals who
have asked both an R question and a Python question. We can do this with
INTERSECT:

``` r
system.time(
        result1 <- dbGetQuery(db, "select displayname, userid from
               questions Q join users U on U.userid = Q.ownerid
               join questions_tags T on Q.questionid = T.questionid
               where tag = 'r'
               intersect
               select displayname, userid from
               questions Q join users U on U.userid = Q.ownerid
               join questions_tags T on Q.questionid = T.questionid
               where tag = 'python'")
               )
```

    ##    user  system elapsed 
    ##   8.514   3.416  29.604

Alternatively we can do a self-join. Note that the syntax gets
complicated as we are doing multiple joins.

``` r
system.time(
        result2 <- dbGetQuery(db, "select displayname, userid from
               (questions Q1 join questions_tags T1
               on Q1.questionid = T1.questionid)
               join
               (questions Q2 join questions_tags T2
               on Q2.questionid = T2.questionid)
               on Q1.ownerid = Q2.ownerid
               join users on Q1.ownerid = users.userid
               where T1.tag = 'r' and T2.tag = 'python'")
               )
```

    ##    user  system elapsed 
    ##  12.235   8.326  38.654

``` r
identical(result1, result2)
```

    ## [1] FALSE

Note that the second query will return duplicates where we have a person
asking multiple R or Python queries. But we know how to solve that by
including a DISTINCT:

    select distinct displayname, userid from ...

Which is faster? The second one looks more involved in terms of the
joins, so the timing results seen above make sense.

Or we could use UNION or EXCEPT to find people who have asked either or
only one type of question, respectively.

> **Challenge**: Find the users who have asked either an R question or a
> Python question.

> **Challenge**: Find the users who have asked only an R question and
> not a Python question.

## 3.2 Subqueries

### 3.2.1 Subqueries in the FROM statement

We can use subqueries in the FROM statement to create a temporary table
to use in a query. Here we’ll do it in the context of a join.

> **Challenge**: What does the following do?

``` r
dbGetQuery(db, "select * from questions join answers A on questions.questionid = A.questionid join 
           (select *, count(*) as n_answered from users 
           group by userid order by n_answered desc limit 1000) most_responsive on
               A.ownerid = most_responsive.userid")
```

It might be hard to just come up with that all at once. A good strategy
is probably to think about creating a view that is the result of the
inner query and then have the outer query use that. You can then piece
together the complicated query in a modular way. For big databases, you
are likely to want to submit this as a single query and not two queries
so that the SQL optimizer can determine the best way to do the
operations. But you want to start with code that you’re confident will
give you the right answer!

Note we could also have done that query using a subquery in the WHERE
statement.

> **Challenge**: Write a query that, for each question, will return the
> question title, number of answers, and the answer to that question
> written by the user with the highest reputation.

Finally one can use subqueries in the SELECT clause to create new
variables, but we won’t go into that here.

### 3.2.2 Subqueries in the WHERE statement

Instead of a join, we can use subqueries as a way to combine information
across tables, with the subquery involved in a WHERE statement. The
subquery creates a set and we then can check for inclusion in (or
exclusion from with `not in`) that set.

For example, suppose we want to know the average number of UpVotes for
users who have posted a question with the tag “python”.

``` r
dbGetQuery(db, "select avg(UpVotes) from users where userid in
               (select distinct ownerid from
               questions join questions_tags on questions.questionid = questions_tags.questionid
               where tag = 'python')")       
```

    ##   avg(UpVotes)
    ## 1      70.7917

In some cases one can do a join rather than using a subquery, but in
this example, it fails.

> **Challenge**: What’s wrong with the following query as an attempt to
> answer the question above? (See if you can figure it out before
> looking at the answer below.)

``` r
dbGetQuery(db, "select avg(UpVotes) from questions, questions_tags, users
               where questions.questionid = questions_tags.questionid and
               questions.ownerid = users.userid and
               tag = 'python'")
```

For more details on subqueries, see the video on “subqueries in where
statements” in this [Introduction to Databases
MOOC](http://cs.stanford.edu/people/widom/DB-mooc.html).

(Answer: In the subquery, we find the Ids of the users we are looking
for and then average over the UpVotes of those individuals. In the join
version we found all the questions that had a Python tag and averaged
over the UpVotes of the individuals associated with those questions. So
the latter includes multiple UpVotes values from individuals who have
posted multiple Python questions.)

> **Challenge**: Write a query that would return the users who have
> answered a question with the Python tag. We’ve seen this challenge
> before, but do it now based on a subquery.

> **Challenge**: How would you find all the answers associated with the
> user with the most upvotes?

> **Challenge**: Create a frequency list of the tags used in the top 100
> most answered questions. Note there is a way to do this with a JOIN
> and a way without a JOIN.

## 3.3 Window functions

[Window
functions](https://www.postgresql.org/docs/current/functions-window.html)
provide the ability to perform calculations across sets of rows that are
related to the current query row.

Comments:

-   The result of applying a window function is the same number of rows
    as the input, even though the functionality is similar to
    `group by`. Hint: think about the result of `group by` + `mutate` in
    dplyr in R.
-   One can apply a window function within groups or across the whole
    table.
-   The functions one can apply include standard aggregation functions
    such as `avg` and `count` as well as non-standard functions
    (specific to using window functions) such as `rank` and `cume_dist`.
-   Unless you’re simply grouping into categories, you’ll generally need
    to order the rows for the window function to make sense.

The syntax is a bit involved, so let’s see with a range of examples:

-   Aggregate within groups but with one output value per input row

``` r
## Total number of questions for each owner
dbGetQuery(db, "select *,
                count() over (partition by ownerid) as n
                from questions order by creationdate limit 5")
```

    ##   questionid        creationdate score viewcount
    ## 1   34552550 2016-01-01 00:00:03     0       108
    ## 2   34552551 2016-01-01 00:00:07     1       151
    ## 3   34552552 2016-01-01 00:00:39     2      1942
    ## 4   34552554 2016-01-01 00:00:50     0       153
    ## 5   34552555 2016-01-01 00:00:51    -1        54
    ##                                                                                   title
    ## 1                                                                 Scope between methods
    ## 2      Rails - Unknown Attribute - Unable to add a new field to a form on create/update
    ## 3 Selenium Firefox webdriver won't load a blank page after changing Firefox preferences
    ## 4                                                       Android Studio styles.xml Error
    ## 5                         Java: reference to non-finial local variables inside a thread
    ##   ownerid  n
    ## 1 5684416 83
    ## 2 2457617  1
    ## 3 5732525  5
    ## 4 5735112  2
    ## 5 4646288 10

-   Compute cumulative calculations; note the need for the ‘order by’

``` r
## Rank (based on ordering by creationdate) of questions by owner
dbGetQuery(db, "select *,
                rank() over (partition by ownerid order by creationdate) as rank
                from questions limit 5")
```

    ##   questionid        creationdate score viewcount
    ## 1   34552558 2016-01-01 00:01:27     1       190
    ## 2   34552612 2016-01-01 00:13:10     0        42
    ## 3   34552655 2016-01-01 00:21:58     2       383
    ## 4   34552875 2016-01-01 01:16:40     0        56
    ## 5   34552973 2016-01-01 01:44:31     2      5824
    ##                                                                                                     title
    ## 1                                   Force delete Session records for the current login User : Laravel 5.2
    ## 2                                                             How do I impliment [example.text intValue]?
    ## 3                                                            RGB to HSV conversion results in noisy image
    ## 4                                                                     When session is considered accessed
    ## 5 What does "cannot invoke initializer for type 'Int' with an argument list of type 'UITextField' " mean?
    ##   ownerid rank
    ## 1      NA    1
    ## 2      NA    2
    ## 3      NA    3
    ## 4      NA    4
    ## 5      NA    5

``` r
dbGetQuery(db, "select *,
                rank() over (partition by ownerid order by creationdate) as rank
                from questions order by ownerid desc limit 10")
```

    ##    questionid        creationdate score viewcount
    ## 1    40826005 2016-11-27 05:23:07     1        38
    ## 2    40866431 2016-11-29 12:53:25     1        97
    ## 3    39327617 2016-09-05 09:30:49     0       402
    ## 4    39529293 2016-09-16 10:31:49     0        27
    ## 5    39916423 2016-10-05 11:50:10     2        62
    ## 6    36130306 2016-03-21 11:11:37     0        41
    ## 7    41301378 2016-12-23 12:16:10     0        87
    ## 8    41142480 2016-12-14 12:18:45    -1        78
    ## 9    39909804 2016-10-07 05:08:09     0        34
    ## 10   38286904 2016-07-09 22:32:49     0       107
    ##                                                                                           title
    ## 1                                                 How to set values in the select dropdown box?
    ## 2                                                                      How to use LatLngBounds?
    ## 3                                                              How To Get Cookies From WebView?
    ## 4                                              How to copy file SDCard to System Rooted Device?
    ## 5                                                               Memory mapping behaviour in QNX
    ## 6                                                                 AEGetParamDesc / MacOS X 10.7
    ## 7  I want to remove some if loops from a php routine, leaving the code more compact and dynamic
    ## 8                                                  Add multiple choice option to quiz generator
    ## 9                                           How to completely disable auto changes in ckeditor?
    ## 10                                       Unable to save a model object with Spring MVC and AJAX
    ##    ownerid rank
    ## 1  7693696    1
    ## 2  7693696    2
    ## 3  7691703    1
    ## 4  7691703    2
    ## 5  7689389    1
    ## 6  7674042    1
    ## 7  7669738    1
    ## 8  7661924    1
    ## 9  7660866    1
    ## 10 7660165    1

-   Do a lagged analysis

``` r
## Get previous value (based on ordering by creationdate) by owner
dbGetQuery(db, "select ownerid, creationdate,
                lag(creationdate, 1) over
                (partition by ownerid order by creationdate)
                as previous_date
                from questions order by ownerid desc limit 5")
```

    ##   ownerid        creationdate       previous_date
    ## 1 7693696 2016-11-27 05:23:07                <NA>
    ## 2 7693696 2016-11-29 12:53:25 2016-11-27 05:23:07
    ## 3 7691703 2016-09-05 09:30:49                <NA>
    ## 4 7691703 2016-09-16 10:31:49 2016-09-05 09:30:49
    ## 5 7689389 2016-10-05 11:50:10                <NA>

So one could now calculate the difference between the previous and
current date to analyze the time gaps between users posting questions.

-   Do an analysis within an arbitrary window of rows based on the
    values in one of the columns

``` r
## Summarize questions within 5 days of current question 
dbGetQuery(db, "select ownerid, creationdate,
                count() over
                (partition by ownerid order by julianday(creationdate)
                range between 5 preceding and 5 following)
                as n_window
                from questions where ownerid is not null limit 30")
```

    ##    ownerid        creationdate n_window
    ## 1       13 2016-12-13 06:09:50        1
    ## 2       25 2016-02-18 05:31:01        1
    ## 3       33 2016-03-23 11:39:08        1
    ## 4       33 2016-08-05 15:32:30        1
    ## 5       33 2016-08-27 08:01:24        1
    ## 6       33 2016-10-10 12:50:36        1
    ## 7       56 2016-05-11 09:40:11        2
    ## 8       56 2016-05-13 13:44:03        2
    ## 9       56 2016-09-14 14:13:19        1
    ## 10      62 2016-06-09 17:16:10        1
    ## 11      62 2016-09-10 02:31:17        1
    ## 12      62 2016-12-31 01:21:24        1
    ## 13      67 2016-08-01 12:51:13        1
    ## 14      70 2016-04-07 14:16:07        1
    ## 15      71 2016-01-18 22:54:07        1
    ## 16      76 2016-09-15 20:28:54        1
    ## 17      91 2016-01-11 21:27:56        1
    ## 18      91 2016-12-28 15:13:48        1
    ## 19      95 2016-04-19 10:19:09        1
    ## 20     105 2016-03-22 18:08:52        1
    ## 21     112 2016-10-02 05:20:24        1
    ## 22     112 2016-10-11 03:44:41        1
    ## 23     113 2016-12-20 22:25:21        1
    ## 24     115 2016-12-29 20:59:24        1
    ## 25     116 2016-01-05 17:14:47        1
    ## 26     116 2016-01-12 00:54:30        1
    ## 27     116 2016-01-22 21:06:24        5
    ## 28     116 2016-01-26 17:32:31        7
    ## 29     116 2016-01-27 06:52:11        9
    ## 30     116 2016-01-27 17:59:30        9

There the ‘5 preceding’ and ‘5 following’ mean to include all rows
within each ownerid that are within 5 Julian days (based on
‘creationdate’) of each row.

So one could now analyze bursts of activity.

One can also choose a fixed number of rows by replacing ‘range’ with
‘rows’. The ROWS and RANGE syntax allow one to specify the *window
frame* in more flexible ways than simply the categories of a categorical
variable.

So the syntax of a window function will generally have these elements:

-   a call to some function
-   OVER
-   PARTITION BY (optional)
-   ORDER BY (optional)
-   RANGE or ROW (optional)
-   AS (optional)

You can also name window functions, which comes in handy if you want
multiple functions applied to the same window:

``` r
dbGetQuery(db, "select ownerid, creationdate,
                lag(creationdate, 1) over w as lag1,
                lag(creationdate, 2) over w as lag2
                from questions where ownerid is not null
                window w as (partition by ownerid order by creationdate)
                order by ownerid limit 5")
```

    ##   ownerid        creationdate                lag1
    ## 1      13 2016-12-13 06:09:50                <NA>
    ## 2      25 2016-02-18 05:31:01                <NA>
    ## 3      33 2016-03-23 11:39:08                <NA>
    ## 4      33 2016-08-05 15:32:30 2016-03-23 11:39:08
    ## 5      33 2016-08-27 08:01:24 2016-08-05 15:32:30
    ##                  lag2
    ## 1                <NA>
    ## 2                <NA>
    ## 3                <NA>
    ## 4                <NA>
    ## 5 2016-03-23 11:39:08

What does that query do?

> **Challenge**: Use a window function to compute the average viewcount
> for each ownerid for the 10 questions preceding each question.

***Challenge (hard)***: Find the users who have asked one question that
is highly-viewed (viewcount &gt; 1000) with their remaining questions
not highly-viewed (viewcount &lt; 20 for all other questions).

## 3.4 Putting it all together to do complicated queries

Here are some real-world style questions one might try to create queries
to answer. The context would be if you have data on user sessions on a
website or data on messages between users.

1.  Given a table of user sessions with the format

<!-- -->

    date | session_id | user_id | session_time

calculate the distribution of the average daily total session time in
the last month. I.e., you want to get each user’s daily average and then
find the distribution over users. The output should be something like:

    minutes_per_day' | number_of_users

1.  Consider a table of messages of the form

<!-- -->

    sender_id | receiver_id | message_id

For each user, find the three users they message the most.

1.  Suppose you have are running an online experiment and have a table
    on the experimental design

<!-- -->

    user_id | test_group | date_first_exposed

Suppose you also have a messages table that indicates if each message
was sent on web or mobile:

    date | sender_id | receiver_id | message_id | interface (web or mobile)

What is the average (over users) in the average number of messages sent
per day for each test group if you look at the users who have sent
messages only on mobile in the last month.

# 4 Efficient SQL queries

# 4.1 Overview

In general, your DBMS should examine your query and try to implement it
in the fastest way possible. And as discussed above, putting an indexes
on your tables will often speed things up substantially, but only for
certain types of queries.

Some tips for faster queries include:

-   use indexes on fields used in WHERE and JOIN clauses
    -   try to avoid wildcards at the start of LIKE string comparison
        when you have an index on the field (as this requires looking at
        all of the rows)
    -   similarly try to avoid using functions on indexed columns in a
        WHERE clause as this requires doing the calculation on all the
        rows in order to check the condition
-   only select the columns you really need
-   create (temporary) tables to store intermediate results that you
    need to query repeatedly
-   use filtering (WHERE clauses) in inner statements when you have
    nested subqueries
-   use LIMIT as seen in the examples here if you only need some of the
    rows a query returns

## 4.2 Indexes

An index is an ordering of rows based on one or more fields. DBMS use
indexes to look up values quickly, either when filtering (if the index
is involved in the WHERE condition) or when doing joins (if the index is
involved in the JOIN condition). So in general you want your tables to
have indexes.

DBMS use indexing to provide sub-linear time lookup. Without indexes, a
database needs to scan through every row sequentially, which is called
linear time lookup – if there are n rows, the lookup is *O*(*n*) in
computational cost. With indexes, lookup may be logarithmic – O(log(n))
– (if using tree-based indexes) or constant time – O(1) – (if using
hash-based indexes). A binary tree-based search is logarithmic; at each
step through the tree you can eliminate half of the possibilities.

Here’s how we create an index, with some time comparison for a simple
query.

``` r
system.time(dbGetQuery(db, "select * from questions where viewcount > 10000"))     # 2.4 seconds
system.time(dbExecute(db, "create index count_index on questions (viewcount)"))  # 5.6 seconds
system.time(dbGetQuery(db, "select * from questions where viewcount > 10000"))    # 0.9 seconds
## restore earlier state by removing index
system.time(dbExecute(db, "drop index count_index"))
```

In other contexts, an index can save huge amounts of time. So if you’re
working with a database and speed is important, check to see if there
are indexes.

That being said, using indexes in a lookup is not always advantageous.

### How indexes work

Indexes are often implemented using tree-based methods. For example in
Postgres, b-tree indexes are used for indexes on things that have an
ordering. Trees are basically like decision trees - at each node in the
tree, there is a condition that sends one down the left or right branch
(there might also be more than two branches. Eventually, one reaches the
leaves of the tree, which have the actual values that one is looking
for. Associated with each value is the address of where that row of data
is stored. With a tree-based index, the time cost of b-tree lookup is
logarithmic (based on the binary lookup), so it does grow with the
number of elements in the table, but it does so slowly. The lookup
process is that given a value (which would often be referred to as a
`key`), one walks down the tree based on comparing the value to the
condition at each split in the tree until one finds the elements
corresponding to the value and then getting the addresses for where the
desired rows are stored.

Here’s [some
information](https://use-the-index-luke.com/sql/anatomy/the-tree) on how
such trees are constructed and searched.

In SQLite, indexes are implemented by creating a separate index table
that maps from the value to the row index in the indexed table, allowing
for fast lookup of a row.

One downside of indexes is that creation of indexes can be very
time-consuming. And if the database is updated frequently, this could be
detrimental.

## 4.3 SQL query plans and EXPLAIN

You can actually examine the query plan that the system is going to use
for a query using the EXPLAIN keyword. I’d suggest trying this in
Postgres as the output is more interpretable than SQLite.

``` r
dbGetQuery(db, "explain select * from webtraffic where count > 500")
```

In PostgreSQL that gives the following:

                                                                            QUERY PLAN
    1                             Gather  (cost=1000.00..388634.17 rows=8513 width=61)
    2                                                               Workers Planned: 2
    3   ->  Parallel Seq Scan on webtraffic  (cost=0.00..386782.88 rows=3547 width=61)
    4                                                            Filter: (count > 500)

The “Workers Planned: 2” seems to indicate that there will be some
parallelization used, even without us asking for that.

Now let’s see what query plan is involved in a join and when using
indexes.

``` r
dbGetQuery(db, "explain select * from questions join questions_tags on
               questions.questionid = questions_tags.questionid")
```

                                                                             QUERY PLAN
    1                   Hash Join  (cost=744893.91..2085537.32 rows=39985376 width=118)
    2                     Hash Cond: (questions_tags.questionid = questions.questionid)
    3     ->  Seq Scan on questions_tags  (cost=0.00..634684.76 rows=39985376 width=16)
    4                     ->  Hash  (cost=365970.96..365970.96 rows=13472796 width=102)
    5         ->  Seq Scan on questions  (cost=0.00..365970.96 rows=13472796 width=102)

``` r
dbGetQuery(db, "explain select * from questions join questions_tags on
               questions.questionid = questions_tags.questionid where tag like 'python'")
```

                                                                                                    QUERY PLAN
    1                                                 Gather  (cost=15339.05..899172.92 rows=687748 width=118)
    2                                                                                       Workers Planned: 2
    3                                        ->  Nested Loop  (cost=14339.05..829398.12 rows=286562 width=118)
    4         ->  Parallel Bitmap Heap Scan on questions_tags  (cost=14338.61..252751.63 rows=286562 width=16)
    5                                                                          Filter: (tag ~~ 'python'::text)
    6               ->  Bitmap Index Scan on questions_tags_tag_idx  (cost=0.00..14166.68 rows=687748 width=0)
    7                                                                       Index Cond: (tag = 'python'::text)
    8                     ->  Index Scan using questions_pkey on questions  (cost=0.43..2.01 rows=1 width=102)
    9                                                     Index Cond: (questionid = questions_tags.questionid)

Here’s additional information on interpreting what you see:
<https://www.postgresql.org/docs/current/static/using-explain.html>.

The main thing to look for is to see if the query will be done by using
an index or by sequential scan (i.e., looking at all the rows).

Finally, let’s compare the query plans for an inner join versus a cross
join followed by a WHERE that produces equivalent results.

``` r
dbGetQuery(db, "explain select * from questions join questions_tags on
               questions.questionid = questions_tags.questionid")
```

                                                                             QUERY PLAN
    1                   Hash Join  (cost=744893.91..2085537.32 rows=39985376 width=118)
    2                     Hash Cond: (questions_tags.questionid = questions.questionid)
    3     ->  Seq Scan on questions_tags  (cost=0.00..634684.76 rows=39985376 width=16)
    4                     ->  Hash  (cost=365970.96..365970.96 rows=13472796 width=102)
    5         ->  Seq Scan on questions  (cost=0.00..365970.96 rows=13472796 width=102)
    6                                                                              JIT:
    7                                                                     Functions: 10
    8       Options: Inlining true, Optimization true, Expressions true, Deforming true

``` r
dbGetQuery(db, "explain select * from questions cross join questions_tags where
               questions.questionid = questions_tags.questionid")
```

                                                                             QUERY PLAN
    1                   Hash Join  (cost=744893.91..2085537.32 rows=39985376 width=118)
    2                     Hash Cond: (questions_tags.questionid = questions.questionid)
    3     ->  Seq Scan on questions_tags  (cost=0.00..634684.76 rows=39985376 width=16)
    4                     ->  Hash  (cost=365970.96..365970.96 rows=13472796 width=102)
    5         ->  Seq Scan on questions  (cost=0.00..365970.96 rows=13472796 width=102)
    6                                                                              JIT:
    7                                                                     Functions: 10
    8       Options: Inlining true, Optimization true, Expressions true, Deforming true

We see that the query plan indicates the two queries are using the same
steps, with the same cost.

## 4.4 Index lookup vs. sequential scan

Using an index is good in that can go to the data needed very quickly
based on random access to the disk locations of the data of interest,
but if it requires the computer to examine a large number of rows, it
may not be better than sequential scan. An advantage of sequential scan
is that it will make good use of the CPU cache, reading chunks of data
and then accessing the individual pieces of data quickly.

Ideally you’d do sequential scan of exactly the subset of the rows that
you need, with that subset available in contiguous storage.

## 4.5 Disk caching

You might think that database queries will generally be slow (and slower
than in-memory manipulation such as in R or Python when all the data can
fit in memory) because the database stores the data on disk. However, as
mentioned earlier the operating system will generally cache files/data
in memory when it reads from disk. Then if that information is still in
memory the next time it is needed, it will be much faster to access it
the second time around. Other processes might need memory and
‘invalidate’ the cache, but often once the data is read once, the
database will be able to do queries quite quickly. This also means that
even if you’re using a database, you can benefit from a machine with a
lot of memory if you have a large database (ideally a machine with
rather more RAM than the size of the table(s) you’ll be accessing).

Given this, it generally won’t be helpful to force your database to
reside in memory (e.g., using `:memory:` for SQLite or putting the
database on a RAM disk).

### 4.6 Parallelization and partitioning

To speed up your work, one might try to split up one’s queries into
multiple queries that you run in parallel. However, you’re likely to
have problems with parallel queries from a single R or Python session.

However, multiple queries to the same database from separate R or Python
sessions will generally run fine but can compete for access to
disk/memory. That said, in some basic experiments, the slowdown was
moderate, so one may be able to parallelize across processes in a manual
fashion.

As of version 9.6 of Postgres, there is some capability for doing
parallel queries:
<https://www.postgresql.org/docs/current/static/parallel-query.html>.

Finally Postgres supports partitioning tables. Generally one would
divide a large table into smaller tables based on unique values of a
key. For example if your data had timetamps, you could partition into
subtables for each month or each year. This would allow faster queries
when considering data that reside on one or a small number of partitions
and could also ease manual implementation of parallelization. Here’s
some information:
<a href="https://www.postgresql.org/docs/current/static/ddl-partitioning.html" class="uri">https://www.postgresql.org/docs/current/static/ddl-partitioning.html</a>.
