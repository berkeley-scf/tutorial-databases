## code courtesy of Harrison Dekker, January 2016
## read Posts.xml and create the questions, questions_tags, and answers tables
## in existing postgres database
source('connect_postgres.R')

iodir = '/scratch/users/paciorek/stackoverflow'
inputfile <- "Posts.xml"

dat <- file(description = file.path(iodir, inputfile), open = "r")
invisible(readLines(con = dat, n = 2))
max_iters <- 5000
actual_iter <- 0
chunk_size <- 500
total_posts <- 0
total_questions <- 0
last.rowid <- 0
while (TRUE) {
  
  actual_iter <- actual_iter + 1
  if (actual_iter %% 1000 == 0) {
    message("iter ", actual_iter)
    message("total_posts ", total_posts)
    message("total_questions ", total_questions)
  }
  
  tmplines <- readLines(con = dat, n = chunk_size, encoding = "UTF-8")
  
  if (length(tmplines) == 0) {
    message("bye!")
    break
  } 
  
  if (str_detect(tmplines[length(tmplines)], "</posts>")) {
    message("Yay last chunk!")
    tmplines <- tmplines[-length(tmplines)]
  }
  
  total_posts <- total_posts + length(tmplines)
  
  x <- read_html(paste(tmplines, collapse = ""))
  
  rows <- x %>% xml_find_first("body") %>% xml_find_all("row")
  
  posttypeids <- x %>%  xml_find_all("body") %>% xml_find_all("row") %>% xml_attr("posttypeid")

  # build and save the 'questions' table  
  qrows <- rows[posttypeids == "1"]
  
  total_questions <- total_questions + length(rows)
  
  df <- data_frame(questionid = qrows %>% xml_attr("id"),
                   creationdate = qrows %>% xml_attr("creationdate"),
                   score = qrows %>% xml_attr("score"),
                   viewcount = qrows %>% xml_attr("viewcount"),
                   answercount = qrows %>% xml_attr("answercount"),
                   commentcount = qrows %>% xml_attr("commentcount"),
                   favoritecount = qrows %>% xml_attr("favoritecount"),
                   title = qrows %>% xml_attr("title"),
                   ownerid = qrows %>% xml_attr("owneruserid"),
                   tags = qrows %>% xml_attr("tags"))
	df$questionid <- as.numeric(df$questionid)			   
	df$creationdate <- format(df$creationdate, format="%Y-%m-%d %H:%M:%S" )
	df$score <- as.numeric(df$score)
	df$viewcount <- as.numeric(df$viewcount)
	df$ownerid <- as.numeric(df$ownerid)
	
	
	dbWriteTable(conn = con, name = "questions", as.data.frame(df[,c(1:6)]),
              row.names = FALSE, append = TRUE)

	# parse the tags out from the questions and save in the questions_tags table  
  df2 <- df %>% select(questionid, tags) %>% group_by(questionid) %>% do({
    data_frame(tag = str_split(.$tags, "<|>") %>% unlist() %>% setdiff(c("")))
  }) %>% ungroup()
  df2$questionid <- as.numeric(df2$questionid)
  
  # create a row id that to use as primary key
  start <- last.rowid + 1
  end <- last.rowid + nrow(df2)
  df2$rowid <- c(start:end)
  last.rowid <- end
  
  # rename the columns
  names(df2) <- c("questionid", "tag", "rowid")
  
  # write the data frame to the db
  dbWriteTable(conn = con, name = "questions_tags", as.data.frame(df2),
               row.names = FALSE, append = TRUE)
  
# build the 'answers' table
  arows <- rows[posttypeids == "2"]
  
  df3 <- data_frame(answerid = arows %>% xml_attr("id"),
                   questionid = arows %>% xml_attr("parentid"),
                   creationdate = arows %>% xml_attr("creationdate"),
                   score = arows %>% xml_attr("score"),
                   ownerid = arows %>% xml_attr("owneruserid"))
  
  df3$answerid <- as.numeric(df3$answerid)			   
  df3$creationdate <- format(df3$creationdate, format="%Y-%m-%d %H:%M:%S" )
  df3$score <- as.numeric(df3$score)
  df3$questionid <- as.numeric(df3$questionid)
  df3$ownerid <- as.numeric(df3$ownerid)
  
  dbWriteTable(conn = con, name = "answers", as.data.frame(df3),
               row.names = FALSE, append = TRUE)
}
close(dat)

### Modify some default data types and add primary key and indices

 # 'questions_tags'
dbGetQuery(con, "ALTER TABLE questions_tags ALTER COLUMN questionid TYPE integer;")
dbGetQuery(con, "ALTER TABLE questions_tags ADD PRIMARY KEY (rowid)")
dbGetQuery(con, "CREATE INDEX ON questions_tags (questionid)")
dbGetQuery(con, "CREATE INDEX ON questions_tags (tag)")  # use tag here not tagid given commenting out tag table below

# 'questions'
dbGetQuery(con, "ALTER TABLE questions ALTER COLUMN questionid TYPE integer;")
dbGetQuery(con, "ALTER TABLE questions ALTER COLUMN score TYPE integer;")
dbGetQuery(con, "ALTER TABLE questions ALTER COLUMN viewcount TYPE integer;")
dbGetQuery(con, "ALTER TABLE questions ADD PRIMARY KEY (questionid)")
dbGetQuery(con, "CREATE INDEX ON questions (ownerid)")

# 'answers'
dbGetQuery(con, "ALTER TABLE answers ALTER COLUMN answerid TYPE integer;")
dbGetQuery(con, "ALTER TABLE answers ALTER COLUMN questionid TYPE integer;")
dbGetQuery(con, "ALTER TABLE answers ALTER COLUMN score TYPE integer;")
dbGetQuery(con, "ALTER TABLE answers ALTER COLUMN ownerid TYPE integer;")
dbGetQuery(con, "ALTER TABLE answers ADD PRIMARY KEY (answerid)")
dbGetQuery(con, "CREATE INDEX ON answers (ownerid)")
dbGetQuery(con, "CREATE INDEX ON answers (questionid)")

### Create the 'tags' table

if(FALSE) {
    ## not done for this tutorial because:
    ## 1) for some reason setting the questions_tags.tagid is _very_slow (seems to hang in some way)
    ## 2) the tags table has little information that cannot be easily generated by a query on the tag field of the questions table
    
    ## grab the tags via a query
    df4 <- dbGetQuery(con, "select distinct tag 
                  from questions_tags
                  order by tag")
    
    ## add an id field
    df4$tagid <- c(1:nrow(df4))
    
    ## add to the db
    dbWriteTable(conn = con, name = "tags", as.data.frame(df4),
                 row.names = FALSE, append = TRUE)
    
    ## add a column to hold a tagid
    dbGetQuery(con, "ALTER TABLE questions_tags ADD COLUMN tagid integer")
    
    ## populate the new column with tagids (this is apparently the postgres way to do it)
    dbGetQuery(con,"UPDATE questions_tags SET tagid = t.tagid
           FROM tags as t
           WHERE questions_tags.tag = t.tag")
    
    ## add a primary key
    dbGetQuery(con, "ALTER TABLE tags ADD PRIMARY KEY (tagid)")
    
    ## index the tags
    dbGetQuery(con, "CREATE INDEX ON tags (lower(tag))")
    
    ## remove the now unnecessary tag column in questions_tags
    dbGetQuery(con, "ALTER TABLE questions_tags DROP COLUMN tag")
}

dbDisconnect(con)
