library(duckdb)

dbname <- "stackoverflow-2021.duckdb"
db <- dbConnect(duckdb(), dbname)

## favoritecount will be 'chararacter'
duckdb_read_csv(db, 'questions', 'questions-2021.csv', na.strings = 'NA')
duckdb_read_csv(db, 'answers', 'answers-2021.csv', na.strings = 'NA')
duckdb_read_csv(db, 'users', 'users-2021.csv', na.strings = 'NA')
duckdb_read_csv(db, 'questions_tags', 'questions_tags-2021.csv', na.strings = 'NA')
dbDisconnect(db, shutdown = TRUE)

