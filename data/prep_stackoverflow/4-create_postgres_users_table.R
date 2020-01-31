## code courtesy of Harrison Dekker, January 2016
## read Users.xml and create the users table
## in existing postgres database
source('connect_postgres.R')

iodir = '/scratch/users/paciorek/stackoverflow'
inputfile <- "Users.xml"

dat <- file(description = file.path(iodir, inputfile), open = "r")
invisible(readLines(con = dat, n = 2))
max_iters <- 5000
actual_iter <- 0
chunk_size <- 500
total_posts <- 0
while (TRUE) {
  
  actual_iter <- actual_iter + 1
  if (actual_iter %% 1000 == 0) {
    message("iter ", actual_iter)
    message("total_posts ", total_posts)
  }
  
  tmplines <- readLines(con = dat, n = chunk_size, encoding = "UTF-8")
  
  if (length(tmplines) == 0) {
    message("bye!")
    break
  } 
  
  if (str_detect(tmplines[length(tmplines)], "</users>")) {
    message("Yay last chunk!")
    tmplines <- tmplines[-length(tmplines)]
  }
  
  total_posts <- total_posts + length(tmplines)
  
  x <- read_html(paste(tmplines, collapse = ""))
  
  rows <- x %>% xml_find_first("body") %>% xml_find_all("row")
  
  df <- tibble(userid = rows %>% xml_attr("id"),
                   creationdate = rows %>% xml_attr("creationdate"),
                   lastaccessdate = rows %>% xml_attr("lastaccessdate"),
                   location = rows %>% xml_attr("location"),
                   reputation = rows %>% xml_attr("reputation"),
                   displayname = rows %>% xml_attr("displayname"),
                   upvotes = rows %>% xml_attr("upvotes"),
                   downvotes = rows %>% xml_attr("downvotes"),
                   age = rows %>% xml_attr("age"),
                   accountid = rows %>% xml_attr("accountid"))
	
  df$userid <- as.numeric(df$userid)			   
  df$reputation <- as.numeric(df$reputation)	
  df$upvotes <- as.numeric(df$upvotes)
  df$downvotes <- as.numeric(df$downvotes)
  df$age <- as.numeric(df$age)
  df$accountid <- as.numeric(df$accountid)
  
  dbWriteTable(conn = con, name = "users", as.data.frame(df),
              row.names = FALSE, append = TRUE)
  
}
close(dat)

### Modify some default data types and add primary key
dbGetQuery(con, "ALTER TABLE users ALTER COLUMN userid TYPE integer;")
dbGetQuery(con, "ALTER TABLE users ALTER COLUMN reputation TYPE integer;")
dbGetQuery(con, "ALTER TABLE users ALTER COLUMN upvotes TYPE integer;")
dbGetQuery(con, "ALTER TABLE users ALTER COLUMN downvotes TYPE integer;")
dbGetQuery(con, "ALTER TABLE users ALTER COLUMN age TYPE integer;")
dbGetQuery(con, "ALTER TABLE users ALTER COLUMN accountid TYPE integer;")
dbGetQuery(con, "ALTER TABLE users ADD PRIMARY KEY (userid)")


dbDisconnect(con)

