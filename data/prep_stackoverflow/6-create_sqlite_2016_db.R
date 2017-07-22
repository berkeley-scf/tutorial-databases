library(readr)
questions <- read_csv(file = 'questions-2016.csv')
answers <- read_csv(file = 'answers-2016.csv')
questions_tags <- read_csv(file = 'questions_tags-2016.csv')
users <- read_csv(file = 'users-2016.csv')

library(RSQLite)
fileName <- "stackoverflow-2016.db"
drv <- dbDriver("SQLite")
db <- dbConnect(drv, dbname = fileName)

## no date/time type in SQLite
questions$creationdate <- as.character(questions$creationdate)
answers$creationdate <- as.character(answers$creationdate)
users$creationdate <- as.character(users$creationdate)
users$lastaccessdate <- as.character(users$lastaccessdate)

dbWriteTable(db, name = "questions", value = questions)
dbWriteTable(conn = db, name = "answers", value = answers)
dbWriteTable(conn = db, name = "questions_tags", value = questions_tags)
dbWriteTable(conn = db, name = "users", value = users)

dbDisconnect(db)
